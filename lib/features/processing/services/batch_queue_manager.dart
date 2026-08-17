import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/storage_path_helper.dart';
import '../../ai_assistant/data/ai_assistant_service.dart';
import '../../presets/domain/render_preset.dart';
import '../../subtitles/data/whisper_service.dart';
import '../../subtitles/domain/subtitle_token.dart';
import '../../tasks/domain/video_task.dart';
import '../../tasks/presentation/providers/task_queue_provider.dart';
import 'ffmpeg_engine.dart';
import 'native_gpu_engine.dart';

class BatchQueueManager extends ChangeNotifier {
  final FfmpegEngine _ffmpegEngine;
  final WhisperService _whisperService;
  bool _isProcessing = false;

  /// Concurrent task count scales with CPU logical cores: numberOfProcessors ~/ 2.
  /// Clamped to [3, 8]: min 3 for overlap, max 8 to protect VRAM on budget GPUs (~275MB VRAM/task).
  /// Examples: 4-core → 3, 8-core → 4, 12-core → 6, 16-core → 8.
  static int get _maxConcurrentTasks => Platform.isAndroid
      ? 1
      : (Platform.numberOfProcessors ~/ 2).clamp(3, 8);

  BatchQueueManager(this._ffmpegEngine, {WhisperService? whisperService})
      : _whisperService = whisperService ?? WhisperService();

  /// Mutex status checking if queue processing is currently active.
  bool get isProcessing => _isProcessing;

  /// Starts processing pending tasks concurrently (up to [_maxConcurrentTasks] at once).
  /// Whisper AI and FFmpeg pipeline overlap naturally across concurrent tasks.
  Future<void> startProcessing({
    required TaskQueueNotifier taskNotifier,
    required RenderPreset preset,
    required String defaultOutputFolderPath,
  }) async {
    if (_isProcessing) {
      debugPrint('BatchQueueManager: Already processing queue. Trigger ignored.');
      return;
    }

    _isProcessing = true;
    notifyListeners();
    debugPrint(
      'BatchQueueManager: Mutex acquired. Starting concurrent batch (max $_maxConcurrentTasks tasks) '
      'using Preset "${preset.name}" [Whisper=${preset.useWhisper}, Banner=${preset.bannerPath ?? "нет"}, Audio=${preset.audioPath ?? "нет"}]...',
    );

    try {
      // Track IDs currently being dispatched to prevent double-scheduling
      final activeIds = <int>{};

      while (true) {
        final pending = taskNotifier.tasks
            .where((t) => t.status == TaskStatus.pending && !activeIds.contains(t.id))
            .toList();

        // All done: no pending tasks and no active slots occupied
        if (pending.isEmpty && activeIds.isEmpty) {
          debugPrint('BatchQueueManager: All tasks complete. Releasing mutex.');
          break;
        }

        // Fill available concurrent slots
        while (pending.isNotEmpty && activeIds.length < _maxConcurrentTasks) {
          final task = pending.removeAt(0);
          activeIds.add(task.id);
          debugPrint(
            'BatchQueueManager: Dispatching Task #${task.id} '
            '(active: ${activeIds.length}/$_maxConcurrentTasks)',
          );

          // Fire-and-forget: remove from activeIds when done (success or fail)
          _processOneTask(
            task: task,
            taskNotifier: taskNotifier,
            preset: preset,
            defaultOutputFolderPath: defaultOutputFolderPath,
          ).whenComplete(() {
            activeIds.remove(task.id);
            debugPrint(
              'BatchQueueManager: Task #${task.id} finished '
              '(active: ${activeIds.length}/$_maxConcurrentTasks)',
            );
          });
        }

        // Yield to Dart event loop — allows async tasks to run and update activeIds
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } catch (e, stack) {
      debugPrint('BatchQueueManager critical error: $e\n$stack');
    } finally {
      _isProcessing = false;
      notifyListeners();
      debugPrint('BatchQueueManager: Mutex released. Queue processing complete.');
    }
  }

  /// Processes a single video task end-to-end: Whisper subtitles → FFmpeg render.
  /// While this task runs Whisper, another concurrent task may already be in FFmpeg phase
  /// (natural pipeline overlap — no extra orchestration needed).
  Future<void> _processOneTask({
    required VideoTask task,
    required TaskQueueNotifier taskNotifier,
    required RenderPreset preset,
    required String defaultOutputFolderPath,
  }) async {
    // Mark task as processing (0% progress)
    await taskNotifier.updateTaskProgress(task.id, 0.0, TaskStatus.processing);

    // Determine output directory & file name
    final outDir = task.outputFolderPath.isNotEmpty
        ? task.outputFolderPath
        : defaultOutputFolderPath;

    final dir = Directory(outDir);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e) {
        await taskNotifier.updateTaskProgress(
          task.id,
          0.0,
          TaskStatus.failed,
          errorMsg: 'Недостаточно прав или места на диске для создания целевой папки',
        );
        return;
      }
    }

    final fileNameWithoutExt =
        task.inputFilePath.split(RegExp(r'[/\\]')).last.split('.').first;
    final partSuffix = task.partNumber != null ? '_part${task.partNumber}' : '';
    final outputFilePath = '${dir.path}/$fileNameWithoutExt${partSuffix}_unique.mp4';

    // Select MP3 audio file if audioPath preset (file or directory) is set
    String? selectedAudioPath;
    if (preset.audioPath != null && preset.audioPath!.isNotEmpty) {
      final audioFile = File(preset.audioPath!);
      if (await audioFile.exists()) {
        selectedAudioPath = audioFile.path;
      } else {
        final audioDir = Directory(preset.audioPath!);
        if (await audioDir.exists()) {
          final mp3Files = audioDir
              .listSync()
              .whereType<File>()
              .where((f) {
                final p = f.path.toLowerCase();
                return p.endsWith('.mp3') || p.endsWith('.wav') || p.endsWith('.m4a') || p.endsWith('.aac') || p.endsWith('.ogg');
              })
              .toList();
          if (mp3Files.isNotEmpty) {
            mp3Files.shuffle();
            selectedAudioPath = mp3Files.first.path;
          }
        }
      }
    }

    // Resolve direct storage Banner Path (bypassing any wiped cache paths)
    String? resolvedBannerPath = preset.bannerPath;
    if (resolvedBannerPath != null && resolvedBannerPath.isNotEmpty) {
      resolvedBannerPath = await StoragePathHelper.getDirectStoragePath(resolvedBannerPath);
      preset.bannerPath = resolvedBannerPath;
    }

    // --- Phase 1: Whisper AI Karaoke Subtitle Generation ---
    String? subtitleAssPath;
    String? transcriptText;
    List<SubtitleToken>? recognizedTokens;

    if (preset.useWhisper) {
      debugPrint('Task #${task.id}: Starting Whisper AI transcription...');
      try {
        final whisperResult = await _whisperService.generateSubtitlesForTask(
          task: task,
          preset: preset,
          onProgress: (progress, statusMsg) {
            taskNotifier.updateTaskProgress(
              task.id,
              progress,
              TaskStatus.processing,
            );
          },
        );
        if (whisperResult != null) {
          subtitleAssPath = whisperResult.assPath;
          transcriptText = whisperResult.transcript;
          recognizedTokens = whisperResult.tokens;
        }
        debugPrint('Task #${task.id}: Whisper transcription complete.');
      } catch (e) {
        debugPrint('Task #${task.id}: Subtitle generation warning (continuing without subs): $e');
      }
    }

    // --- Phase 1.5: AI Viral Hook Generation (if hook is empty) ---
    if ((task.textHook == null || task.textHook!.trim().isEmpty) &&
        AiAssistantService.instance.isConfigured &&
        AiAssistantService.instance.isAutoHooksEnabled) {
      try {
        debugPrint('Task #${task.id}: AI Generating viral hook for video "$fileNameWithoutExt"...');
        final aiHook = await AiAssistantService.instance.generateHook(
          transcript: transcriptText,
          videoTitle: fileNameWithoutExt,
        );
        if (aiHook != null && aiHook.isNotEmpty) {
          task.textHook = aiHook;
          await taskNotifier.updateTaskHook(task.id, aiHook);
          debugPrint('Task #${task.id}: AI Hook applied → "$aiHook"');
        }
      } catch (e) {
        debugPrint('Task #${task.id}: AI Hook generation error (ignored): $e');
      }
    }

    // Fallback: If hook is still empty, check if preset has a predefined text hook
    if ((task.textHook == null || task.textHook!.trim().isEmpty) &&
        preset.textHook != null &&
        preset.textHook!.trim().isNotEmpty) {
      task.textHook = preset.textHook!.trim();
      await taskNotifier.updateTaskHook(task.id, task.textHook!);
    }

    // --- Phase 2: Render Execution (Native GPU Engine on Android, FFmpeg on PC) ---
    bool renderedSuccessfully = false;
    String? renderError;

    if (Platform.isAndroid) {
      try {
        final outF = File(outputFilePath);
        if (await outF.exists()) {
          try { await outF.delete(); } catch (_) {}
        }
        debugPrint('Task #${task.id}: Launching Native Zero-Copy GPU Engine (100-200 FPS)...');
        final startOffset = preset.useWhisper ? 0.25 : 0.05;
        double maxSeenProgress = startOffset;
        taskNotifier.updateTaskProgress(task.id, startOffset, TaskStatus.processing);

        final gpuTask = VideoTask()
          ..id = task.id
          ..inputFilePath = task.inputFilePath
          ..outputFolderPath = dir.path
          ..startTime = task.startTime
          ..endTime = task.endTime
          ..textHook = task.textHook
          ..partNumber = task.partNumber;

        renderedSuccessfully = await NativeGpuEngine.instance.renderTask(
          task: gpuTask,
          preset: preset,
          outputFilePath: outputFilePath,
          tokens: recognizedTokens,
          onProgress: (progress) {
            final scaledProgress = (startOffset + progress * (0.99 - startOffset)).clamp(0.0, 0.99);
            if (scaledProgress >= maxSeenProgress) {
              maxSeenProgress = scaledProgress;
              taskNotifier.updateTaskProgress(
                task.id,
                scaledProgress,
                TaskStatus.processing,
              );
            }
          },
        );
        if (renderedSuccessfully) {
          debugPrint('Task #${task.id}: Native GPU Engine finished successfully.');
        } else {
          renderError = 'Native GPU Engine rendering failed';
        }
      } catch (e) {
        debugPrint('Task #${task.id}: Native GPU Engine error: $e');
        renderError = e.toString();
      }
    } else {
      // Non-Android (Desktop PC)
      debugPrint('Task #${task.id}: Starting FFmpeg render on Desktop...');
      renderError = await _ffmpegEngine.executeTask(
        task: task,
        preset: preset,
        outputFilePath: outputFilePath,
        gameplayVideoPath: preset.gameplayVideoPath,
        backgroundAudioPath: selectedAudioPath,
        subtitleAssPath: subtitleAssPath,
        onProgress: (progress) {
          final startOffset = preset.useWhisper ? 0.25 : 0.05;
          final scaledProgress = startOffset + progress * (0.99 - startOffset);
          taskNotifier.updateTaskProgress(
            task.id,
            scaledProgress,
            TaskStatus.processing,
          );
        },
      );
    }

    // --- Final Status Update & Phase 3 (AI Post Generation) ---
    if (renderError == null) {
      debugPrint('Task #${task.id}: Render SUCCESS → $outputFilePath');
      await taskNotifier.updateTaskProgress(task.id, 1.0, TaskStatus.success);

      // --- Phase 3: AI Post / Description / Hashtags (.txt) ---
      final partPrefix = task.partNumber != null ? 'ЧАСТЬ ${task.partNumber} - ' : '';
      final initialContent = '=== ЗАГОЛОВОК / ХУК ===\n$partPrefix${task.textHook ?? "—"}\n\n=== ТЕКСТ ПОСТА ДЛЯ ПУБЛИКАЦИИ ===\n';
      
      await _savePostTextFile(
        outputFolderPath: dir.path,
        fileNameWithoutExt: fileNameWithoutExt,
        partSuffix: partSuffix,
        fullContent: initialContent,
      );

      if (transcriptText != null &&
          transcriptText.isNotEmpty &&
          AiAssistantService.instance.isConfigured &&
          AiAssistantService.instance.isAutoPostsEnabled) {
        // Run AI text generation asynchronously without blocking queue mutex release
        AiAssistantService.instance.generatePostDescription(
          transcript: transcriptText,
          partNumber: task.partNumber,
          videoTitle: fileNameWithoutExt,
        ).then((aiPost) async {
          if (aiPost != null && aiPost.trim().isNotEmpty) {
            final updatedContent = '=== ЗАГОЛОВОК / ХУК ===\n$partPrefix${task.textHook ?? "—"}\n\n=== ТЕКСТ ПОСТА ДЛЯ ПУБЛИКАЦИИ ===\n$aiPost\n';
            await _savePostTextFile(
              outputFolderPath: dir.path,
              fileNameWithoutExt: fileNameWithoutExt,
              partSuffix: partSuffix,
              fullContent: updatedContent,
            );
          }
        }).catchError((e) {
          debugPrint('Task #${task.id}: Async AI Post saving error (ignored): $e');
        });
      }
    } else {
      debugPrint('Task #${task.id}: Render FAILED: $renderError');
      await taskNotifier.updateTaskProgress(
        task.id,
        0.0,
        TaskStatus.failed,
        errorMsg: renderError,
      );
    }

    // Удаляем temp WAV+ASS, чтобы TemporaryDirectory не раздувался после успешного рендера.
    await _whisperService.cleanupTaskTempFiles(task.id);
  }

  Future<void> _savePostTextFile({
    required String outputFolderPath,
    required String fileNameWithoutExt,
    required String partSuffix,
    required String fullContent,
  }) async {
    final targetPath = '$outputFolderPath/$fileNameWithoutExt${partSuffix}_post.txt';

    // 1. Android Native MediaStore / All-Files Bridge (Guaranteed same folder saving)
    if (Platform.isAndroid) {
      try {
        final channel = MethodChannel('com.example.tt_video_automator/gpu_engine');
        final success = await channel.invokeMethod<bool>('saveTextFile', {
          'path': targetPath,
          'content': fullContent,
        });
        if (success == true) {
          debugPrint('AI Post description saved in target folder → $targetPath');
          return;
        }
      } catch (e) {
        debugPrint('Native saveTextFile failed ($e), falling back to direct IO...');
      }
    }

    // 2. Direct File write
    try {
      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsString(fullContent);
      debugPrint('AI Post description saved directly → $targetPath');
    } catch (e) {
      debugPrint('Task AI Post saving error: $e');
    }
  }
}

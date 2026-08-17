import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../subtitles/data/whisper_service.dart';
import '../../../subtitles/domain/subtitle_token.dart';
import '../../../tasks/domain/video_task.dart';
import '../../../tasks/presentation/providers/task_queue_provider.dart';
import '../../data/ai_assistant_service.dart';
import '../../domain/ai_cut_segment.dart';
import '../ai_settings_dialog.dart';

class AiSmartCutDialog extends ConsumerStatefulWidget {
  final String initialVideoPath;
  final String outputDirectory;

  const AiSmartCutDialog({
    super.key,
    required this.initialVideoPath,
    required this.outputDirectory,
  });

  @override
  ConsumerState<AiSmartCutDialog> createState() => _AiSmartCutDialogState();
}

class _AiSmartCutDialogState extends ConsumerState<AiSmartCutDialog> {
  int _targetDuration = 50; // seconds
  bool _isAnalyzing = false;
  String _statusMessage = '';
  double _progress = 0.0;
  List<AiCutSegment> _segments = [];
  List<SubtitleToken>? _cachedTokens;
  double? _cachedTotalSec;

  Future<void> _startAiAnalysis({bool forceWhisper = false}) async {
    if (!AiAssistantService.instance.isConfigured) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ИИ не настроен'),
          content: const Text(
            'Для авто-нарезки требуется указать API ключ нейросети (DeepSeek, OpenAI или Ollama).\n\nОткрыть настройки?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ОТМЕНА'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('НАСТРОЙКИ'),
            ),
          ],
        ),
      );

      if (openSettings == true && mounted) {
        await showDialog(
          context: context,
          builder: (_) => const AiSettingsDialog(),
        );
      }
      return;
    }

    // 0. Проверяем кэш (RAM или Диск): если видео уже транскрибировалось — используем сразу без Whisper!
    if (!forceWhisper) {
      var tokens = _cachedTokens;
      if (tokens == null || tokens.isEmpty) {
        tokens = await WhisperService.getCachedTokensForVideo(widget.initialVideoPath);
        if (tokens != null && tokens.isNotEmpty) {
          _cachedTokens = tokens;
          _cachedTotalSec = tokens.last.endMs / 1000.0;
        }
      }

      if (tokens != null && tokens.isNotEmpty) {
        setState(() {
          _isAnalyzing = true;
          _statusMessage =
              'Мгновенный старт из кэша (${tokens!.length} слов): нейросеть ${AiAssistantService.instance.model} делит на серии...';
          _progress = 0.75;
          _segments = [];
        });

        try {
          final segments = await AiAssistantService.instance.splitVideoIntoSegments(
            tokens: tokens,
            totalDurationSeconds: _cachedTotalSec ?? (tokens.last.endMs / 1000.0),
            targetDurationSec: _targetDuration,
          );

          if (mounted) {
            setState(() {
              _isAnalyzing = false;
              _progress = 1.0;
              _segments = segments;
              _statusMessage = segments.isNotEmpty
                  ? '✅ Найдено ${segments.length} готовых серий!'
                  : '⚠️ Нейросеть не смогла разбить. Попробуйте сменить модель или целевую длительность.';
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
              _statusMessage = 'Ошибка ответа ИИ: $e';
            });
          }
        }
        return;
      }
    }

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Извлечение аудиодорожки...';
      _progress = 0.1;
      _segments = [];
    });

    try {
      final whisperService = WhisperService();
      final dummyTask = VideoTask()
        ..inputFilePath = widget.initialVideoPath
        ..outputFolderPath = widget.outputDirectory;

      // 1. Извлечение аудио
      final tempDir = await getTemporaryDirectory();
      final tempWavPath =
          '${tempDir.path}/smart_cut_${DateTime.now().millisecondsSinceEpoch}.wav';
      final audioPath = await whisperService.extractAudioForWhisper(
        task: dummyTask,
        outputWavPath: tempWavPath,
      );
      if (audioPath == null || !File(audioPath).existsSync()) {
        throw Exception('Не удалось извлечь аудио из видеофайла');
      }

      setState(() {
        _statusMessage = 'Распознавание речи через Whisper AI (GPU/CPU)...';
        _progress = 0.35;
      });

      // 2. Транскрибация по словам
      final modelPath = await whisperService.ensureModelDownloaded();
      final tokens = await whisperService.runWhisperTranscription(
        wavPath: audioPath,
        modelPath: modelPath,
      );

      List<AiCutSegment> segments;

      if (tokens.isNotEmpty) {
        final lastTokenMs = tokens.last.endMs;
        final totalSec = lastTokenMs / 1000.0;
        _cachedTokens = tokens;
        _cachedTotalSec = totalSec;
        WhisperService.cacheTokensForVideo(widget.initialVideoPath, tokens);

        setState(() {
          _statusMessage =
              'Нейросеть ${AiAssistantService.instance.model} анализирует сюжет и делит на серии...';
          _progress = 0.75;
        });

        // 3. LLM нарезка по речи
        segments = await AiAssistantService.instance.splitVideoIntoSegments(
          tokens: tokens,
          totalDurationSeconds: totalSec,
          targetDurationSec: _targetDuration,
        );
      } else {
        // Fallback: умная нарезка по длительности видео + генерация хуков через нейросеть
        setState(() {
          _statusMessage = 'Определение длительности видео...';
          _progress = 0.55;
        });

        double totalSec = 60.0;
        try {
          if (Platform.isWindows) {
            final res = await Process.run('ffprobe', [
              '-v', 'error',
              '-show_entries', 'format=duration',
              '-of', 'default=noprint_wrappers=1:nokey=1',
              widget.initialVideoPath,
            ]);
            if (res.exitCode == 0) {
              totalSec = double.tryParse((res.stdout as String).trim()) ?? 60.0;
            }
          } else {
            final session = await FFprobeKit.getMediaInformation(widget.initialVideoPath);
            final info = session.getMediaInformation();
            if (info != null && info.getDuration() != null) {
              totalSec = double.tryParse(info.getDuration()!) ?? 60.0;
            }
          }
        } catch (e) {
          debugPrint('Duration probe fallback: $e');
        }

        setState(() {
          _statusMessage =
              'Нейросеть ${AiAssistantService.instance.model} генерирует интригующие хуки для серий...';
          _progress = 0.8;
        });

        segments = await AiAssistantService.instance.splitByDurationWithAiHooks(
          videoFileName: FileUtils.getFileName(widget.initialVideoPath),
          totalDurationSeconds: totalSec,
          targetDurationSec: _targetDuration == 0 ? 45 : _targetDuration,
        );
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _progress = 1.0;
          _segments = segments;
          _statusMessage = segments.isNotEmpty
              ? '✅ Найдено ${segments.length} готовых серий!'
              : '⚠️ Не удалось разделить на серии. Попробуйте нажать повтор.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusMessage = 'Ошибка анализа: $e';
        });
      }
    }
  }

  Future<void> _addAllSegmentsToQueue() async {
    if (_segments.isEmpty) return;

    final tasksToAdd = <VideoTask>[];
    for (final seg in _segments) {
      final task = VideoTask()
        ..inputFilePath = widget.initialVideoPath
        ..outputFolderPath = widget.outputDirectory
        ..startTime = seg.startTime
        ..endTime = seg.endTime
        ..partNumber = seg.partNumber
        ..textHook = seg.hook;
      tasksToAdd.add(task);
    }

    final notifier = ref.read(taskQueueProvider.notifier);
    await notifier.addCustomTasks(tasksToAdd);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🚀 ${_segments.length} серий с таймингами и хуками добавлены в очередь!',
          ),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = FileUtils.getFileName(widget.initialVideoPath);

    return AlertDialog(
      actionsOverflowButtonSpacing: 8,
      actionsOverflowDirection: VerticalDirection.down,
      title: const Row(
        children: [
          Icon(Icons.auto_fix_high, color: Color(0xFFFE2C55)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'ИИ Авто-Нарезка на Серии',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.video_file, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Режим нарезки и длительность:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('🔥 Авто-Клиффхэнгер'),
                    selected: _targetDuration == 0,
                    onSelected: _isAnalyzing
                        ? null
                        : (_) => setState(() => _targetDuration = 0),
                  ),
                  ChoiceChip(
                    label: const Text('30–45 сек (Short)'),
                    selected: _targetDuration == 35,
                    onSelected: _isAnalyzing
                        ? null
                        : (_) => setState(() => _targetDuration = 35),
                  ),
                  ChoiceChip(
                    label: const Text('45–60 сек (Стандарт)'),
                    selected: _targetDuration == 50,
                    onSelected: _isAnalyzing
                        ? null
                        : (_) => setState(() => _targetDuration = 50),
                  ),
                  ChoiceChip(
                    label: const Text('60–90 сек (Длинные)'),
                    selected: _targetDuration == 75,
                    onSelected: _isAnalyzing
                        ? null
                        : (_) => setState(() => _targetDuration = 75),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isAnalyzing) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    color: const Color(0xFFFE2C55),
                    backgroundColor: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
              ] else if (_statusMessage.isNotEmpty) ...[
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_segments.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Сгенерированные серии (${_segments.length} шт.):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _segments.length,
                    itemBuilder: (context, index) {
                      final seg = _segments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFE2C55).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFE2C55),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Часть ${seg.partNumber}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${seg.startTime} ➔ ${seg.endTime}',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                seg.hook,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (!_isAnalyzing && _segments.isEmpty && _cachedTokens == null)
          FilledButton.icon(
            onPressed: () => _startAiAnalysis(),
            icon: const Icon(Icons.bolt),
            label: const Text('НАЧАТЬ АНАЛИЗ И НАРАЗКУ'),
          ),
        if (!_isAnalyzing && _segments.isEmpty && _cachedTokens != null) ...[
          OutlinedButton(
            onPressed: () => _startAiAnalysis(forceWhisper: true),
            child: const Text('ПЕРЕРАСПОЗНАТЬ'),
          ),
          FilledButton.icon(
            onPressed: () => _startAiAnalysis(),
            icon: const Icon(Icons.refresh),
            label: const Text('🔁 ПОВТОРИТЬ ЗАПРОС К ИИ'),
          ),
        ],
        if (_segments.isNotEmpty)
          FilledButton.icon(
            onPressed: _addAllSegmentsToQueue,
            icon: const Icon(Icons.playlist_add),
            label: Text('ДОБАВИТЬ ВСЕ ${_segments.length} СЕРИЙ В ОЧЕРЕДЬ'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ЗАКРЫТЬ'),
        ),
      ],
    );
  }
}

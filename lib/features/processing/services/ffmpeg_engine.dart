import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/ffmpeg/ffmpeg_filter_builder.dart';
import '../../../core/utils/font_extractor.dart';
import '../../presets/domain/render_preset.dart';
import '../../tasks/domain/video_task.dart';

class FfmpegEngine {
  /// Executes a render task asynchronously using FFmpeg.
  /// Automatically falls back from GPU NVENC to CPU encoding if GPU acceleration fails.
  /// Reports real-time progress (0.0 to 1.0) through [onProgress].
  /// Dumps raw execution logs into application documents /logs/ directory.
  /// Returns `null` on success; a human-readable error message on failure.
  Future<String?> executeTask({
    required VideoTask task,
    required RenderPreset preset,
    required String outputFilePath,
    String? gameplayVideoPath,
    String? backgroundAudioPath,
    String? subtitleAssPath,
    void Function(double progress)? onProgress,
  }) async {
    IOSink? logSink;
    try {
      // 1. Obtain font path for drawtext filter
      final fontPath = await FontExtractor.getFontPath();

      // 2. Prepare log file in ApplicationDocumentsDirectory/logs/
      final docDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${docDir.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      final logFile = File('${logsDir.path}/ffmpeg_task_${task.id}.log');
      logSink = logFile.openWrite(mode: FileMode.writeOnlyAppend);
      logSink.writeln('=== FFmpeg Task Start: ${DateTime.now()} ===');
      logSink.writeln('Input: ${task.inputFilePath}');
      logSink.writeln('Output: $outputFilePath');

      // 3. Obtain exact task duration in milliseconds (FFprobe probe + trim check)
      final totalMs = await _calculateTaskDurationMs(task);

      if (Platform.isWindows) {
        // Try NVENC first if on Windows
        var (exitCode, errMsg) = await _runWindowsFfmpeg(
          task: task,
          preset: preset,
          outputFilePath: outputFilePath,
          fontPath: fontPath,
          gameplayVideoPath: gameplayVideoPath,
          backgroundAudioPath: backgroundAudioPath,
          subtitleAssPath: subtitleAssPath,
          useNvenc: true,
          totalMs: totalMs,
          logSink: logSink,
          onProgress: onProgress,
        );

        // If NVENC fails (e.g. non-NVIDIA GPU, driver missing CUDA/NVENC), fallback to CPU libx264
        if (exitCode != 0 && _isNvencOrGpuError(errMsg)) {
          debugPrint('NVENC hardware acceleration failed ($errMsg). Falling back to CPU encoder (libx264)...');
          logSink.writeln('=== NVENC failed. Retrying with CPU libx264 fallback ===');

          final cpuResult = await _runWindowsFfmpeg(
            task: task,
            preset: preset,
            outputFilePath: outputFilePath,
            fontPath: fontPath,
            gameplayVideoPath: gameplayVideoPath,
            backgroundAudioPath: backgroundAudioPath,
            subtitleAssPath: subtitleAssPath,
            useNvenc: false,
            totalMs: totalMs,
            logSink: logSink,
            onProgress: onProgress,
          );
          exitCode = cpuResult.$1;
          errMsg = cpuResult.$2;
        }

        if (exitCode == 0) {
          onProgress?.call(1.0);
          return null;
        }
        return errMsg ?? 'FFmpeg вернул код ошибки $exitCode';
      }

      // Mobile / FFmpegKit Execution
      final result = FfmpegFilterBuilder.buildCommand(
        task: task,
        preset: preset,
        outputFilePath: outputFilePath,
        fontPath: fontPath,
        gameplayVideoPath: gameplayVideoPath,
        backgroundAudioPath: backgroundAudioPath,
        subtitleAssPath: subtitleAssPath,
        useNvenc: false,
      );

      final safeArgs = result.arguments.map((arg) {
        if (arg.contains(' ') && !arg.startsWith('"') && !arg.startsWith("'")) {
          return '"$arg"';
        }
        return arg;
      }).toList();

      final commandStr = safeArgs.join(' ');
      debugPrint('Executing FFmpegKit command: $commandStr');
      logSink.writeln('Command: $commandStr');

      final completer = Completer<String?>();

      await FFmpegKit.executeAsync(
        commandStr,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            debugPrint('FFmpeg task succeeded! (Code 0)');
            logSink?.writeln('=== FFmpeg Task Success (Code 0) ===');
            onProgress?.call(1.0);
            completer.complete(null);
          } else if (ReturnCode.isCancel(returnCode)) {
            debugPrint('FFmpeg task cancelled by user (Code 255)');
            logSink?.writeln('=== FFmpeg Task Cancelled (Code 255) ===');
            completer.complete('Отменено пользователем');
          } else {
            final logs = await session.getAllLogsAsString();
            debugPrint('FFmpeg task failed with code $returnCode: $logs');
            logSink?.writeln('=== FFmpeg Task Failed (Code: $returnCode) ===');
            logSink?.writeln(logs ?? '');
            completer.complete(_extractHumanError(logs ?? '', returnCode?.getValue()));
          }
        },
        (log) {
          final msg = log.getMessage();
          debugPrint('FFmpeg Log: $msg');
          logSink?.writeln(msg);
        },
        (statistics) {
          if (totalMs > 0 && onProgress != null) {
            final timeMs = statistics.getTime();
            if (timeMs > 0) {
              final progress = (timeMs / totalMs).clamp(0.0, 0.99);
              onProgress(progress);
            }
          }
        },
      );

      return await completer.future;
    } catch (e, stack) {
      debugPrint('Error executing FFmpeg Engine task: $e\n$stack');
      logSink?.writeln('Error: $e\n$stack');
      return 'Engine error: $e';
    } finally {
      if (logSink != null) {
        await logSink.flush();
        await logSink.close();
      }
    }
  }

  Future<(int, String?)> _runWindowsFfmpeg({
    required VideoTask task,
    required RenderPreset preset,
    required String outputFilePath,
    required String fontPath,
    String? gameplayVideoPath,
    String? backgroundAudioPath,
    String? subtitleAssPath,
    required bool useNvenc,
    required double totalMs,
    required IOSink logSink,
    void Function(double progress)? onProgress,
  }) async {
    final result = FfmpegFilterBuilder.buildCommand(
      task: task,
      preset: preset,
      outputFilePath: outputFilePath,
      fontPath: fontPath,
      gameplayVideoPath: gameplayVideoPath,
      backgroundAudioPath: backgroundAudioPath,
      subtitleAssPath: subtitleAssPath,
      useNvenc: useNvenc,
    );

    final commandStr = result.arguments.join(' ');
    debugPrint('Executing Windows FFmpeg (NVENC=$useNvenc): $commandStr');
    logSink.writeln('Command (NVENC=$useNvenc): $commandStr');

    try {
      final process = await Process.start('ffmpeg', result.arguments);
      final timeRegex = RegExp(r'time=(\d+):(\d+):(\d+\.\d+)');

      String? firstError;
      await for (final line in process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())) {
        try {
          logSink.writeln(line);
        } catch (_) {}
        final isErrorish = line.startsWith('Error') ||
            line.startsWith('Invalid') ||
            line.contains('Conversion failed') ||
            line.contains('No such') ||
            line.contains('Permission denied') ||
            line.contains('No space left') ||
            line.toLowerCase().contains('unknown encoder') ||
            line.toLowerCase().contains('cuda') ||
            line.toLowerCase().contains('nvenc');
        if (isErrorish && firstError == null) {
          firstError = line.trim();
        }
        final match = timeRegex.firstMatch(line);
        if (match != null && totalMs > 0 && onProgress != null) {
          final h = double.tryParse(match.group(1)!) ?? 0.0;
          final m = double.tryParse(match.group(2)!) ?? 0.0;
          final s = double.tryParse(match.group(3)!) ?? 0.0;
          final currentMs = (h * 3600 + m * 60 + s) * 1000.0;
          final progress = (currentMs / totalMs).clamp(0.0, 0.99);
          onProgress(progress);
        }
      }

      final exitCode = await process.exitCode;
      return (exitCode, firstError);
    } catch (e) {
      return (1, 'Failed to launch ffmpeg process: $e');
    }
  }

  bool _isNvencOrGpuError(String? error) {
    if (error == null) return false;
    final low = error.toLowerCase();
    return low.contains('nvenc') ||
        low.contains('cuda') ||
        low.contains('unknown encoder') ||
        low.contains('nvcuda') ||
        low.contains('hardware') ||
        low.contains('device creation');
  }

  /// Достаёт читаемую человеком причину падения из полного FFmpegKit-лога.
  String _extractHumanError(String logs, dynamic returnCodeValue) {
    final lines = logs.split('\n');
    for (var i = lines.length - 1; i >= 0; i--) {
      final l = lines[i].trim();
      final low = l.toLowerCase();
      if (low.startsWith('error') ||
          low.contains('conversion failed') ||
          low.contains('no such') ||
          low.contains('permission denied') ||
          low.contains('no space left') ||
          low.contains('unknown encoder')) {
        return l.isEmpty ? 'FFmpeg вернул код $returnCodeValue' : l;
      }
    }
    return 'FFmpeg завершился с кодом ошибки $returnCodeValue (подробности в логах приложения)';
  }

  /// Calculates total target video duration in milliseconds.
  Future<double> _calculateTaskDurationMs(VideoTask task) async {
    if (task.startTime != null &&
        task.startTime!.isNotEmpty &&
        task.endTime != null &&
        task.endTime!.isNotEmpty) {
      final startMs = _parseTimeStringToMs(task.startTime!);
      final endMs = _parseTimeStringToMs(task.endTime!);
      if (endMs > startMs) {
        return endMs - startMs;
      }
    }

    return await _getVideoDurationMs(task.inputFilePath);
  }

  /// Probes full video file duration in milliseconds via FFprobe.
  Future<double> _getVideoDurationMs(String filePath) async {
    try {
      if (Platform.isWindows) {
        final res = await Process.run('ffprobe', [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          filePath
        ]);
        if (res.exitCode == 0) {
          final durationSec = double.tryParse((res.stdout as String).trim()) ?? 0.0;
          return durationSec * 1000.0;
        }
      } else {
        final session = await FFprobeKit.getMediaInformation(filePath);
        final info = session.getMediaInformation();
        if (info != null && info.getDuration() != null) {
          final durationSec = double.tryParse(info.getDuration()!) ?? 0.0;
          return durationSec * 1000.0;
        }
      }
    } catch (e) {
      debugPrint('Error probing video duration: $e');
    }
    return 0.0;
  }

  /// Parses "hh:mm:ss" time string into milliseconds.
  double _parseTimeStringToMs(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 3) {
      final h = double.tryParse(parts[0]) ?? 0.0;
      final m = double.tryParse(parts[1]) ?? 0.0;
      final s = double.tryParse(parts[2]) ?? 0.0;
      return (h * 3600 + m * 60 + s) * 1000.0;
    }
    return 0.0;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../presets/domain/render_preset.dart';
import '../../tasks/domain/video_task.dart';
import '../domain/subtitle_token.dart';
import '../utils/ass_file_writer.dart';

enum WhisperModelType {
  tiny,
  base,
  small,
  largeV3Turbo,
}

class WhisperResult {
  final String? assPath;
  final String transcript;
  final List<SubtitleToken> tokens;

  const WhisperResult({
    this.assPath,
    this.transcript = '',
    this.tokens = const [],
  });
}

class WhisperService {
  static const Map<WhisperModelType, String> _modelUrls = {
    WhisperModelType.tiny:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
    WhisperModelType.base:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
    WhisperModelType.small:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
    WhisperModelType.largeV3Turbo:
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin',
  };

  static const Map<WhisperModelType, String> _modelFileNames = {
    WhisperModelType.tiny: 'ggml-tiny.bin',
    WhisperModelType.base: 'ggml-base.bin',
    WhisperModelType.small: 'ggml-small.bin',
    WhisperModelType.largeV3Turbo: 'ggml-large-v3-turbo.bin',
  };

  /// Ensures whisper-cli.exe and required DLLs are downloaded to ApplicationDocumentsDirectory/whisper_bin/.
  /// If [forceCpu] is true, downloads the universal CPU AVX2 binary.
  Future<String> ensureWhisperCliDownloaded({bool forceCpu = false}) async {
    final docDir = await getApplicationDocumentsDirectory();
    final binDir = Directory('${docDir.path}/whisper_bin');
    final exeFile = File('${binDir.path}/whisper-cli.exe');

    if (await exeFile.exists() && !forceCpu) {
      return exeFile.path;
    }

    if (!await binDir.exists()) {
      await binDir.create(recursive: true);
    }

    final zipPath = '${binDir.path}/whisper.zip';
    final zipFile = File(zipPath);

    final url = (Platform.isWindows && !forceCpu)
        ? 'https://github.com/ggml-org/whisper.cpp/releases/download/v1.9.1/whisper-cublas-12.4.0-bin-x64.zip'
        : 'https://github.com/ggml-org/whisper.cpp/releases/download/v1.9.1/whisper-bin-x64.zip';

    debugPrint('Downloading whisper-cli binaries from $url...');
    final response = await http.get(Uri.parse(url));
    await zipFile.writeAsBytes(response.bodyBytes);

    if (Platform.isWindows) {
      await Process.run('powershell', [
        '-Command',
        'Expand-Archive -Path "${zipFile.path}" -DestinationPath "${binDir.path}" -Force',
      ]);

      // Flatten directory structure: recursively copy all binaries (.exe, .dll) to binDir
      final entities = binDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.path.split(RegExp(r'[/\\]')).last;
          final targetFile = File('${binDir.path}/$fileName');
          if (entity.path != targetFile.path) {
            try {
              await entity.copy(targetFile.path);
            } catch (e) {
              debugPrint('Failed to copy binary ${entity.path}: $e');
            }
          }
        }
      }
    }

    if (await zipFile.exists()) {
      await zipFile.delete();
    }

    return exeFile.path;
  }

  /// Ensures specified Whisper GGML model binary is downloaded to ApplicationDocumentsDirectory/whisper_models/.
  /// Streams HTTP response with progress reporting (0.0 to 1.0) via [onProgress].
  Future<String> ensureModelDownloaded({
    WhisperModelType modelType = WhisperModelType.tiny,
    void Function(double progress)? onProgress,
  }) async {
    final docDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${docDir.path}/whisper_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    final fileName = _modelFileNames[modelType]!;
    final modelFile = File('${modelDir.path}/$fileName');

    // Check if valid model file already exists (size > 10MB)
    if (await modelFile.exists() && await modelFile.length() > 10 * 1024 * 1024) {
      debugPrint('Whisper model $fileName already cached at ${modelFile.path}');
      onProgress?.call(1.0);
      return modelFile.path;
    }

    final url = _modelUrls[modelType]!;
    debugPrint('Downloading Whisper model $fileName from $url...');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException(
          'HTTP ${response.statusCode}: Failed to download model $fileName from $url',
        );
      }

      final contentLength = response.contentLength ??
          (modelType == WhisperModelType.small ? 466000000 : 1600000000);
      int downloadedBytes = 0;
      final sink = modelFile.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (onProgress != null && contentLength > 0) {
          final progress = (downloadedBytes / contentLength).clamp(0.0, 1.0);
          onProgress(progress);
        }
      });

      await sink.flush();
      await sink.close();
      debugPrint('Whisper model $fileName successfully downloaded to: ${modelFile.path}');
      return modelFile.path;
    } catch (e) {
      debugPrint('Error downloading Whisper model $fileName: $e');
      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Extracts target audio slice from video file into 16kHz Mono PCM WAV format.
  /// First attempts system ffmpeg, then falls back to bundled FFmpegKit.
  Future<String?> extractAudioForWhisper({
    required VideoTask task,
    required String outputWavPath,
  }) async {
    try {
      final args = <String>['-y'];

      // Fast seek if task has startTime / endTime
      if (task.startTime != null &&
          task.startTime!.isNotEmpty &&
          task.endTime != null &&
          task.endTime!.isNotEmpty) {
        args.addAll(['-ss', task.startTime!, '-to', task.endTime!]);
      }

      args.addAll([
        '-i',
        task.inputFilePath,
        '-vn', // Disable video stream for ultra-fast extraction
        '-ar',
        '16000', // 16kHz sample rate required by Whisper
        '-ac',
        '1', // Mono audio channel
        '-c:a',
        'pcm_s16le', // Uncompressed 16-bit PCM WAV
        outputWavPath,
      ]);

      final commandStr = args.join(' ');
      debugPrint('Extracting audio for Whisper: $commandStr');

      if (Platform.isWindows) {
        try {
          final res = await Process.run('ffmpeg', args);
          if (res.exitCode == 0) {
            debugPrint('Audio extracted successfully to $outputWavPath via system ffmpeg');
            return outputWavPath;
          } else {
            debugPrint('System ffmpeg failed (Code ${res.exitCode}): ${res.stderr}. Retrying with FFmpegKit...');
          }
        } catch (e) {
          debugPrint('Process.run ffmpeg not found: $e. Falling back to FFmpegKit...');
        }
      }

      final session = await FFmpegKit.execute(commandStr);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('Audio extracted successfully to $outputWavPath via FFmpegKit');
        return outputWavPath;
      } else {
        final logs = await session.getAllLogsAsString();
        debugPrint('Failed to extract audio for Whisper (Code $returnCode): $logs');
        return null;
      }
    } catch (e, stack) {
      debugPrint('Error in extractAudioForWhisper: $e\n$stack');
      return null;
    }
  }

  /// Transcribes input WAV audio file into word-level subtitle tokens with exact timestamps via whisper-cli.
  /// If GPU/cuBLAS fails, falls back automatically to CPU-based whisper-cli.
  Future<List<SubtitleToken>> runWhisperTranscription({
    required String wavPath,
    required String modelPath,
  }) async {
    debugPrint('Running Whisper AI transcription on $wavPath using $modelPath...');

    try {
      final wavFile = File(wavPath);
      if (!await wavFile.exists()) {
        debugPrint('WAV file does not exist: $wavPath');
        return [];
      }

      var cliPath = await ensureWhisperCliDownloaded();
      var tokens = await _executeWhisperProcess(cliPath: cliPath, wavPath: wavPath, modelPath: modelPath);

      // If failed on Windows (e.g. missing cuBLAS / CUDA DLLs), fallback to CPU binary
      if (tokens.isEmpty && Platform.isWindows) {
        debugPrint('Whisper execution failed. Retrying with universal CPU binary...');
        cliPath = await ensureWhisperCliDownloaded(forceCpu: true);
        tokens = await _executeWhisperProcess(cliPath: cliPath, wavPath: wavPath, modelPath: modelPath);
      }

      return tokens;
    } catch (e, stack) {
      debugPrint('Error in runWhisperTranscription: $e\n$stack');
      return [];
    }
  }

  Future<List<SubtitleToken>> _executeWhisperProcess({
    required String cliPath,
    required String wavPath,
    required String modelPath,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputJsonPrefix = '${tempDir.path}/whisper_${DateTime.now().millisecondsSinceEpoch}';
      final outputJsonFile = File('$outputJsonPrefix.json');

      final cliDir = File(cliPath).parent.path;
      final args = [
        '-m',
        modelPath,
        '-f',
        wavPath,
        '-l',
        'auto',
        '-t',
        '${Platform.numberOfProcessors}',
        '-sow',
        '-ojf',
        '-of',
        outputJsonPrefix,
      ];

      debugPrint('Executing whisper-cli: $cliPath ${args.join(' ')}');
      final result = await Process.run(cliPath, args, workingDirectory: cliDir);

      if (result.stderr.toString().isNotEmpty) {
        debugPrint('whisper-cli log: ${result.stderr}');
      }

      if (result.exitCode != 0) {
        debugPrint('whisper-cli failed (Code ${result.exitCode}): ${result.stderr}');
        return [];
      }

      if (!await outputJsonFile.exists()) {
        debugPrint('whisper-cli output JSON not found: ${outputJsonFile.path}');
        return [];
      }

      final jsonContent = await outputJsonFile.readAsString();
      final jsonData = jsonDecode(jsonContent) as Map<String, dynamic>;

      final tokens = <SubtitleToken>[];
      final transcription = jsonData['transcription'] as List?;

      if (transcription != null) {
        for (final segment in transcription) {
          final tokensList = segment['tokens'] as List?;
          if (tokensList == null) continue;

          String currentWord = '';
          int? wordStartMs;
          int? wordEndMs;

          for (final t in tokensList) {
            final text = t['text'] as String? ?? '';
            if (text.startsWith('[') && text.endsWith(']')) continue;

            final fromMs = (t['offsets']?['from'] as num?)?.toInt() ?? 0;
            final toMs = (t['offsets']?['to'] as num?)?.toInt() ?? 0;

            if (text.startsWith(' ')) {
              if (currentWord.isNotEmpty && wordStartMs != null && wordEndMs != null) {
                tokens.add(
                  SubtitleToken(
                    word: currentWord.trim(),
                    startMs: wordStartMs,
                    endMs: wordEndMs,
                  ),
                );
              }
              currentWord = text.trim();
              wordStartMs = fromMs;
              wordEndMs = toMs;
            } else {
              currentWord += text;
              wordEndMs = toMs;
            }
          }

          if (currentWord.isNotEmpty && wordStartMs != null && wordEndMs != null) {
            tokens.add(
              SubtitleToken(
                word: currentWord.trim(),
                startMs: wordStartMs,
                endMs: wordEndMs,
              ),
            );
          }
        }
      }

      if (await outputJsonFile.exists()) {
        await outputJsonFile.delete();
      }

      debugPrint('Whisper AI transcribed ${tokens.length} word tokens.');
      return tokens;
    } catch (e) {
      debugPrint('_executeWhisperProcess error: $e');
      return [];
    }
  }

  /// End-to-end pipeline: Extracts audio, runs transcription, builds ASS file,
  /// and saves the resulting .ass subtitle file in TemporaryDirectory.
  Future<WhisperResult?> generateSubtitlesForTask({
    required VideoTask task,
    RenderPreset? preset,
    void Function(double progress, String statusMsg)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final wavPath = '${tempDir.path}/task_${task.id}_audio.wav';
      final assPath = '${tempDir.path}/task_${task.id}_subtitles.ass';

      // 1. Extract audio
      onProgress?.call(0.05, 'Извлечение звуковой дорожки...');
      final extractedWav =
          await extractAudioForWhisper(task: task, outputWavPath: wavPath);
      if (extractedWav == null) return null;

      // 2. Download/verify model
      onProgress?.call(0.10, 'Проверка нейросетевой модели Whisper...');
      final modelPath = await ensureModelDownloaded(
        modelType: WhisperModelType.tiny,
        onProgress: (p) {
          onProgress?.call(0.10 + p * 0.08, 'Загрузка модели Whisper (${(p * 100).toInt()}%)...');
        },
      );

      // 3. Run transcription
      onProgress?.call(0.18, 'Распознавание речи (Whisper AI)...');
      final tokens = await runWhisperTranscription(
        wavPath: extractedWav,
        modelPath: modelPath,
      );
      if (tokens.isEmpty) return null;

      final transcript = tokens.map((t) => t.word).join(' ').trim();

      // 4. Save ASS file to TemporaryDirectory
      onProgress?.call(0.24, 'Создание караоке-субтитров...');
      final speedFactor = 1.0 + (preset?.speedDelta ?? 0.0);
      final generatedAss = await AssFileWriter.generateAssFile(
        tokens: tokens,
        outputPath: assPath,
        position: preset?.subtitlePosition ?? SubtitlePosition.bottom,
        yRatio: preset?.subtitleYRatio,
        speedFactor: speedFactor,
      );

      return WhisperResult(
        assPath: generatedAss,
        transcript: transcript,
        tokens: tokens,
      );
    } catch (e, stack) {
      debugPrint('Error generating subtitles for task ${task.id}: $e\n$stack');
      return null;
    }
  }

  /// Удаляет temp-файлы конкретной задачи (WAV + ASS), чтобы TemporaryDirectory
  /// не раздувался на долгих батчах.
  Future<void> cleanupTaskTempFiles(int taskId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final wav = File('${tempDir.path}/task_${taskId}_audio.wav');
      final ass = File('${tempDir.path}/task_${taskId}_subtitles.ass');
      if (await wav.exists()) await wav.delete();
      if (await ass.exists()) await ass.delete();
    } catch (e) {
      debugPrint('cleanupTaskTempFiles failed: $e');
    }
  }
}

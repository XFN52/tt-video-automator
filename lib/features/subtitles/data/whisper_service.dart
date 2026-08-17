import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart' as wfn;
import '../../presets/domain/render_preset.dart';
import '../../tasks/domain/video_task.dart';
import '../../ai_assistant/data/ai_assistant_service.dart';
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
        '-threads', '4',
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

      // Safe argument quoting for FFmpegKit
      final safeCommand = args.map((a) => a.contains(' ') ? '"$a"' : a).join(' ');
      debugPrint('Extracting audio for Whisper: $safeCommand');

      final session = await FFmpegKit.execute(safeCommand);
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

  /// Transcribes input WAV audio file into word-level subtitle tokens with exact timestamps.
  Future<List<SubtitleToken>> runWhisperTranscription({
    required String wavPath,
    required String modelPath,
  }) async {
    debugPrint('Running Whisper AI transcription on $wavPath...');

    try {
      final wavFile = File(wavPath);
      if (!await wavFile.exists()) {
        debugPrint('WAV file does not exist: $wavPath');
        return [];
      }

      // On Android / iOS, transcribe via on-device Whisper engine (whisper.cpp NDK)
      if (Platform.isAndroid || Platform.isIOS) {
        final localTokens = await _transcribeViaWhisperFlutter(
          wavPath: wavPath,
          modelPath: modelPath,
        );
        if (localTokens.isNotEmpty) {
          return localTokens;
        }
        // Fallback to Cloud Whisper if on-device model not available
        return await _transcribeViaCloudApi(wavPath: wavPath);
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

  static Completer<void>? _activeWhisperJob;

  static Future<T> _synchronizedWhisper<T>(Future<T> Function() block) async {
    while (_activeWhisperJob != null) {
      await _activeWhisperJob!.future;
    }
    final completer = Completer<void>();
    _activeWhisperJob = completer;
    try {
      return await block();
    } finally {
      _activeWhisperJob = null;
      completer.complete();
    }
  }

  Future<List<SubtitleToken>> _transcribeViaWhisperFlutter({
    required String wavPath,
    String? modelPath,
  }) async {
    return _synchronizedWhisper(() async {
      try {
        final modelDirectory = (modelPath != null && modelPath.isNotEmpty)
            ? File(modelPath).parent.path
            : null;
        final whisper = wfn.Whisper(
          model: wfn.WhisperModel.tiny,
          modelDir: modelDirectory,
        );

        final res = await whisper.transcribe(
          transcribeRequest: wfn.TranscribeRequest(
            audio: wavPath,
            language: 'ru',
            isTranslate: false,
            isNoTimestamps: false,
            splitOnWord: false,
          ),
        );

        debugPrint('On-device Whisper raw text: ${res.text}');
        final tokens = <SubtitleToken>[];
        final segments = res.segments;

        if (segments != null && segments.isNotEmpty) {
          for (final seg in segments) {
            final segText = seg.text?.trim() ?? '';
            final fromMs = seg.fromTs?.inMilliseconds ?? 0;
            final toMs = seg.toTs?.inMilliseconds ?? (fromMs + 1000);
            if (segText.isNotEmpty) {
              final words = segText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
              if (words.isNotEmpty) {
                final totalDuration = (toMs - fromMs).clamp(200, 60000);
                final wordDur = totalDuration ~/ words.length;
                for (int i = 0; i < words.length; i++) {
                  tokens.add(SubtitleToken(
                    word: words[i],
                    startMs: fromMs + i * wordDur,
                    endMs: fromMs + (i + 1) * wordDur,
                  ));
                }
              }
            }
          }
        }

      if (tokens.isEmpty && res.text != null && res.text!.trim().isNotEmpty) {
        final words = res.text!.trim().split(RegExp(r'\s+'));
        const wordDurationMs = 300;
        for (int i = 0; i < words.length; i++) {
          tokens.add(SubtitleToken(
            word: words[i],
            startMs: i * wordDurationMs,
            endMs: (i + 1) * wordDurationMs,
          ));
        }
      }

      debugPrint('On-device Whisper parsed ${tokens.length} tokens');
      return tokens;
    } catch (e, stack) {
      debugPrint('On-device Whisper error: $e\n$stack');
      return [];
    }
    });
  }

  Future<List<SubtitleToken>> _transcribeViaCloudApi({
    required String wavPath,
  }) async {
    try {
      final ai = AiAssistantService.instance;
      if (!ai.isConfigured || ai.apiKey.isEmpty) {
        debugPrint('Cloud Whisper: AI key not configured');
        return [];
      }

      var url = '${ai.baseUrl}/audio/transcriptions';
      if (ai.baseUrl.contains('deepseek')) {
        url = 'https://api.openai.com/v1/audio/transcriptions';
      }

      debugPrint('Sending audio to Cloud Whisper endpoint: $url');
      final req = http.MultipartRequest('POST', Uri.parse(url));
      req.headers['Authorization'] = 'Bearer ${ai.apiKey}';
      req.fields['model'] = 'whisper-1';
      req.fields['response_format'] = 'verbose_json';
      req.fields['timestamp_granularities[]'] = 'word';
      req.files.add(await http.MultipartFile.fromPath('file', wavPath));

      final streamedResponse = await req.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final tokens = <SubtitleToken>[];
        final words = json['words'] as List?;
        if (words != null && words.isNotEmpty) {
          for (final w in words) {
            final wordText = (w['word'] ?? '').toString().trim();
            final startSec = (w['start'] as num?)?.toDouble() ?? 0.0;
            final endSec = (w['end'] as num?)?.toDouble() ?? 0.0;
            if (wordText.isNotEmpty) {
              tokens.add(SubtitleToken(
                word: wordText,
                startMs: (startSec * 1000).round(),
                endMs: (endSec * 1000).round(),
              ));
            }
          }
        } else {
          final segments = json['segments'] as List?;
          if (segments != null) {
            for (final seg in segments) {
              final text = (seg['text'] ?? '').toString().trim();
              final startSec = (seg['start'] as num?)?.toDouble() ?? 0.0;
              final endSec = (seg['end'] as num?)?.toDouble() ?? 0.0;
              if (text.isNotEmpty) {
                tokens.add(SubtitleToken(
                  word: text,
                  startMs: (startSec * 1000).round(),
                  endMs: (endSec * 1000).round(),
                ));
              }
            }
          }
        }
        debugPrint('Cloud Whisper transcribed ${tokens.length} tokens successfully.');
        return tokens;
      } else {
        debugPrint('Cloud Whisper returned ${res.statusCode}: ${res.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Cloud Whisper error: $e');
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

  static final Map<String, List<SubtitleToken>> _videoTokensCache = {};

  /// Caches recognized tokens for a video in memory and persists to disk cache
  static void cacheTokensForVideo(String videoPath, List<SubtitleToken> tokens) {
    final key = _diskCacheKey(videoPath);
    _videoTokensCache[key] = tokens;
    _saveTokensToDiskCache(videoPath, tokens);
  }

  /// Returns cached tokens from RAM or persistent disk cache if available
  static Future<List<SubtitleToken>?> getCachedTokensForVideo(String videoPath) async {
    final key = _diskCacheKey(videoPath);
    if (_videoTokensCache.containsKey(key) && _videoTokensCache[key]!.isNotEmpty) {
      return _videoTokensCache[key];
    }
    return await _loadTokensFromDiskCache(videoPath);
  }

  static String _diskCacheKey(String path) {
    String cleanPath = path;
    String sliceSuffix = '';
    if (path.contains('#')) {
      final parts = path.split('#');
      cleanPath = parts[0];
      sliceSuffix = '_slice_${parts[1].replaceAll(':', '_')}';
    }

    int fileSize = 0;
    try {
      final file = File(cleanPath);
      if (file.existsSync()) {
        fileSize = file.lengthSync();
      }
    } catch (_) {}

    final filename = cleanPath.split(RegExp(r'[\\/]')).last;
    final cleanName = filename.replaceAll(RegExp(r'[^\w\dа-яА-ЯёЁ\-\.]'), '_');
    final prefix = cleanName.length > 35 ? cleanName.substring(0, 35) : cleanName;
    return '${prefix}_size${fileSize}$sliceSuffix';
  }

  static Future<void> _saveTokensToDiskCache(String videoPath, List<SubtitleToken> tokens) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docDir.path}/whisper_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      final cacheFile = File('${cacheDir.path}/${_diskCacheKey(videoPath)}.json');
      final jsonList = tokens
          .map((t) => {'w': t.word, 's': t.startMs, 'e': t.endMs})
          .toList();
      await cacheFile.writeAsString(jsonEncode(jsonList));
      debugPrint('WhisperService: Persisted ${tokens.length} tokens to disk cache -> ${cacheFile.path}');
    } catch (e) {
      debugPrint('WhisperService: Failed to save disk cache: $e');
    }
  }

  static Future<List<SubtitleToken>?> _loadTokensFromDiskCache(String videoPath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${docDir.path}/whisper_cache/${_diskCacheKey(videoPath)}.json');
      if (await cacheFile.exists()) {
        final content = await cacheFile.readAsString();
        final decoded = jsonDecode(content) as List?;
        if (decoded != null && decoded.isNotEmpty) {
          final tokens = decoded
              .map((item) => SubtitleToken(
                    word: item['w'] as String? ?? '',
                    startMs: (item['s'] as num?)?.toInt() ?? 0,
                    endMs: (item['e'] as num?)?.toInt() ?? 0,
                  ))
              .toList();
          final key = _diskCacheKey(videoPath);
          _videoTokensCache[key] = tokens;
          debugPrint('WhisperService: Loaded ${tokens.length} tokens from disk cache -> ${cacheFile.path}');
          return tokens;
        }
      }
    } catch (e) {
      debugPrint('WhisperService: Failed to load disk cache: $e');
    }
    return null;
  }

  /// Asynchronously pre-warms the Whisper cache for a video file in the background
  static Future<void> preWarmCacheForVideo(String videoPath) async {
    try {
      final cached = await getCachedTokensForVideo(videoPath);
      if (cached != null && cached.isNotEmpty) return;

      final tempDir = await getTemporaryDirectory();
      final key = _diskCacheKey(videoPath);
      final wavPath = '${tempDir.path}/prewarm_${key}.wav';

      final svc = WhisperService();
      final dummyTask = VideoTask()
        ..inputFilePath = videoPath
        ..outputFolderPath = '';
      final extracted = await svc.extractAudioForWhisper(task: dummyTask, outputWavPath: wavPath);
      if (extracted != null) {
        final modelPath = await svc.ensureModelDownloaded(modelType: WhisperModelType.tiny);
        final tokens = await svc.runWhisperTranscription(wavPath: extracted, modelPath: modelPath);
        if (tokens.isNotEmpty) {
          cacheTokensForVideo(videoPath, tokens);
          debugPrint('WhisperService: Pre-warm completed for $videoPath (${tokens.length} tokens)');
        }
        try {
          final f = File(extracted);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('WhisperService: Pre-warm error: $e');
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

      // 0. Instant Cache Check (RAM or Disk) for full video or exact slice:
      final key = _diskCacheKey(task.inputFilePath);
      List<SubtitleToken>? fullTokens = _videoTokensCache[key] ??
          await _loadTokensFromDiskCache(task.inputFilePath);

      // Check slice-specific cache if not full
      final sliceKey = '${task.inputFilePath}#${task.startTime}_${task.endTime}';
      final sliceKeyId = _diskCacheKey(sliceKey);
      fullTokens ??= _videoTokensCache[sliceKeyId] ??
          await _loadTokensFromDiskCache(sliceKey);

      if (fullTokens != null && fullTokens.isNotEmpty) {
        final isTrimmed = task.startTime != null &&
            task.startTime!.isNotEmpty &&
            task.endTime != null &&
            task.endTime!.isNotEmpty;

        final startMs = isTrimmed ? _parseTimeToMs(task.startTime!) : 0;
        final endMs = isTrimmed ? _parseTimeToMs(task.endTime!) : 86400000;

        final slicedTokens = <SubtitleToken>[];
        for (final t in fullTokens) {
          if (t.endMs >= startMs && t.startMs <= endMs) {
            final relStart = isTrimmed ? (t.startMs - startMs).clamp(0, 86400000) : t.startMs;
            final relEnd = isTrimmed ? (t.endMs - startMs).clamp(relStart, 86400000) : t.endMs;
            slicedTokens.add(
              SubtitleToken(
                word: t.word,
                startMs: relStart,
                endMs: relEnd,
              ),
            );
          }
        }

        final effectiveTokens = slicedTokens.isNotEmpty ? slicedTokens : fullTokens;
        debugPrint('Task #${task.id}: Reusing ${effectiveTokens.length} cached Whisper tokens (0s Whisper time)!');
        onProgress?.call(0.24, 'Мгновенное создание караоке-субтитров из кэша...');
        final speedFactor = 1.0 + (preset?.speedDelta ?? 0.0);
        final generatedAss = await AssFileWriter.generateAssFile(
          tokens: effectiveTokens,
          outputPath: assPath,
          position: preset?.subtitlePosition ?? SubtitlePosition.bottom,
          yRatio: preset?.subtitleYRatio,
          speedFactor: speedFactor,
        );
        final transcript = effectiveTokens.map((t) => t.word).join(' ').trim();

        return WhisperResult(
          assPath: generatedAss,
          transcript: transcript,
          tokens: effectiveTokens,
        );
      }

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

      // 3.5. Cache recognized tokens globally (RAM + Disk) for instant future re-use!
      if (task.startTime == null || task.startTime!.isEmpty) {
        cacheTokensForVideo(task.inputFilePath, tokens);
      } else {
        cacheTokensForVideo(sliceKey, tokens);
      }

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

  static int _parseTimeToMs(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = double.tryParse(parts[2]) ?? 0.0;
        return ((h * 3600 + m * 60 + s) * 1000).round();
      } else if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = double.tryParse(parts[1]) ?? 0.0;
        return ((m * 60 + s) * 1000).round();
      }
    } catch (_) {}
    return 0;
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../presets/domain/render_preset.dart';
import '../../subtitles/domain/subtitle_token.dart';
import '../../tasks/domain/video_task.dart';

/// High-performance Zero-Copy Native GPU Video Rendering Engine bridge for Android.
/// Runs hardware-accelerated OpenGL ES 3.0 shaders + MediaCodec Surface-to-Surface
/// video rendering pipeline with 100-200+ FPS rendering speeds.
class NativeGpuEngine {
  static final NativeGpuEngine instance = NativeGpuEngine._internal();
  NativeGpuEngine._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const MethodChannel _channel =
      MethodChannel('com.example.tt_video_automator/gpu_engine');

  final Map<String, void Function(double progress)> _progressListeners = {};

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onProgress') {
      final args = call.arguments as Map?;
      final path = args?['outputPath'] as String?;
      final p = (args?['progress'] as num?)?.toDouble() ?? 0.0;
      if (path != null && _progressListeners.containsKey(path)) {
        _progressListeners[path]?.call(p);
      }
    }
  }

  /// Checks if hardware OpenGL ES 3.0 Surface pipeline is supported on the current device
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      final supported = await _channel.invokeMethod<bool>('isSupported');
      return supported ?? false;
    } catch (e) {
      debugPrint('NativeGpuEngine.isSupported check error: $e');
      return false;
    }
  }

  /// Executes GPU video rendering for a specific video task.
  Future<bool> renderTask({
    required VideoTask task,
    required RenderPreset preset,
    required String outputFilePath,
    List<SubtitleToken>? tokens,
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isAndroid) return false;

    try {
      final outputPath = outputFilePath;
      if (onProgress != null) {
        _progressListeners[outputPath] = onProgress;
      }

      // Convert timestamps to microseconds
      final startUs = task.startTime != null && task.startTime!.isNotEmpty
          ? (_parseTimeToMs(task.startTime!) * 1000)
          : 0;
      final endUs = task.endTime != null && task.endTime!.isNotEmpty
          ? (_parseTimeToMs(task.endTime!) * 1000)
          : 9223372036854775807; // Long.MAX_VALUE

      final subtitlesList = (preset.useWhisper && preset.showSubtitles)
          ? tokens?.map((t) => {
                'word': t.word,
                'text': t.word,
                'startMs': t.startMs,
                'endMs': t.endMs,
              }).toList()
          : null;

      final bannerXRatio = preset.bannerXRatio ?? 0.0;
      final bannerYRatio = preset.bannerYRatio ??
          (preset.bannerPosition == BannerPosition.top ? (100.0 / 1280.0) : (1080.0 / 1280.0));
      final bannerWidthRatio = preset.bannerWidthRatio ?? 1.0;
      final bannerHeightRatio = preset.bannerHeightRatio ?? 0.161;

      final subtitleYRatio = preset.subtitleYRatio;

      final partNumberText = (preset.autoNumbering && task.partNumber != null)
          ? 'ЧАСТЬ ${task.partNumber}'
          : null;

      final textHook = (task.textHook?.trim().isNotEmpty == true)
          ? task.textHook!.trim()
          : (preset.textHook?.trim().isNotEmpty == true ? preset.textHook!.trim() : null);

      final args = <String, dynamic>{
        'inputPath': task.inputFilePath,
        'outputPath': outputPath,
        'outputWidth': 720,
        'outputHeight': 1280,
        'bitrate': 2000000,
        'startTimeUs': startUs,
        'endTimeUs': endUs,
        'brightness': (preset.colorDelta * 0.5),
        'contrast': (1.0 + preset.colorDelta),
        'saturation': (1.0 + preset.colorDelta * 0.8),
        'noiseLevel': (preset.noiseLevel > 0 ? (preset.noiseLevel * 0.015).clamp(0.0, 0.04) : 0.0),
        'isMirrored': preset.isMirrored,
        'bannerPath': preset.bannerPath,
        'bannerXRatio': bannerXRatio,
        'bannerYRatio': bannerYRatio,
        'bannerWidthRatio': bannerWidthRatio,
        'bannerHeightRatio': bannerHeightRatio,
        'subtitles': subtitlesList,
        'subtitleYRatio': subtitleYRatio,
        'partNumberText': partNumberText,
        'numberingYRatio': preset.numberingYRatio,
        'textHook': textHook,
        'textHookYRatio': preset.textHookYRatio,
      };

      debugPrint('NativeGpuEngine: Dispatching task #${task.id} to native OpenGL ES 3.0 hardware engine...');
      final result = await _channel.invokeMethod<Map>('renderVideoTask', args);
      final success = result?['success'] as bool? ?? false;
      debugPrint('NativeGpuEngine: Task #${task.id} finished with status: $success');
      return success;
    } catch (e, stack) {
      debugPrint('NativeGpuEngine renderTask error: $e\n$stack');
      return false;
    } finally {
      _progressListeners.remove(outputFilePath);
    }
  }

  static int _parseTimeToMs(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final secParts = parts[2].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0').substring(0, 3)) : 0;
        return (hours * 3600 + minutes * 60 + seconds) * 1000 + millis;
      }
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final secParts = parts[1].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0').substring(0, 3)) : 0;
        return (minutes * 60 + seconds) * 1000 + millis;
      }
      final sec = double.tryParse(timeStr) ?? 0.0;
      return (sec * 1000).toInt();
    } catch (_) {
      return 0;
    }
  }
}

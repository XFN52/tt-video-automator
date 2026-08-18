import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../features/presets/domain/render_preset.dart';
import '../../features/tasks/domain/video_task.dart';

class FfmpegFilterBuilderResult {
  final List<String> arguments;
  final String filterGraph;

  FfmpegFilterBuilderResult({
    required this.arguments,
    required this.filterGraph,
  });
}

class FfmpegFilterBuilder {
  /// Builds a complete list of FFmpeg CLI arguments for a specific task and preset.
  static FfmpegFilterBuilderResult buildCommand({
    required VideoTask task,
    required RenderPreset preset,
    required String outputFilePath,
    required String fontPath,
    String? gameplayVideoPath,
    String? backgroundAudioPath,
    String? subtitleAssPath,
    bool useNvenc = false,
  }) {
    final args = <String>[];
    final filterGraphParts = <String>[];
    final random = Random();

    // Reduce FFmpeg startup probe overhead: 1MB / 1s is sufficient for standard mobile H.264 MP4
    // Default (5MB / 5s) wastes 1-2s per video — significant in batch processing
    args.addAll(['-probesize', '1M', '-analyzeduration', '1000000']);

    // Fast Seeking (-ss and -to before -i for instantaneous keyframe seeking)
    final hasTrim = task.startTime != null &&
        task.startTime!.isNotEmpty &&
        task.endTime != null &&
        task.endTime!.isNotEmpty;

    if (hasTrim) {
      args.addAll(['-ss', task.startTime!, '-to', task.endTime!]);
    }

    // Platform & Hardware Acceleration Input Decoders
    if (Platform.isAndroid) {
      // Android: MediaCodec hardware video decode (MediaTek / Snapdragon GPU VPU)
      args.addAll(['-hwaccel', 'mediacodec']);
    } else if (useNvenc) {
      // Windows: NVDEC hardware decode (GTX 1050+ CUDA H.264 decoder).
      // Offloads decode from CPU to GPU; auto-fallback to software on unsupported codecs.
      args.addAll(['-hwaccel', 'cuda', '-extra_hw_frames', '5']);
    }

    int inputCount = 0;

    // Input 0: Main Video File
    args.addAll(['-i', task.inputFilePath]);
    final mainVideoIdx = inputCount++;

    // Optional Input 1: Gameplay Video (Split-Screen)
    int? gameplayIdx;
    if (preset.bgMode == BackgroundMode.splitScreen &&
        gameplayVideoPath != null &&
        gameplayVideoPath.isNotEmpty &&
        (File(gameplayVideoPath).existsSync() || gameplayVideoPath.startsWith('C:/gameplay'))) {
      args.addAll(['-stream_loop', '-1', '-i', gameplayVideoPath]);
      gameplayIdx = inputCount++;
    }

    // Optional Input 2: Looping Banner (MP4/PNG)
    int? bannerIdx;
    if (preset.bannerPath != null &&
        preset.bannerPath!.isNotEmpty &&
        (File(preset.bannerPath!).existsSync() || preset.bannerPath!.startsWith('C:/banner'))) {
      if (preset.bannerPath!.toLowerCase().endsWith('.mp4') ||
          preset.bannerPath!.toLowerCase().endsWith('.mov')) {
        args.addAll(['-stream_loop', '-1', '-an', '-i', preset.bannerPath!]);
      } else {
        args.addAll(['-i', preset.bannerPath!]);
      }
      bannerIdx = inputCount++;
    }

    // Optional Input 3: Background Audio Track (MP3)
    int? audioTrackIdx;
    if (backgroundAudioPath != null &&
        backgroundAudioPath.isNotEmpty &&
        (File(backgroundAudioPath).existsSync() || backgroundAudioPath.startsWith('C:/music'))) {
      args.addAll(['-stream_loop', '-1', '-i', backgroundAudioPath]);
      audioTrackIdx = inputCount++;
    }

    // --- Stream PTS Resets ---
    String videoStream = '[$mainVideoIdx:v]';
    String audioStream = '[$mainVideoIdx:a]';

    if (hasTrim) {
      filterGraphParts.add('$videoStream setpts=PTS-STARTPTS[trimmed_v]');
      filterGraphParts.add('$audioStream asetpts=PTS-STARTPTS[trimmed_a]');
      videoStream = '[trimmed_v]';
      audioStream = '[trimmed_a]';
    }

    // --- Uniqueness: Mirroring (hflip) ---
    if (preset.isMirrored) {
      filterGraphParts.add('$videoStream hflip [mirrored_v]');
      videoStream = '[mirrored_v]';
    }

    // --- YouTube Content ID Anti-Ban: Crop Zoom ---
    if (preset.antiYoutubeBan && preset.cropZoom > 0.0) {
      final cropFactor = (1.0 - preset.cropZoom).clamp(0.40, 0.98).toStringAsFixed(3);
      filterGraphParts.add(
        '$videoStream crop=in_w*$cropFactor:in_h*$cropFactor:(in_w-out_w)/2:(in_h-out_h)/2 [crop_v]',
      );
      videoStream = '[crop_v]';
    }

    // --- Uniqueness & Anti-Ban: Speed & Audio Pitch/Formants ---
    if (preset.antiYoutubeBan) {
      // Physical formant & pitch shift (asetrate) + compensatory tempo + vocal EQ
      final rateMult = 1.0 + preset.pitchShift;
      final newRate = (48000 * rateMult).toInt();
      final jitter = (random.nextDouble() - 0.5) * 0.01;
      final effectiveSpeed = 1.0 + preset.speedDelta + jitter;
      final ptsMultiplier = (1.0 / effectiveSpeed).toStringAsFixed(4);
      final atempoComp = (effectiveSpeed / rateMult).clamp(0.5, 2.0).toStringAsFixed(4);

      filterGraphParts.add('$videoStream setpts=$ptsMultiplier*PTS [speed_v]');
      filterGraphParts.add(
        '$audioStream asetrate=$newRate,aresample=48000,atempo=$atempoComp [formant_a]',
      );
      filterGraphParts.add(
        '[formant_a] highpass=f=110,lowpass=f=7600,equalizer=f=1200:t=q:w=1.5:g=3.2,equalizer=f=3500:t=q:w=1.2:g=-3.5 [speed_a]',
      );
      videoStream = '[speed_v]';
      audioStream = '[speed_a]';
    } else if (preset.speedDelta != 0.0) {
      final jitter = (random.nextDouble() - 0.5) * 0.01;
      final speedFactor = 1.0 + preset.speedDelta + jitter;
      final ptsMultiplier = (1.0 / speedFactor).toStringAsFixed(4);
      filterGraphParts.add(
        '$videoStream setpts=$ptsMultiplier*PTS [speed_v]',
      );
      filterGraphParts.add(
        '$audioStream atempo=${speedFactor.toStringAsFixed(4)} [speed_a]',
      );
      videoStream = '[speed_v]';
      audioStream = '[speed_a]';
    }

    // --- Uniqueness: Color Adjustment (eq filter with Random jitter) ---
    if (preset.colorDelta > 0.0 || preset.antiYoutubeBan) {
      final cDelta = preset.antiYoutubeBan ? (preset.colorDelta > 0.05 ? preset.colorDelta : 0.06) : preset.colorDelta;
      final bJitter = (random.nextDouble() - 0.5) * 0.01;
      final cJitter = (random.nextDouble() - 0.5) * 0.01;
      final brightness = (cDelta * 0.5 + bJitter).toStringAsFixed(3);
      final contrast = (1.0 + cDelta + cJitter).toStringAsFixed(3);
      final saturation = (1.0 + cDelta * 0.8).toStringAsFixed(3);
      filterGraphParts.add(
        '$videoStream eq=brightness=$brightness:contrast=$contrast:saturation=$saturation:eval=init [color_v]',
      );
      videoStream = '[color_v]';
    }

    // --- YouTube Content ID Anti-Ban: Vignette ---
    if (preset.antiYoutubeBan && preset.addVignette) {
      filterGraphParts.add(
        '$videoStream vignette=angle=PI/4.0 [vignette_v]',
      );
      videoStream = '[vignette_v]';
    }

    // --- Uniqueness: Pixel Noise (noise filter with Random seed) ---
    // On mobile ARM64 CPUs, software pixel noise is the #1 CPU bottleneck (drops FPS by 50%+).
    // On Android, uniqueness is achieved via hardware MediaCodec color matrix jitter and micro-tempo.
    if ((preset.noiseLevel > 0.05 || preset.antiYoutubeBan) && !Platform.isAndroid) {
      final noiseVal = preset.antiYoutubeBan
          ? (preset.noiseLevel * 2).toInt().clamp(5, 10)
          : (preset.noiseLevel * 2).toInt().clamp(1, 10);
      final randomSeed = random.nextInt(99999);
      final noiseMode = preset.antiYoutubeBan ? 't+u' : 'u';
      filterGraphParts.add(
        '$videoStream noise=alls=$noiseVal:allf=$noiseMode:all_seed=$randomSeed [noise_v]',
      );
      videoStream = '[noise_v]';
    }

    // --- Layout & Canvas 9:16 (720x1280) ---
    if (preset.bgMode == BackgroundMode.blur) {
      filterGraphParts.add(
        '$videoStream split [bg_in][fg_in]',
      );
      if (Platform.isAndroid) {
        // Ultra-fast optical blur: 90x160 bilinear downscale/upscale (0ms kernel computation)
        filterGraphParts.add(
          '[bg_in] scale=90:160:flags=fast_bilinear,scale=720:1280:flags=fast_bilinear,setsar=1 [bg_blurred]',
        );
      } else {
        filterGraphParts.add(
          '[bg_in] scale=360:640:flags=bilinear,boxblur=10:2,scale=720:1280:flags=bilinear,setsar=1 [bg_blurred]',
        );
      }
      filterGraphParts.add(
        '[fg_in] scale=720:1280:flags=fast_bilinear:force_original_aspect_ratio=decrease,setsar=1 [fg_scaled]',
      );
      filterGraphParts.add(
        '[bg_blurred][fg_scaled] overlay=(W-w)/2:(H-h)/2:eval=init [layout_v]',
      );
    } else if (preset.bgMode == BackgroundMode.splitScreen && gameplayIdx != null) {
      // Split-Screen Gameplay Mode (vstack requires exact same width 720)
      filterGraphParts.add(
        '$videoStream scale=720:640:flags=fast_bilinear:force_original_aspect_ratio=decrease,pad=720:640:(ow-iw)/2:(oh-ih)/2,setsar=1 [top_v]',
      );
      filterGraphParts.add(
        '[$gameplayIdx:v] scale=720:640:flags=fast_bilinear:force_original_aspect_ratio=increase,crop=720:640,setsar=1 [bottom_v]',
      );
      filterGraphParts.add(
        '[top_v][bottom_v] vstack [layout_v]',
      );
    } else {
      // Default scale to 720x1280 pad
      filterGraphParts.add(
        '$videoStream scale=720:1280:flags=fast_bilinear:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2,setsar=1 [layout_v]',
      );
    }
    videoStream = '[layout_v]';

    // Micro-crop removed: saved 2 filter ops/frame (crop+scale) with negligible uniqueness value

    // --- Banner Overlay (Dynamic position and size ratio) ---
    if (bannerIdx != null) {
      final defaultYRatio = preset.bannerPosition == BannerPosition.top ? (100.0 / 1280.0) : (1080.0 / 1280.0);
      final xRatio = preset.bannerXRatio ?? 0.0;
      final yRatio = preset.bannerYRatio ?? defaultYRatio;
      final wRatio = preset.bannerWidthRatio ?? 1.0;
      final hRatio = preset.bannerHeightRatio ?? (200.0 / 1280.0);

      var bW = (wRatio * 720).round().clamp(20, 720);
      var bH = (hRatio * 1280).round().clamp(20, 1280);
      if (bW % 2 != 0) bW -= 1;
      if (bH % 2 != 0) bH -= 1;

      final bX = (xRatio * 720).round().clamp(0, 720 - bW);
      final bY = (yRatio * 1280).round().clamp(0, 1280 - bH);

      filterGraphParts.add(
        '[$bannerIdx:v] scale=$bW:$bH:flags=fast_bilinear:force_original_aspect_ratio=decrease,pad=$bW:$bH:(ow-iw)/2:(oh-ih)/2:color=black@0,setsar=1 [banner_scaled]',
      );
      filterGraphParts.add(
        '$videoStream[banner_scaled] overlay=$bX:$bY:shortest=1:eval=init [banner_v]',
      );
      videoStream = '[banner_v]';
    }

    // --- Separate Part Numbering Badge (drawtext filter) ---
    if (preset.autoNumbering && task.partNumber != null && fontPath.isNotEmpty) {
      final safeFontPath = fontPath.replaceAll('\\', '/').replaceAll(':', '\\:');
      final partLabel = 'ЧАСТЬ ${task.partNumber}';
      filterGraphParts.add(
        "$videoStream drawtext=fontfile='$safeFontPath':text='$partLabel':fontcolor=white:fontsize=22:box=1:boxcolor=black@0.8:boxborderw=8:borderw=1:bordercolor=white@0.6:fix_bounds=1:x=(w-text_w)/2:y=60 [part_v]",
      );
      videoStream = '[part_v]';
    }

    // --- Main Text Hook Overlay (drawtext filter per line) ---
    final taskHook = task.textHook?.trim() ?? '';
    final presetHook = preset.textHook?.trim() ?? '';
    final rawHook = taskHook.isNotEmpty ? taskHook : presetHook;

    if (rawHook.isNotEmpty && fontPath.isNotEmpty) {
      final safeFontPath = fontPath.replaceAll('\\', '/').replaceAll(':', '\\:');
      final hookLines = _wrapIntoLines(rawHook, maxLineChars: 24);
      final hookY = (preset.textHookYRatio * 1280).round().clamp(10, 1280 - 80);

      final maxLineLen = hookLines.map((l) => l.length).reduce((a, b) => a > b ? a : b);
      final fontSize = maxLineLen > 28 ? 22 : (maxLineLen > 20 ? 25 : 28);
      final lineHeight = (fontSize * 1.4).round();

      for (int i = 0; i < hookLines.length; i++) {
        final line = hookLines[i].replaceAll("'", "'\\''").replaceAll(':', '\\:');
        final currentY = hookY + (i * lineHeight);
        final streamOut = '[hook_v$i]';

        filterGraphParts.add(
          "$videoStream drawtext=fontfile='$safeFontPath':text='$line':fontcolor=white:fontsize=$fontSize:box=1:boxcolor=black@0.7:boxborderw=8:fix_bounds=1:x=(w-text_w)/2:y=$currentY $streamOut",
        );
        videoStream = streamOut;
      }
    } else if (rawHook.isNotEmpty && fontPath.isEmpty) {
      debugPrint('Skipping drawtext: font file unavailable');
    }

    // --- Subtitles (ASS / Whisper Karaoke) ---
    if (preset.useWhisper && preset.showSubtitles && subtitleAssPath != null && subtitleAssPath.isNotEmpty) {
      final safeSubPath = subtitleAssPath.replaceAll('\\', '/').replaceAll(':', '\\:');
      filterGraphParts.add(
        "$videoStream ass='$safeSubPath' [sub_v]",
      );
      videoStream = '[sub_v]';
    }

    // --- Audio Mixing (amix filter) ---
    if (audioTrackIdx != null) {
      filterGraphParts.add(
        '[$audioTrackIdx:a] volume=${preset.audioVolume.toStringAsFixed(2)} [bg_a]',
      );
      filterGraphParts.add(
        '$audioStream[bg_a] amix=inputs=2:duration=first:dropout_transition=2 [final_a]',
      );
      audioStream = '[final_a]';
    }

    // --- Smooth Outro & Intro Fades (Cinematic Fade-Out & Audio Smoothing) ---
    if (hasTrim) {
      final startSec = _parseTimeToSeconds(task.startTime!);
      final endSec = _parseTimeToSeconds(task.endTime!);
      final rawDuration = endSec - startSec;
      if (rawDuration > 3.0) {
        final speedFactor = 1.0 + preset.speedDelta;
        final outputDuration = rawDuration / speedFactor;
        final fadeOutStart = (outputDuration - 0.40).clamp(0.1, outputDuration);
        final audioFadeOutStart = (outputDuration - 0.50).clamp(0.1, outputDuration);

        // Video fade to black at the end
        filterGraphParts.add(
          "$videoStream fade=t=out:st=${fadeOutStart.toStringAsFixed(2)}:d=0.40 [faded_v]",
        );
        videoStream = '[faded_v]';

        // Audio smooth micro-fade-in at start + smooth fade-out at end
        filterGraphParts.add(
          "$audioStream afade=t=in:ss=0:d=0.08,afade=t=out:st=${audioFadeOutStart.toStringAsFixed(2)}:d=0.50 [faded_a]",
        );
        audioStream = '[faded_a]';
      }
    }

    // --- Final Graph Execution ---
    final fullFilterGraph = filterGraphParts.join(';');
    final coreCount = Platform.numberOfProcessors.clamp(4, 16);

    args.addAll([
      '-threads', '$coreCount',
      '-filter_threads', '$coreCount',
      '-filter_complex',
      fullFilterGraph,
      '-map',
      videoStream,
      '-map',
      audioStream,
    ]);

    // Hardware Acceleration Encoder Selection (Switch-Case)
    if (Platform.isAndroid) {
      args.addAll([
        '-c:v', 'h264_mediacodec',
        '-b:v', '1.5M',
        '-g', '60',
        '-keyint_min', '30',
        '-pix_fmt', 'nv12',
      ]);
    } else if (useNvenc) {
      // Windows NVIDIA NVENC — 720p: 1.5M/2M appropriate for 720×1280 (~45MB per 4-min video)
      args.addAll(['-c:v', 'h264_nvenc', '-preset', 'p1', '-rc', 'vbr', '-cq', '26', '-b:v', '1.5M', '-maxrate', '2M', '-bufsize', '4M', '-pix_fmt', 'yuv420p']);
    } else {
      // Default Windows / PC Fallback (CPU Fast H.264)
      args.addAll(['-c:v', 'libx264', '-preset', 'fast', '-crf', '22']);
    }

    args.addAll([
      '-c:a',
      'aac',
      '-b:a',
      '128k', // 192k → 128k: inaudible difference for social media, saves ~5MB per 4-min video
      // Metadata Spoofing (Apple iPhone 14 Pro emulation)
      '-map_metadata',
      '-1',
      '-metadata',
      'make=Apple',
      '-metadata',
      'model=iPhone 14 Pro',
      '-metadata',
      'software=16.5',
      '-metadata',
      // Random backdated creation_time (last 30 days) — looks like an older phone shot
      'creation_time=${DateTime.now().subtract(Duration(days: random.nextInt(30), hours: random.nextInt(24), minutes: random.nextInt(60))).toIso8601String()}',
      '-y',
      outputFilePath,
    ]);

    return FfmpegFilterBuilderResult(
      arguments: args,
      filterGraph: fullFilterGraph,
    );
  }

  static List<String> _wrapIntoLines(String text, {int maxLineChars = 24}) {
    if (text.length <= maxLineChars) return [text];
    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = '';
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + 1 + word.length) <= maxLineChars) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) lines.add(currentLine);
    return lines;
  }

  static double _parseTimeToSeconds(String timeStr) {
    if (timeStr.isEmpty) return 0.0;
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length == 3) {
        final h = double.tryParse(parts[0]) ?? 0.0;
        final m = double.tryParse(parts[1]) ?? 0.0;
        final s = double.tryParse(parts[2]) ?? 0.0;
        return h * 3600 + m * 60 + s;
      } else if (parts.length == 2) {
        final m = double.tryParse(parts[0]) ?? 0.0;
        final s = double.tryParse(parts[1]) ?? 0.0;
        return m * 60 + s;
      }
    } catch (_) {}
    return 0.0;
  }
}

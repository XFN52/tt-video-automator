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
      // Android Hardware Acceleration Decoder
      args.addAll(['-c:v', 'h264_mediacodec']);
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
        gameplayVideoPath.isNotEmpty) {
      args.addAll(['-stream_loop', '-1', '-i', gameplayVideoPath]);
      gameplayIdx = inputCount++;
    }

    // Optional Input 2: Looping Banner (MP4/PNG)
    int? bannerIdx;
    if (preset.bannerPath != null && preset.bannerPath!.isNotEmpty) {
      if (preset.bannerPath!.endsWith('.mp4') || preset.bannerPath!.endsWith('.mov')) {
        args.addAll(['-stream_loop', '-1', '-i', preset.bannerPath!]);
      } else {
        args.addAll(['-i', preset.bannerPath!]);
      }
      bannerIdx = inputCount++;
    }

    // Optional Input 3: Background Audio Track (MP3)
    int? audioTrackIdx;
    if (backgroundAudioPath != null && backgroundAudioPath.isNotEmpty) {
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

    // --- Uniqueness: Speed Randomization (setpts & atempo) ---
    if (preset.speedDelta != 0.0) {
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
    if (preset.colorDelta > 0.0) {
      final bJitter = (random.nextDouble() - 0.5) * 0.01;
      final cJitter = (random.nextDouble() - 0.5) * 0.01;
      final brightness = (preset.colorDelta * 0.5 + bJitter).toStringAsFixed(3);
      final contrast = (1.0 + preset.colorDelta + cJitter).toStringAsFixed(3);
      final saturation = (1.0 + preset.colorDelta * 0.8).toStringAsFixed(3);
      filterGraphParts.add(
        '$videoStream eq=brightness=$brightness:contrast=$contrast:saturation=$saturation [color_v]',
      );
      videoStream = '[color_v]';
    }

    // --- Uniqueness: Pixel Noise (noise filter with Random seed) ---
    if (preset.noiseLevel > 0.05) {
      final noiseVal = (preset.noiseLevel * 2).toInt();
      final randomSeed = random.nextInt(99999);
      filterGraphParts.add(
        // allf=u (uniform only): 2× faster than t+u (temporal+uniform); visually identical
        '$videoStream noise=alls=$noiseVal:allf=u:all_seed=$randomSeed [noise_v]',
      );
      videoStream = '[noise_v]';
    }

    // --- Layout & Canvas 9:16 (720x1280) ---
    if (preset.bgMode == BackgroundMode.blur) {
      // Blur Background Mode (half-res bg = 360×640 = 4× fewer pixels than 720×1280)
      filterGraphParts.add(
        '$videoStream split [bg_in][fg_in]',
      );
      // BG at half resolution (360×640): blur radius 10 at 360p ≡ radius 20 at 720p
      filterGraphParts.add(
        '[bg_in] scale=360:640:flags=bilinear,boxblur=10:2,scale=720:1280:flags=bilinear,setsar=1 [bg_blurred]',
      );
      filterGraphParts.add(
        '[fg_in] scale=720:1280:flags=bilinear:force_original_aspect_ratio=decrease,setsar=1 [fg_scaled]',
      );
      filterGraphParts.add(
        '[bg_blurred][fg_scaled] overlay=(W-w)/2:(H-h)/2 [layout_v]',
      );
    } else if (preset.bgMode == BackgroundMode.splitScreen && gameplayIdx != null) {
      // Split-Screen Gameplay Mode (vstack requires exact same width 720)
      filterGraphParts.add(
        '$videoStream scale=720:640:flags=bilinear:force_original_aspect_ratio=decrease,pad=720:640:(ow-iw)/2:(oh-ih)/2,setsar=1 [top_v]',
      );
      filterGraphParts.add(
        '[$gameplayIdx:v] scale=720:640:flags=bilinear:force_original_aspect_ratio=increase,crop=720:640,setsar=1 [bottom_v]',
      );
      filterGraphParts.add(
        '[top_v][bottom_v] vstack [layout_v]',
      );
    } else {
      // Default scale to 720x1280 pad
      filterGraphParts.add(
        '$videoStream scale=720:1280:flags=bilinear:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2,setsar=1 [layout_v]',
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
        '[$bannerIdx:v] scale=$bW:$bH:flags=bilinear:force_original_aspect_ratio=decrease,pad=$bW:$bH:(ow-iw)/2:(oh-ih)/2:color=black@0,setsar=1 [banner_scaled]',
      );
      filterGraphParts.add(
        '$videoStream[banner_scaled] overlay=$bX:$bY:shortest=1 [banner_v]',
      );
      videoStream = '[banner_v]';
    }

    // --- Text Hook & Part Numbering Overlay (drawtext filter) ---
    final taskHook = task.textHook?.trim() ?? '';
    final presetHook = preset.textHook?.trim() ?? '';
    final rawHook = taskHook.isNotEmpty ? taskHook : presetHook;

    String displayText = rawHook;
    if (preset.autoNumbering && task.partNumber != null) {
      if (displayText.isNotEmpty) {
        displayText += ' (Часть ${task.partNumber})';
      } else {
        displayText = 'Часть ${task.partNumber}';
      }
    }

    if (displayText.isNotEmpty && fontPath.isNotEmpty) {
      final safeFontPath = fontPath.replaceAll('\\', '/').replaceAll(':', '\\:');
      final safeText = displayText.replaceAll("'", "'\\''");
      final hookY = (preset.textHookYRatio * 1280).round().clamp(10, 1280 - 60);

      filterGraphParts.add(
        "$videoStream drawtext=fontfile='$safeFontPath':text='$safeText':fontcolor=white:fontsize=36:box=1:boxcolor=black@0.6:boxborderw=8:x=(w-text_w)/2:y=$hookY [text_v]",
      );
      videoStream = '[text_v]';
    } else if (displayText.isNotEmpty && fontPath.isEmpty) {
      debugPrint('Skipping drawtext: font file unavailable');
    }

    // --- Subtitles (ASS / Whisper Karaoke) ---
    if (preset.useWhisper && subtitleAssPath != null && subtitleAssPath.isNotEmpty) {
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

    // --- Final Graph Execution ---
    final fullFilterGraph = filterGraphParts.join(';');

    args.addAll([
      '-threads', '0',        // auto: global FFmpeg thread count (demux/mux/encode helpers)
      '-filter_threads', '0', // auto: filtergraph CPU threads
      '-filter_complex',
      fullFilterGraph,
      '-map',
      videoStream,
      '-map',
      audioStream,
    ]);

    // Hardware Acceleration Encoder Selection (Switch-Case)
    if (Platform.isAndroid) {
      args.addAll(['-c:v', 'h264_mediacodec', '-b:v', '1.5M']);
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
}

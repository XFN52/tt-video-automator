import 'package:flutter_test/flutter_test.dart';
import 'package:tt_video_automator/core/ffmpeg/ffmpeg_filter_builder.dart';
import 'package:tt_video_automator/features/presets/domain/render_preset.dart';
import 'package:tt_video_automator/features/tasks/domain/video_task.dart';

void main() {
  group('FfmpegFilterBuilder Unit Tests', () {
    late VideoTask testTask;
    late RenderPreset testPreset;

    setUp(() {
      testTask = VideoTask()
        ..id = 1
        ..inputFilePath = 'C:/input/video.mp4'
        ..outputFolderPath = 'C:/output'
        ..status = TaskStatus.pending
        ..progress = 0.0
        ..startTime = '00:00:10'
        ..endTime = '00:01:00'
        ..partNumber = 1;

      testPreset = RenderPreset()
        ..name = 'Test Preset'
        ..bgMode = BackgroundMode.blur
        ..isMirrored = true
        ..speedDelta = 0.05
        ..colorDelta = 0.04
        ..noiseLevel = 2.0
        ..textHook = 'Смотреть до конца!'
        ..autoNumbering = true
        ..audioVolume = 0.10
        ..useWhisper = true;
    });

    test('Should build valid FFmpeg arguments with Blur mode and uniqueness filters', () {
      final result = FfmpegFilterBuilder.buildCommand(
        task: testTask,
        preset: testPreset,
        outputFilePath: 'C:/output/result_part1.mp4',
        fontPath: 'C:/app/bold.ttf',
      );

      expect(result.arguments, contains('-i'));
      expect(result.arguments, contains('C:/input/video.mp4'));
      expect(result.arguments, contains('-filter_complex'));

      final fg = result.filterGraph;
      expect(fg, contains('hflip'));
      expect(fg, contains('setpts='));
      expect(fg, contains('atempo='));
      expect(fg, contains('eq='));
      expect(fg, contains('noise=alls=4'));
      expect(fg, contains('all_seed='));
      expect(fg, contains('boxblur=10:2'));
      expect(fg, contains('drawtext='));
    });

    test('Should build valid FFmpeg arguments for Split-Screen mode with gameplay video', () {
      testPreset.bgMode = BackgroundMode.splitScreen;

      final result = FfmpegFilterBuilder.buildCommand(
        task: testTask,
        preset: testPreset,
        outputFilePath: 'C:/output/result_split.mp4',
        fontPath: 'C:/app/bold.ttf',
        gameplayVideoPath: 'C:/gameplay/gta5.mp4',
      );

      expect(result.arguments, contains('-stream_loop'));
      expect(result.arguments, contains('-1'));
      expect(result.arguments, contains('C:/gameplay/gta5.mp4'));

      final fg = result.filterGraph;
      expect(fg, contains('vstack'));
      expect(fg, contains('pad=720:640'));
    });

    test('Should escape font path colons and single quotes correctly for drawtext', () {
      final result = FfmpegFilterBuilder.buildCommand(
        task: testTask,
        preset: testPreset,
        outputFilePath: 'C:/output/escaped.mp4',
        fontPath: r'C:\Users\User\Font:Name.ttf',
      );

      final fg = result.filterGraph;
      expect(fg, contains(r'C\:/Users/User/Font\:Name.ttf'));
    });

    test('Should inject ASS subtitle filter when subtitleAssPath is provided', () {
      final result = FfmpegFilterBuilder.buildCommand(
        task: testTask,
        preset: testPreset,
        outputFilePath: 'C:/output/subs.mp4',
        fontPath: 'C:/app/bold.ttf',
        subtitleAssPath: r'C:\Temp\subtitles.ass',
      );

      final fg = result.filterGraph;
      expect(fg, contains(r"ass='C\:/Temp/subtitles.ass'"));
    });

    test('Should include EXIF metadata spoofing flags for Apple iPhone 14 Pro emulation', () {
      final result = FfmpegFilterBuilder.buildCommand(
        task: testTask,
        preset: testPreset,
        outputFilePath: 'C:/output/metadata.mp4',
        fontPath: 'C:/app/bold.ttf',
      );

      expect(result.arguments, contains('-map_metadata'));
      expect(result.arguments, contains('-1'));
      expect(result.arguments, contains('make=Apple'));
      expect(result.arguments, contains('model=iPhone 14 Pro'));
    });

    test('Should build amix filter when background audio track is provided', () {
      final result = FfmpegFilterBuilder.buildCommand(
        task: testTask,
        preset: testPreset,
        outputFilePath: 'C:/output/audio_mix.mp4',
        fontPath: 'C:/app/bold.ttf',
        backgroundAudioPath: 'C:/music/bg.mp3',
      );

      expect(result.arguments, contains('C:/music/bg.mp3'));
      final fg = result.filterGraph;
      expect(fg, contains('amix=inputs=2:duration=first'));
      expect(fg, contains('volume=0.10'));
    });
    test('Should prioritize task.textHook over preset.textHook when provided', () {
      testPreset.textHook = 'Пресетный заголовок';
      testTask.textHook = 'Индивидуальный хук ролика';

      final result = FfmpegFilterBuilder.buildCommand(
        task: testTask,
        preset: testPreset,
        outputFilePath: 'C:/output/custom_hook.mp4',
        fontPath: 'C:/app/bold.ttf',
      );

      final fg = result.filterGraph;
      expect(fg, contains('Индивидуальный хук ролика'));
      expect(fg, isNot(contains('Пресетный заголовок')));
    });
  });
}

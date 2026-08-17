import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../presets/domain/render_preset.dart';
import '../domain/subtitle_token.dart';

class AssFileWriter {
  /// Экранирует слово под libass-семантику Dialogue-строки: `\` перед любыми
  /// фигурными скобками, переносы строк заменяются пробелом.
  static String _escapeAssText(String word) {
    final buffer = StringBuffer();
    for (final codeUnit in word.codeUnits) {
      final ch = String.fromCharCode(codeUnit);
      if (ch == '\\' || ch == '{' || ch == '}') {
        buffer.write('\\');
      }
      if (ch == '\n' || ch == '\r') {
        buffer.write(' ');
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  /// Generates an Advanced SubStation Alpha (.ass) subtitle file with TikTok-style Karaoke highlighting.
  /// Returns output path of created .ass file.
  static Future<String> generateAssFile({
    required List<SubtitleToken> tokens,
    required String outputPath,
    SubtitlePosition position = SubtitlePosition.bottom,
    double? yRatio,
    double speedFactor = 1.0,
  }) async {
    final buffer = StringBuffer();

    // 1. ASS Script Info Header
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: TikTok Karaoke Subtitles');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('WrapStyle: 0');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln('PlayResX: 720');
    buffer.writeln('PlayResY: 1280');
    buffer.writeln();

    // 2. V4+ Styles Header (TikTok Yellow & White Karaoke font)
    buffer.writeln('[V4+ Styles]');
    buffer.writeln(
      'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding',
    );

    int alignmentVal;
    int marginVVal;
    if (yRatio != null) {
      alignmentVal = 2;
      marginVVal = ((1.0 - yRatio.clamp(0.05, 0.95)) * 1280).round().clamp(10, 1200);
    } else {
      switch (position) {
        case SubtitlePosition.top:
          alignmentVal = 8;
          marginVVal = 187;
          break;
        case SubtitlePosition.center:
          alignmentVal = 5;
          marginVVal = 0;
          break;
        case SubtitlePosition.bottom:
          alignmentVal = 2;
          marginVVal = 187;
          break;
      }
    }

    // MarginL/R 27 (40×720/1080), Shadow=0 (no expensive double-render), Outline=2
    buffer.writeln(
      'Style: Karaoke,Arial,48,&H0000FFFF,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,2,0,$alignmentVal,27,27,$marginVVal,1',
    );
    buffer.writeln();

    // 3. Events Header & Dialogue lines with {\k} Karaoke tags
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    final effectiveTokens = (speedFactor > 0.0 && (speedFactor - 1.0).abs() > 0.0001)
        ? tokens.map((t) {
            return SubtitleToken(
              word: t.word,
              startMs: (t.startMs / speedFactor).round(),
              endMs: (t.endMs / speedFactor).round(),
            );
          }).toList()
        : tokens;

    if (effectiveTokens.isNotEmpty) {
      // Group tokens into lines of up to 4 words for optimal TikTok readability
      const wordsPerLine = 4;
      for (int i = 0; i < effectiveTokens.length; i += wordsPerLine) {
        final chunk = effectiveTokens.sublist(
          i,
          (i + wordsPerLine > effectiveTokens.length)
              ? effectiveTokens.length
              : i + wordsPerLine,
        );

        final lineStart = chunk.first.formattedStart;
        final lineEnd = chunk.last.formattedEnd;

        final lineTextBuffer = StringBuffer();
        for (final token in chunk) {
          final centisec = token.durationCentiseconds;
          final word = _escapeAssText(token.word);
          lineTextBuffer.write('{\\k$centisec}$word ');
        }

        buffer.writeln(
          'Dialogue: 0,$lineStart,$lineEnd,Karaoke,,0,0,0,,${lineTextBuffer.toString().trim()}',
        );
      }
    }

    final file = File(outputPath);
    await file.writeAsString(buffer.toString());
    debugPrint('Generated ASS Karaoke Subtitle file: $outputPath');

    return outputPath;
  }
}

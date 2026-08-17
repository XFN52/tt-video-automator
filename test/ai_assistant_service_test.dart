import 'package:flutter_test/flutter_test.dart';
import 'package:tt_video_automator/features/ai_assistant/data/ai_assistant_service.dart';
import 'package:tt_video_automator/features/ai_assistant/domain/ai_cut_segment.dart';
import 'package:tt_video_automator/features/subtitles/domain/subtitle_token.dart';

void main() {
  group('AiAssistant Domain & Parsing Tests', () {
    test('AiCutSegment.fromJson should parse standard JSON correctly', () {
      final json = {
        'part_number': 1,
        'start_time': '00:00:10',
        'end_time': '00:01:05',
        'hook': 'ОН НАШЕЛ ЭТО В ЛЕСУ',
        'summary': 'Завязка истории',
      };

      final segment = AiCutSegment.fromJson(json, 1);
      expect(segment.partNumber, 1);
      expect(segment.startTime, '00:00:10');
      expect(segment.endTime, '00:01:05');
      expect(segment.hook, 'ОН НАШЕЛ ЭТО В ЛЕСУ');
      expect(segment.summary, 'Завязка истории');
    });

    test('AiCutSegment.fromJson should handle camelCase and fallback fields', () {
      final json = {
        'startTime': '00:01:05',
        'endTime': '00:02:15',
        'title': 'КУЛЬМИНАЦИЯ',
        'description': 'Развязка',
      };

      final segment = AiCutSegment.fromJson(json, 2);
      expect(segment.partNumber, 2);
      expect(segment.startTime, '00:01:05');
      expect(segment.endTime, '00:02:15');
      expect(segment.hook, 'КУЛЬМИНАЦИЯ');
      expect(segment.summary, 'Развязка');
    });

    test('AiCutSegment.toJson should produce clean map', () {
      const segment = AiCutSegment(
        startTime: '00:00:00',
        endTime: '00:00:45',
        partNumber: 1,
        hook: 'ТАЙНА 1998 ГОДА',
      );

      final map = segment.toJson();
      expect(map['part_number'], 1);
      expect(map['start_time'], '00:00:00');
      expect(map['end_time'], '00:00:45');
      expect(map['hook'], 'ТАЙНА 1998 ГОДА');
    });
    test('SpeechPhrase.groupTokensIntoPhrases should group by punctuation and pauses', () {
      final tokens = [
        SubtitleToken(word: 'Вы', startMs: 0, endMs: 400),
        SubtitleToken(word: 'когда-нибудь', startMs: 450, endMs: 1200),
        SubtitleToken(word: 'думали?', startMs: 1250, endMs: 1900),
        SubtitleToken(word: 'Это', startMs: 3000, endMs: 3400),
        SubtitleToken(word: 'важно.', startMs: 3450, endMs: 4000),
      ];

      final phrases = AiAssistantService.groupTokensIntoPhrases(tokens);
      expect(phrases.length, 2);
      expect(phrases[0].text, 'Вы когда-нибудь думали?');
      expect(phrases[0].startTimeFormatted, '00:00:00.000');
      expect(phrases[0].endTimeFormatted, '00:00:01.900');
      expect(phrases[1].text, 'Это важно.');
      expect(phrases[1].startTimeFormatted, '00:00:03.000');
      expect(phrases[1].endTimeFormatted, '00:00:04.000');
    });
  });
}

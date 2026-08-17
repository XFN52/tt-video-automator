import 'package:flutter_test/flutter_test.dart';
import 'package:tt_video_automator/features/ai_assistant/domain/ai_cut_segment.dart';

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
  });
}

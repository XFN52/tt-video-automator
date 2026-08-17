import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/app_settings_service.dart';
import '../../subtitles/domain/subtitle_token.dart';
import '../domain/ai_cut_segment.dart';

class AiAssistantService {
  static AiAssistantService? _instance;
  static AiAssistantService get instance => _instance ??= AiAssistantService._();

  AiAssistantService._();

  String get apiKey =>
      AppSettingsService.instance.getString(AppSettingsService.keyAiApiKey) ?? '';

  String get baseUrl {
    final url =
        AppSettingsService.instance.getString(AppSettingsService.keyAiBaseUrl);
    if (url != null && url.trim().isNotEmpty) {
      var clean = url.trim().replaceAll(RegExp(r'/+$'), '');
      if (clean.endsWith('/chat/completions')) {
        clean = clean.substring(0, clean.length - '/chat/completions'.length);
      }
      return clean.replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://api.deepseek.com/v1';
  }

  String get model {
    final m =
        AppSettingsService.instance.getString(AppSettingsService.keyAiModel);
    if (m != null && m.trim().isNotEmpty) {
      return m.trim();
    }
    return 'deepseek-chat';
  }

  bool get isConfigured {
    // Для локальной Ollama API ключ не обязателен
    if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
      return true;
    }
    return apiKey.trim().isNotEmpty;
  }

  bool get isAutoHooksEnabled => AppSettingsService.instance.getBool(
        AppSettingsService.keyAiAutoGenerateHooks,
        defaultValue: true,
      );

  bool get isAutoPostsEnabled => AppSettingsService.instance.getBool(
        AppSettingsService.keyAiAutoGeneratePosts,
        defaultValue: true,
      );

  /// Отправляет запрос к OpenAI-совместимому API chat/completions
  Future<(String? content, String? error)> _chatCompletionDetailed({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    if (!isConfigured) {
      return (null, 'API ключ или Base URL не настроены');
    }

    final endpoint = Uri.parse('$baseUrl/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    try {
      debugPrint('AiAssistantService: Sending request to $endpoint ($model)...');
      final response = await http
          .post(endpoint, headers: headers, body: body)
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = decoded['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices.first['message']?['content'] as String?;
          return (content?.trim(), null);
        }
        return (null, 'Сервер вернул пустой список choices');
      } else {
        final errorBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        debugPrint(
          'AiAssistantService HTTP Error ${response.statusCode}: $errorBody',
        );
        return (null, 'HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      debugPrint('AiAssistantService Exception: $e');
      return (null, 'Ошибка сети: $e');
    }
  }

  Future<String?> _chatCompletion({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
  }) async {
    final (content, _) = await _chatCompletionDetailed(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    return content;
  }

  /// Проверка подключения к AI API
  Future<(bool, String)> testConnection() async {
    if (!isConfigured) {
      return (false, 'API ключ не заполнен');
    }

    try {
      final (res, err) = await _chatCompletionDetailed(
        systemPrompt: 'Ответь одним словом "OK"',
        userPrompt: 'Тест связи',
        maxTokens: 10,
      );
      if (res != null && res.isNotEmpty) {
        return (true, 'Связь установлена! Модель ответила: $res');
      }
      return (false, err ?? 'Сервер не вернул ответ');
    } catch (e) {
      return (false, 'Ошибка: $e');
    }
  }

  /// Генерация одного вирусного кликбейтного хука (3-6 слов)
  Future<String?> generateHook({
    required String transcript,
    String? videoTitle,
  }) async {
    if (transcript.trim().isEmpty) return null;

    const systemPrompt = '''
Ты — ведущий креативный продюсер вирусных коротких видео (TikTok, Reels, Shorts).
На основе расшифровки речи из видео придумай ОДИН мощный, интригующий, кликбейтный заголовок-хук на русском языке для верхней плашки ролика.
Требования:
- Ровно 3-6 слов.
- Вызывает моментальное любопытство и желание досмотреть.
- Без кавычек, без смайлов в начале, без знаков препинания в конце.
- Пиши только сам заголовок, никаких пояснений.''';

    final userPrompt = '''
Название видео: ${videoTitle ?? 'Без названия'}
Текст речи из видео:
"""
$transcript
"""''';

    final result = await _chatCompletion(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.8,
      maxTokens: 50,
    );

    if (result != null && result.isNotEmpty) {
      // Очистка от кавычек и префиксов
      return result
          .replaceAll(RegExp(r'^["«]+|["»]+$'), '')
          .replaceAll(RegExp(r'^(Заголовок|Хук|Hook):\s*', caseSensitive: false), '')
          .trim();
    }
    return null;
  }

  /// Генерация текста поста (описание, призыв к действию, хэштеги)
  Future<String?> generatePostDescription({
    required String transcript,
    int? partNumber,
    String? videoTitle,
  }) async {
    if (transcript.trim().isEmpty) return null;

    final partInfo = partNumber != null ? ' (Часть $partNumber)' : '';
    const systemPrompt = '''
Ты — SMM-продюсер вирусных каналов в TikTok, Instagram Reels и YouTube Shorts.
Создай идеальный текст поста для публикации видео.
Структура:
1. Интригующее краткое описание (1-2 цепляющих предложения).
2. Призыв к действию (подпишись, поставь лайк, поделись мнением).
3. Блок из 6-10 трендовых целевых хэштегов (например, #истории #факты #рекомендации #fyp #рек).
Формат: чистый готовый текст на русском языке.''';

    final userPrompt = '''
Название: ${videoTitle ?? 'Видео'}$partInfo
Текст речи из видео:
"""
$transcript
"""''';

    return await _chatCompletion(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.7,
      maxTokens: 350,
    );
  }

  /// Умная авто-нарезка длинного видео на смысловые серии с точной привязкой к границам предложений
  Future<List<AiCutSegment>> splitVideoIntoSegments({
    required List<SubtitleToken> tokens,
    required double totalDurationSeconds,
    int targetDurationSec = 50,
  }) async {
    if (tokens.isEmpty || totalDurationSeconds <= 35) {
      return [];
    }

    final phrases = groupTokensIntoPhrases(tokens);
    if (phrases.isEmpty) return [];

    // Составляем четкий структурированный таймлайн законченных фраз/предложений
    final buffer = StringBuffer();
    for (final p in phrases) {
      buffer.writeln('[${p.startTimeFormatted} - ${p.endTimeFormatted}] ${p.text}');
    }

    const systemPrompt = '''
Ты — профессиональный видеомонтажер и сценарист вирусных TikTok/Shorts/Reels сериалов.
Твоя задача — разделить длинный транскрипт видео на логические серии/части.

СТРОЖАЙШИЕ ПРАВИЛА НАРЕЗКИ:
1. Каждая серия ОБЯЗАНА начинаться СТРОГО в начале фразы (start_time) и заканчиваться СТРОГО в конце законченной фразы или предложения (end_time).
2. СТРОГО ЗАПРЕЩЕНО обрывать речь на полуслове или посреди незаконченного предложения!
3. Каждая часть должна длиться примерно от 35 до 75 секунд (иметь законченную мысль или цепляющий клиффхэнгер).
4. Заголовок (hook) для каждой части: ровно 3-5 слов, интригующий и кликбейтный, без кавычек и точек.
5. Для таймкодов используй точные значения из списка фраз.

ВЕРНИ ТОЛЬКО ЧИСТЫЙ СТРОГИЙ JSON-МАССИВ БЕЗ ЛИШНЕГО ТЕКСТА И БЕЗ MARKDOWN РАЗМЕТКИ!
Пример формата:
[
  {
    "part_number": 1,
    "start_time": "00:00:00",
    "end_time": "00:00:52",
    "hook": "ТАЙНА КАТАСТРОФЫ 1998",
    "summary": "Введение в сюжет и завязка"
  },
  {
    "part_number": 2,
    "start_time": "00:00:52",
    "end_time": "00:01:45",
    "hook": "ОН НАШЕЛ ЭТО В ЛЕСУ",
    "summary": "Кульминация находки"
  }
]''';

    final totalDurationMs = (totalDurationSeconds * 1000).round();
    final totalFormatted = SpeechPhrase._formatMsToTime(totalDurationMs);

    final userPrompt = '''
Общая длительность видео: $totalFormatted (~${totalDurationSeconds.round()} сек).
Целевой хронометраж одной серии: ~$targetDurationSec сек.
Таймлайн предложений:
"""
${buffer.toString()}
"""''';

    final rawJson = await _chatCompletion(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.4,
      maxTokens: 1500,
    );

    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      // Очищаем от возможных markdown обрамлений ```json ... ```
      String cleanJson = rawJson.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?\n?'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'```$'), '');
      }
      cleanJson = cleanJson.trim();

      final decoded = jsonDecode(cleanJson);
      if (decoded is List) {
        final segments = <AiCutSegment>[];
        String lastEndTime = '00:00:00';

        for (int i = 0; i < decoded.length; i++) {
          final item = decoded[i];
          if (item is Map<String, dynamic>) {
            final rawStart = item['start_time'] ?? item['startTime'] ?? '';
            final rawEnd = item['end_time'] ?? item['endTime'] ?? '';
            final rawHook = item['hook'] ?? item['title'] ?? 'Часть ${i + 1}';
            final summary = item['summary'] ?? item['description'] ?? '';

            final startMs = _parseTimeToMs(rawStart.toString());
            final endMs = _parseTimeToMs(rawEnd.toString());

            // Точная привязка границ к паузам/предложениям речи
            final snappedStart = i == 0
                ? '00:00:00'
                : (lastEndTime.isNotEmpty
                    ? lastEndTime
                    : _snapToNearestPhraseStart(startMs, phrases));
            final snappedEnd = (i == decoded.length - 1)
                ? SpeechPhrase._formatMsToTime(totalDurationMs)
                : _snapToNearestPhraseEnd(endMs, phrases, totalDurationMs);

            lastEndTime = snappedEnd;

            final cleanHook = rawHook
                .toString()
                .replaceAll(RegExp(r'^["«]+|["»]+$'), '')
                .replaceAll(RegExp(r'^(Заголовок|Хук|Hook):\s*', caseSensitive: false), '')
                .trim();

            segments.add(
              AiCutSegment(
                startTime: snappedStart,
                endTime: snappedEnd,
                partNumber: i + 1,
                hook: cleanHook,
                summary: summary.toString().trim(),
              ),
            );
          }
        }
        return segments;
      }
    } catch (e) {
      debugPrint('AiAssistantService JSON parsing error: $e\nRaw: $rawJson');
    }

    return [];
  }

  /// Группирует слова в законченные фразы и предложения с точными таймкодами
  static List<SpeechPhrase> groupTokensIntoPhrases(List<SubtitleToken> tokens) {
    if (tokens.isEmpty) return [];

    final phrases = <SpeechPhrase>[];
    var currentWords = <String>[];
    int phraseStartMs = tokens.first.startMs;
    int phraseEndMs = tokens.first.endMs;

    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      currentWords.add(t.word);
      phraseEndMs = t.endMs;

      final isLast = i == tokens.length - 1;
      final word = t.word.trim();
      final hasSentencePunctuation = word.endsWith('.') ||
          word.endsWith('!') ||
          word.endsWith('?') ||
          word.endsWith(';') ||
          word.endsWith('...');

      final hasNaturalPause =
          !isLast && (tokens[i + 1].startMs - t.endMs >= 400);
      final isLongPhrase = currentWords.length >= 14 &&
          (word.endsWith(',') || hasNaturalPause);

      if (isLast || hasSentencePunctuation || hasNaturalPause || isLongPhrase) {
        phrases.add(
          SpeechPhrase(
            startMs: phraseStartMs,
            endMs: phraseEndMs,
            text: currentWords.join(' ').trim(),
          ),
        );
        currentWords = [];
        if (!isLast) {
          phraseStartMs = tokens[i + 1].startMs;
        }
      }
    }

    return phrases;
  }

  static int _parseTimeToMs(String timeStr) {
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

  static String _snapToNearestPhraseStart(
    int targetMs,
    List<SpeechPhrase> phrases,
  ) {
    if (phrases.isEmpty) return SpeechPhrase._formatMsToTime(targetMs);
    if (targetMs <= 1000) return '00:00:00';

    SpeechPhrase closest = phrases.first;
    int minDiff = (phrases.first.startMs - targetMs).abs();

    for (final p in phrases) {
      final diff = (p.startMs - targetMs).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = p;
      }
    }

    // Если разница в пределах 7 секунд — привязываемся к началу фразы
    if (minDiff <= 7000) {
      return closest.startTimeFormatted;
    }
    return SpeechPhrase._formatMsToTime(targetMs);
  }

  static String _snapToNearestPhraseEnd(
    int targetMs,
    List<SpeechPhrase> phrases,
    int totalDurationMs,
  ) {
    if (phrases.isEmpty) return SpeechPhrase._formatMsToTime(targetMs);
    if ((targetMs - totalDurationMs).abs() <= 1500) {
      return SpeechPhrase._formatMsToTime(totalDurationMs);
    }

    SpeechPhrase closest = phrases.first;
    int minDiff = (phrases.first.endMs - targetMs).abs();

    for (final p in phrases) {
      final diff = (p.endMs - targetMs).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = p;
      }
    }

    // Если разница в пределах 7 секунд — привязываемся к концу фразы
    if (minDiff <= 7000) {
      return closest.endTimeFormatted;
    }
    return SpeechPhrase._formatMsToTime(targetMs);
  }
}

class SpeechPhrase {
  final int startMs;
  final int endMs;
  final String text;

  const SpeechPhrase({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  String get startTimeFormatted => _formatMsToTime(startMs);
  String get endTimeFormatted => _formatMsToTime(endMs);

  static String _formatMsToTime(int ms) {
    final safeMs = ms.clamp(0, 86400000);
    final hours = safeMs ~/ 3600000;
    final minutes = (safeMs % 3600000) ~/ 60000;
    final seconds = (safeMs % 60000) ~/ 1000;
    final h = hours.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

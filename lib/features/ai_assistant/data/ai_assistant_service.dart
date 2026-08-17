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

  /// Отправляет запрос к OpenAI-совместимому API chat/completions с автоматическими ретраями при 503/429
  Future<(String? content, String? error)> _chatCompletionDetailed({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 1000,
    int maxRetries = 3,
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

    String? lastError;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
          'AiAssistantService: Sending request to $endpoint ($model) [Попытка $attempt/$maxRetries]...',
        );
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
          lastError = 'HTTP ${response.statusCode}: $errorBody';
          debugPrint(
            'AiAssistantService HTTP Error ${response.statusCode} (попытка $attempt): $errorBody',
          );

          final isTransient = response.statusCode == 503 ||
              response.statusCode == 502 ||
              response.statusCode == 504 ||
              response.statusCode == 429;
          if (isTransient && attempt < maxRetries) {
            final delaySec = attempt * 2;
            debugPrint('AiAssistantService: Сервер временно занят (503/429). Повтор через $delaySec сек...');
            await Future.delayed(Duration(seconds: delaySec));
            continue;
          }
          return (null, lastError);
        }
      } catch (e) {
        lastError = 'Ошибка сети: $e';
        debugPrint('AiAssistantService Exception (попытка $attempt): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        return (null, lastError);
      }
    }
    return (null, lastError ?? 'Не удалось получить ответ от ИИ');
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

  /// Умная авто-нарезка длинного видео на смысловые серии на основе диапазонов предложений с миллисекундной точностью
  Future<List<AiCutSegment>> splitVideoIntoSegments({
    required List<SubtitleToken> tokens,
    required double totalDurationSeconds,
    int targetDurationSec = 50,
  }) async {
    if (tokens.isEmpty || totalDurationSeconds <= 30) {
      return [];
    }

    final phrases = groupTokensIntoPhrases(tokens);
    if (phrases.isEmpty) return [];

    // Составляем пронумерованный список фраз с длительностью
    final buffer = StringBuffer();
    for (int i = 0; i < phrases.length; i++) {
      final p = phrases[i];
      final dur = p.durationSec;
      buffer.writeln('#${i + 1} [${p.startTimeFormatted} - ${p.endTimeFormatted}] ($dur сек): "${p.text}"');
    }

    const systemPrompt = '''
Ты — профессиональный видеомонтажер и сценарист вирусных TikTok/Shorts/Reels сериалов.
Твоя задача — объединить пронумерованные фразы длинного видео в логические серии/части.

СТРОГИЕ ПРАВИЛА:
1. Каждая серия объединяет диапазон фраз от start_phrase до end_phrase (номера с решеткой #).
2. Серии идут строго подряд без пропусков (серия 2 начинается со следующей фразы после серии 1).
3. Длительность одной серии должна быть примерно от 35 до 75 секунд (суммируй секунды фраз).
4. Каждая серия должна заканчиваться на сильной смысловой точке или клиффхэнгере.
5. Для каждой части придумай мощный вирусный заголовок-хук (3-5 слов, без кавычек и точек).

ВЕРНИ ТОЛЬКО ЧИСТЫЙ СТРОГИЙ JSON-МАССИВ БЕЗ MARKDOWN:
[
  {
    "part_number": 1,
    "start_phrase": 1,
    "end_phrase": 7,
    "hook": "ТАЙНА КАТАСТРОФЫ 1998",
    "summary": "Завязка истории"
  },
  {
    "part_number": 2,
    "start_phrase": 8,
    "end_phrase": 15,
    "hook": "ОН НАШЕЛ ЭТО В ЛЕСУ",
    "summary": "Кульминация находки"
  }
]''';

    final totalDurationMs = (totalDurationSeconds * 1000).round();
    final totalFormatted = SpeechPhrase._formatMsToTime(totalDurationMs);

    final userPrompt = '''
Всего фраз в видео: ${phrases.length} шт. Общая длительность: $totalFormatted (~${totalDurationSeconds.round()} сек).
Целевой хронометраж одной серии: ~$targetDurationSec сек.

Список предложений:
"""
${buffer.toString()}
"""''';

    final rawJson = await _chatCompletion(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.3,
      maxTokens: 1500,
    );

    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      String cleanJson = rawJson.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?\n?'), '');
        cleanJson = cleanJson.replaceAll(RegExp(r'```$'), '');
      }
      cleanJson = cleanJson.trim();

      final decoded = jsonDecode(cleanJson);
      if (decoded is List) {
        final segments = <AiCutSegment>[];
        int previousEndMs = 0;

        for (int i = 0; i < decoded.length; i++) {
          final item = decoded[i];
          if (item is Map<String, dynamic>) {
            final rawHook = item['hook'] ?? item['title'] ?? 'Часть ${i + 1}';
            final summary = item['summary'] ?? item['description'] ?? '';

            int startMs;
            int endMs;

            // Если модель указала номера фраз (start_phrase / end_phrase)
            if (item.containsKey('start_phrase') || item.containsKey('startPhrase')) {
              final sp = (item['start_phrase'] ?? item['startPhrase'] as num?)?.toInt() ?? 1;
              final ep = (item['end_phrase'] ?? item['endPhrase'] as num?)?.toInt() ?? sp;

              final startIdx = (sp - 1).clamp(0, phrases.length - 1);
              final endIdx = (ep - 1).clamp(startIdx, phrases.length - 1);

              final rawStartMs = phrases[startIdx].startMs;
              final rawEndMs = phrases[endIdx].endMs;

              // Буфер 80мс для плавности начала/конца
              startMs = i == 0 ? 0 : (rawStartMs - 80).clamp(previousEndMs, totalDurationMs);
              endMs = (i == decoded.length - 1)
                  ? totalDurationMs
                  : (rawEndMs + 100).clamp(startMs + 5000, totalDurationMs);
            } else {
              // Fallback: если модель вернула таймкоды строками
              final rawStart = item['start_time'] ?? item['startTime'] ?? '';
              final rawEnd = item['end_time'] ?? item['endTime'] ?? '';

              final parsedStart = _parseTimeToMs(rawStart.toString());
              final parsedEnd = _parseTimeToMs(rawEnd.toString());

              startMs = i == 0 ? 0 : _snapToNearestPhraseStartMs(parsedStart, phrases, previousEndMs);
              endMs = (i == decoded.length - 1)
                  ? totalDurationMs
                  : _snapToNearestPhraseEndMs(parsedEnd, phrases, totalDurationMs);
            }

            previousEndMs = endMs;

            final cleanHook = rawHook
                .toString()
                .replaceAll(RegExp(r'^["«]+|["»]+$'), '')
                .replaceAll(RegExp(r'^(Заголовок|Хук|Hook):\s*', caseSensitive: false), '')
                .trim();

            segments.add(
              AiCutSegment(
                startTime: SpeechPhrase._formatMsToTime(startMs),
                endTime: SpeechPhrase._formatMsToTime(endMs),
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
          !isLast && (tokens[i + 1].startMs - t.endMs >= 350);
      final isLongPhrase = currentWords.length >= 12 &&
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

  static int _snapToNearestPhraseStartMs(
    int targetMs,
    List<SpeechPhrase> phrases,
    int minStartMs,
  ) {
    if (phrases.isEmpty) return targetMs.clamp(minStartMs, 86400000);
    if (targetMs <= 1000) return 0;

    SpeechPhrase closest = phrases.first;
    int minDiff = (phrases.first.startMs - targetMs).abs();

    for (final p in phrases) {
      final diff = (p.startMs - targetMs).abs();
      if (diff < minDiff && p.startMs >= minStartMs) {
        minDiff = diff;
        closest = p;
      }
    }

    return (closest.startMs - 60).clamp(minStartMs, 86400000);
  }

  static int _snapToNearestPhraseEndMs(
    int targetMs,
    List<SpeechPhrase> phrases,
    int totalDurationMs,
  ) {
    if (phrases.isEmpty) return targetMs.clamp(0, totalDurationMs);
    if ((targetMs - totalDurationMs).abs() <= 1500) {
      return totalDurationMs;
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

    return (closest.endMs + 100).clamp(0, totalDurationMs);
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

  int get durationSec => ((endMs - startMs) / 1000).round();

  String get startTimeFormatted => _formatMsToTime(startMs);
  String get endTimeFormatted => _formatMsToTime(endMs);

  static String _formatMsToTime(int ms) {
    final safeMs = ms.clamp(0, 86400000);
    final hours = safeMs ~/ 3600000;
    final minutes = (safeMs % 3600000) ~/ 60000;
    final seconds = (safeMs % 60000) ~/ 1000;
    final millis = safeMs % 1000;
    final h = hours.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    final msStr = millis.toString().padLeft(3, '0');
    return '$h:$m:$s.$msStr';
  }
}

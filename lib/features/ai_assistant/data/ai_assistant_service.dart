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

  /// Умная авто-нарезка длинного видео на смысловые серии с таймкодами
  Future<List<AiCutSegment>> splitVideoIntoSegments({
    required List<SubtitleToken> tokens,
    required double totalDurationSeconds,
    int targetDurationSec = 50,
  }) async {
    if (tokens.isEmpty || totalDurationSeconds <= 40) {
      return [];
    }

    // Составляем компактный таймлайн текста с шагом ~10-15 секунд
    final buffer = StringBuffer();
    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (i == 0 || (t.startMs % 10000 < 500)) {
        final sec = (t.startMs / 1000).round();
        final mm = (sec ~/ 60).toString().padLeft(2, '0');
        final ss = (sec % 60).toString().padLeft(2, '0');
        buffer.write('\n[$mm:$ss] ');
      }
      buffer.write('${t.word} ');
    }

    const systemPrompt = '''
Ты — профессиональный видеомонтажер и продюсер TikTok-сериалов.
Твоя задача — разбить транскрипт длинного видео на логические серии/части.
Каждая часть должна:
- Длиться примерно от 35 до 75 секунд.
- Иметь законченную смысловую мысль или обрываться на интригующем моменте (клиффхэнгер).
- Содержать start_time и end_time в формате HH:MM:SS (или MM:SS).
- Содержать цепляющий заголовок (hook) для этой части.

ВЕРНИ ТОЛЬКО СТРОГИЙ JSON-МАССИВ БЕЗ КАКИХ-ЛИБО ДРУГИХ СЛОВ И БЕЗ MARKDOWN РАЗМЕТКИ!
Пример формата:
[
  {
    "part_number": 1,
    "start_time": "00:00:00",
    "end_time": "00:00:48",
    "hook": "НАЧАЛО СТРАННОЙ ИСТОРИИ",
    "summary": "Введение в сюжет и завязка"
  },
  {
    "part_number": 2,
    "start_time": "00:00:48",
    "end_time": "00:01:35",
    "hook": "ОН НАШЕЛ ЭТО В ЛЕСУ",
    "summary": "Кульминация находки"
  }
]''';

    final totalSec = totalDurationSeconds.round();
    final totalMm = (totalSec ~/ 60).toString().padLeft(2, '0');
    final totalSs = (totalSec % 60).toString().padLeft(2, '0');

    final userPrompt = '''
Общая длительность видео: 00:$totalMm:$totalSs (~$totalSec сек).
Целевой хронометраж одной серии: ~$targetDurationSec сек.
Таймлайн речи:
"""
${buffer.toString()}
"""''';

    final rawJson = await _chatCompletion(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.5,
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
        for (int i = 0; i < decoded.length; i++) {
          final item = decoded[i];
          if (item is Map<String, dynamic>) {
            segments.add(AiCutSegment.fromJson(item, i + 1));
          }
        }
        return segments;
      }
    } catch (e) {
      debugPrint('AiAssistantService JSON parsing error: $e\nRaw: $rawJson');
    }

    return [];
  }
}

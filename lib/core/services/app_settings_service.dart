import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Сервис сохранения пользовательских настроек и последних использованных путей (Output, Videos, Audio, Banner, Gameplay).
class AppSettingsService {
  static AppSettingsService? _instance;
  static AppSettingsService get instance => _instance ??= AppSettingsService._();

  AppSettingsService._();

  final Map<String, dynamic> _cache = {};
  File? _file;
  bool _initialized = false;

  static const String keyLastOutputDirectory = 'lastOutputDirectory';
  static const String keyLastInputVideoDirectory = 'lastInputVideoDirectory';
  static const String keyLastAudioDirectory = 'lastAudioDirectory';
  static const String keyLastBannerDirectory = 'lastBannerDirectory';
  static const String keyLastGameplayDirectory = 'lastGameplayDirectory';
  static const String keyLastSelectedPresetId = 'lastSelectedPresetId';

  Future<void> init() async {
    if (_initialized) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _file = File('${docDir.path}/app_settings.json');
      if (await _file!.exists()) {
        final content = await _file!.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            _cache.addAll(decoded);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading app_settings.json: $e');
    }
    _initialized = true;
  }

  String? getString(String key) => _cache[key] as String?;

  int? getInt(String key) => _cache[key] as int?;

  /// Возвращает путь к директории, только если она реально существует на диске.
  String? getExistingDirectory(String key) {
    final path = getString(key);
    if (path != null && path.isNotEmpty && Directory(path).existsSync()) {
      return path;
    }
    return null;
  }

  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    await _save();
  }

  Future<void> setInt(String key, int value) async {
    _cache[key] = value;
    await _save();
  }

  /// Запоминает родительскую директорию для переданного файла.
  Future<void> rememberParentDirectoryForFile(String key, String filePath) async {
    if (filePath.isEmpty) return;
    try {
      final parent = File(filePath).parent.path;
      if (parent.isNotEmpty && Directory(parent).existsSync()) {
        await setString(key, parent);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      if (_file == null) {
        final docDir = await getApplicationDocumentsDirectory();
        _file = File('${docDir.path}/app_settings.json');
      }
      await _file!.writeAsString(jsonEncode(_cache));
    } catch (e) {
      debugPrint('Error saving app_settings.json: $e');
    }
  }
}

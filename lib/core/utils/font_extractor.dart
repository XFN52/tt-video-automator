import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FontExtractor {
  static String? _cachedFontPath;

  /// Returns absolute path to a usable TTF font file for FFmpeg `drawtext` filter.
  /// Returns empty string `''` if no font could be found, so drawtext can be skipped safely.
  static Future<String> getFontPath() async {
    if (_cachedFontPath != null && _cachedFontPath!.isNotEmpty && await File(_cachedFontPath!).exists()) {
      return _cachedFontPath!;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final fontFile = File('${docDir.path}/bold.ttf');

    if (await fontFile.exists()) {
      _cachedFontPath = fontFile.path;
      return _cachedFontPath!;
    }

    // 1. Attempt to load from Flutter rootBundle assets
    try {
      final byteData = await rootBundle.load('assets/fonts/bold.ttf');
      await fontFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
      _cachedFontPath = fontFile.path;
      return _cachedFontPath!;
    } catch (_) {
      // Asset not bundled, fallback to system fonts
    }

    // 2. Windows system font fallbacks
    if (Platform.isWindows) {
      const candidates = [
        r'C:\Windows\Fonts\arialbd.ttf',
        r'C:\Windows\Fonts\arial.ttf',
        r'C:\Windows\Fonts\calibrib.ttf',
        r'C:\Windows\Fonts\calibri.ttf',
        r'C:\Windows\Fonts\segoeuib.ttf',
        r'C:\Windows\Fonts\segoeui.ttf',
        r'C:\Windows\Fonts\tahomabd.ttf',
        r'C:\Windows\Fonts\tahoma.ttf',
      ];

      for (final candidate in candidates) {
        final f = File(candidate);
        if (await f.exists()) {
          _cachedFontPath = f.path;
          return _cachedFontPath!;
        }
      }

      // Dynamic search in Windows fonts directory
      try {
        final fontsDir = Directory(r'C:\Windows\Fonts');
        if (await fontsDir.exists()) {
          final ttf = fontsDir
              .listSync()
              .whereType<File>()
              .firstWhere(
                (f) => f.path.toLowerCase().endsWith('.ttf'),
                orElse: () => File(''),
              );
          if (ttf.path.isNotEmpty) {
            _cachedFontPath = ttf.path;
            return _cachedFontPath!;
          }
        }
      } catch (e) {
        debugPrint('Error searching Windows fonts: $e');
      }
    }

    _cachedFontPath = '';
    return '';
  }
}

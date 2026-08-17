import 'dart:io';

/// Helper to ensure direct physical storage paths without using app cache directories
class StoragePathHelper {
  /// Resolves direct /storage/emulated/0/ path for any picked file to completely bypass cache
  static Future<String> getDirectStoragePath(String path) async {
    if (!Platform.isAndroid || path.isEmpty) return path;

    // If path is already a direct non-cache storage path and exists, return immediately
    if (path.startsWith('/storage/') && !path.contains('/cache/') && await File(path).exists()) {
      return path;
    }

    // Search direct physical storage locations on the device
    final fileName = path.split(RegExp(r'[/\\]')).last;
    final candidates = [
      '/storage/emulated/0/Download/Telegram/$fileName',
      '/storage/emulated/0/Download/$fileName',
      '/storage/emulated/0/Movies/$fileName',
      '/storage/emulated/0/Movies/TT_Automator/$fileName',
      '/storage/emulated/0/DCIM/Camera/$fileName',
      '/storage/emulated/0/DCIM/$fileName',
      '/storage/emulated/0/Pictures/$fileName',
      '/storage/emulated/0/Documents/$fileName',
    ];

    for (final candidate in candidates) {
      if (await File(candidate).exists()) {
        return candidate;
      }
    }

    return path;
  }
}

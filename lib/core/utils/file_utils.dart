class FileUtils {
  static String getFileName(String filePath) {
    if (filePath.isEmpty) return '';
    final segments = filePath.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '';
    return segments.last;
  }

  static String getFileNameWithoutExtension(String filePath) {
    final name = getFileName(filePath);
    final lastDot = name.lastIndexOf('.');
    if (lastDot <= 0) return name;
    return name.substring(0, lastDot);
  }

  static bool isVideoFile(String path) {
    if (path.isEmpty) return false;
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) return false;
    final ext = path.substring(lastDot + 1).toLowerCase();
    return ['mp4', 'mov', 'mkv', 'avi'].contains(ext);
  }
}

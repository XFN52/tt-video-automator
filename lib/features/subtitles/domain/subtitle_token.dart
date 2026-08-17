class SubtitleToken {
  final String word;
  final int startMs;
  final int endMs;

  SubtitleToken({
    required this.word,
    required this.startMs,
    required this.endMs,
  });

  /// Duration of the token in centiseconds (used by ASS \k karaoke tag).
  int get durationCentiseconds {
    final diff = endMs - startMs;
    return (diff / 10).round().clamp(1, 999999);
  }

  /// Formats millisecond timestamp into ASS format: h:mm:ss.cs (e.g. 0:00:01.50)
  static String formatAssTimestamp(int ms) {
    final safeMs = ms.clamp(0, 86400000);
    final hours = safeMs ~/ 3600000;
    final minutes = (safeMs % 3600000) ~/ 60000;
    final seconds = (safeMs % 60000) ~/ 1000;
    final centiseconds = (safeMs % 1000) ~/ 10;

    final h = hours.toString();
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    final cs = centiseconds.toString().padLeft(2, '0');

    return '$h:$m:$s.$cs';
  }

  String get formattedStart => formatAssTimestamp(startMs);
  String get formattedEnd => formatAssTimestamp(endMs);
}

class TextUtils {
  static List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static String cleanText(String text) {
    return text.replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  static double calculateWpm(int wordCount, Duration duration) {
    if (duration.inSeconds == 0) return 0;
    final minutes = duration.inSeconds / 60;
    return wordCount / minutes;
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
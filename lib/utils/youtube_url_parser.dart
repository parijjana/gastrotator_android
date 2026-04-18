/// [SYSTEM INTEGRITY]: Centralized utility for YouTube URL handling.
/// Normalizes various YouTube URL formats (short links, shorts, mobile, desktop)
/// into a standard Video ID to ensure reliable duplicate checking.
class YouTubeUrlParser {
  /// Extracts the 11-character Video ID from any valid YouTube URL.
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;

    // Pattern for standard watch URLs, mobile, shorts, and youtu.be links
    final RegExp regExp = RegExp(
      r'.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
      caseSensitive: false,
    );

    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final id = match.group(1);
      if (id != null && id.length == 11) {
        return id;
      }
    }

    return null;
  }

  /// Normalizes a URL to a standard canonical format.
  static String? normalize(String url) {
    final id = extractVideoId(url);
    if (id == null) return null;
    return 'https://www.youtube.com/watch?v=$id';
  }
}

class RecipeParser {
  /// [PROTECTED LOGIC]: The Smart Parser
  /// Corrects "wall of text" regressions and preserves multi-digit numbering.
  /// Normalizes various list formats (numbered, bullets, dashes) into clean strings.
  static List<String> parseList(String input) {
    if (input.trim().isEmpty) return [];

    // 1. Normalize line endings
    String text = input.replaceAll('\r\n', '\n').trim();

    // 2. Identify and split
    List<String> parts;
    int newlineCount = '\n'.allMatches(text).length;

    // Logic: If there are few newlines but many numbered patterns, it's a "wall of text"
    if (newlineCount < 2 &&
        RegExp(r'\d+[\.\)]\s+').allMatches(text).length >= 2) {
      parts = text.split(RegExp(r'(?=\d+[\.\)]\s+)'));
    } else {
      parts = text.split(RegExp(r'\n+|(?=[•\-\*]\s+)'));
    }

    return parts
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) {
          // Aggressively strip multiple leading markers (e.g., "10. 1. Text" -> "Text")
          String cleaned = s;
          bool changed = true;
          while (changed) {
            final original = cleaned;
            // Strip leading numbers: "1. ", "10) "
            cleaned = cleaned.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '');
            // Strip leading bullets: "• ", "- ", "* "
            cleaned = cleaned.replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
            cleaned = cleaned.trim();
            changed = (original != cleaned);
          }
          return cleaned;
        })
        .where((s) => s.isNotEmpty && s != '•' && s != '-' && s != '*')
        .toList();
  }
}

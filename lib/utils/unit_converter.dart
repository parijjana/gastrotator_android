class UnitConverter {
  static const Map<String, double> _conversions = {
    'tsp': 5.0,
    'teaspoon': 5.0,
    'tbsp': 15.0,
    'tablespoon': 15.0,
    'cup': 240.0,
    'oz': 28.35,
    'ounce': 28.35,
    'lb': 453.59,
    'pound': 453.59,
  };

  static String convertString(String text) {
    // Regex to match patterns like "1 1/2 tsp", "2 tbsp", "0.5 cup"
    // Handles whole numbers, decimals, and simple fractions
    final regex = RegExp(
      r'(\d+[\s\d/.]*)\s*(tsp|teaspoon|tbsp|tablespoon|cup|oz|ounce|lb|pound)s?\b',
      caseSensitive: false,
    );

    return text.replaceAllMapped(regex, (match) {
      final quantityStr = match.group(1)!.trim();
      final unit = match.group(2)!.toLowerCase();

      final quantity = _parseQuantity(quantityStr);
      final multiplier = _conversions[unit] ?? 0.0;

      if (quantity > 0 && multiplier > 0) {
        final grams = (quantity * multiplier).toStringAsFixed(0);
        return "${match.group(0)} ($grams g)";
      }

      return match.group(0)!;
    });
  }

  static double _parseQuantity(String str) {
    try {
      // Handle fractions like "1 1/2"
      if (str.contains(' ')) {
        final parts = str.split(' ');
        double total = 0.0;
        for (var part in parts) {
          total += _parseFraction(part);
        }
        return total;
      }
      return _parseFraction(str);
    } catch (e) {
      return 0.0;
    }
  }

  static double _parseFraction(String str) {
    if (str.contains('/')) {
      final parts = str.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0]) ?? 0.0;
        final den = double.tryParse(parts[1]) ?? 1.0;
        return num / den;
      }
    }
    return double.tryParse(str) ?? 0.0;
  }
}

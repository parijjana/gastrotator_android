import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/utils/unit_converter.dart';

void main() {
  group('UnitConverter Unit Tests', () {
    test('Should convert simple units (tsp, tbsp, cup)', () {
      expect(UnitConverter.convertString("1 tsp salt"), contains("(5 g)"));
      expect(UnitConverter.convertString("2 tbsp sugar"), contains("(30 g)"));
      expect(UnitConverter.convertString("1 cup flour"), contains("(240 g)"));
    });

    test('Should handle plural units', () {
      expect(UnitConverter.convertString("2 teaspoons salt"), contains("(10 g)"));
      expect(UnitConverter.convertString("1.5 tablespoons oil"), contains("(23 g)"));
    });

    test('Should handle fractions (simple)', () {
      expect(UnitConverter.convertString("1/2 cup water"), contains("(120 g)"));
      expect(UnitConverter.convertString("1/4 tsp pepper"), contains("(1 g)"));
    });

    test('Should handle mixed fractions (e.g., 1 1/2)', () {
      expect(UnitConverter.convertString("1 1/2 cups milk"), contains("(360 g)"));
      expect(UnitConverter.convertString("2 1/4 lbs chicken"), contains("(1021 g)"));
    });

    test('Should handle decimals', () {
      expect(UnitConverter.convertString("0.5 cup sugar"), contains("(120 g)"));
      expect(UnitConverter.convertString("1.25 lbs beef"), contains("(567 g)"));
    });

    test('Should handle weight units (oz, lb)', () {
      expect(UnitConverter.convertString("8 oz cheese"), contains("(227 g)"));
      expect(UnitConverter.convertString("1 lb butter"), contains("(454 g)"));
    });

    test('Should be case insensitive', () {
      expect(UnitConverter.convertString("1 TSP salt"), contains("(5 g)"));
      expect(UnitConverter.convertString("1 CUP FLOUR"), contains("(240 g)"));
    });

    test('Should ignore text without valid units', () {
      const input = "Bring to a boil.";
      expect(UnitConverter.convertString(input), input);
    });

    test('Should handle multiple conversions in one string', () {
      const input = "Mix 1 cup flour with 2 tbsp sugar.";
      final result = UnitConverter.convertString(input);
      expect(result, contains("(240 g)"));
      expect(result, contains("(30 g)"));
    });
  });
}

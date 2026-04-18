import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/utils/recipe_parser.dart';

void main() {
  group('RecipeParser Unit Tests', () {
    test('Should parse simple newline-separated lists', () {
      const input = "Ingredient 1\nIngredient 2\nIngredient 3";
      final result = RecipeParser.parseList(input);
      expect(result, ['Ingredient 1', 'Ingredient 2', 'Ingredient 3']);
    });

    test('Should handle "wall of text" with numbering', () {
      const input = "1. First step 2. Second step 3. Third step";
      final result = RecipeParser.parseList(input);
      expect(result, ['First step', 'Second step', 'Third step']);
    });

    test('Should handle multi-digit numbering correctly', () {
      const input = "9. Step nine\n10. Step ten\n11. Step eleven";
      final result = RecipeParser.parseList(input);
      expect(result, ['Step nine', 'Step ten', 'Step eleven']);
    });

    test('Should strip multiple leading markers', () {
      const input = "1. • Step one\n2. - Step two\n3. * Step three";
      final result = RecipeParser.parseList(input);
      expect(result, ['Step one', 'Step two', 'Step three']);
    });

    test('Should handle various bullet types', () {
      const input = "• Bullet one\n- Dash one\n* Asterisk one";
      final result = RecipeParser.parseList(input);
      expect(result, ['Bullet one', 'Dash one', 'Asterisk one']);
    });

    test('Should return empty list for empty input', () {
      expect(RecipeParser.parseList(""), []);
      expect(RecipeParser.parseList("   "), []);
    });

    test('Should handle CRLF line endings', () {
      const input = "Line 1\r\nLine 2";
      final result = RecipeParser.parseList(input);
      expect(result, ['Line 1', 'Line 2']);
    });

    test('Should handle parenthesized numbers', () {
      const input = "1) First 2) Second";
      final result = RecipeParser.parseList(input);
      expect(result, ['First', 'Second']);
    });
  });
}

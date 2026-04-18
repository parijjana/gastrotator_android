import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/services/gemini_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late GeminiService geminiService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    geminiService = GeminiService(apiKey: 'test_key');
  });

  group('GeminiService Parsing', () {
    test('parseRecipe should handle raw JSON correctly', () {
      const jsonText = '''
{
  "dish_name": "Butter Chicken",
  "category": "Dinner",
  "ingredients": "Chicken, Butter",
  "recipe": "Cook it.",
  "total_calories": 500,
  "calories_per_100g": 150,
  "total_weight_grams": 300,
  "cooking_time": "45 mins"
}
''';
      final recipe = geminiService.parseRecipe(
        jsonText,
        'Title',
        'Channel',
        'URL',
        'thumb',
      );

      expect(recipe, isNotNull);
      expect(recipe!.dishName, 'Butter Chicken');
      expect(recipe.totalCalories, 500);
      expect(recipe.cookingTime, '45 mins');
    });

    test('parseRecipe should handle markdown blocks correctly', () {
      const jsonText =
          '```json\n{"dish_name": "Salad", "category": "Lunch", "ingredients": "Lettuce", "recipe": "Mix it."}\n```';
      final recipe = geminiService.parseRecipe(
        jsonText,
        'Title',
        'Channel',
        'URL',
        'thumb',
      );

      expect(recipe, isNotNull);
      expect(recipe!.dishName, 'Salad');
    });

    test('parseRecipe should return null on invalid JSON', () {
      const jsonText = 'invalid json';
      final recipe = geminiService.parseRecipe(
        jsonText,
        'Title',
        'Channel',
        'URL',
        'thumb',
      );

      expect(recipe, isNull);
    });
  });
}

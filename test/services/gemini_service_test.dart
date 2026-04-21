import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/services/ai/remote_gemini_engine.dart';
import 'package:android_app/services/rate_limit_dispatcher.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockRateLimitDispatcher extends Mock implements RateLimitDispatcher {}

void main() {
  late RemoteGeminiEngine geminiService;
  late MockRateLimitDispatcher mockDispatcher;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    mockDispatcher = MockRateLimitDispatcher();
    geminiService = RemoteGeminiEngine(apiKey: 'test_key', dispatcher: mockDispatcher);
  });

  group('RemoteGeminiEngine Parsing', () {
    test('parseRecipe should correctly map a valid JSON string to a Recipe object', () {
      const jsonText = '''
      {
        "dish_name": "Paneer Tikka",
        "category": "Appetizer",
        "ingredients": "Paneer, Curd, Spices",
        "recipe": "Marinate paneer.",
        "total_calories": 300,
        "calories_per_100g": 150,
        "total_weight_grams": 200,
        "cooking_time": "20 mins",
        "tips_warnings": "Do not overcook."
      }
      ''';

      final recipe = geminiService.parseRecipe(
        jsonText,
        'Title',
        'Channel',
        'https://youtube.com/paneer',
        'thumb',
      );

      expect(recipe, isNotNull);
      expect(recipe!.dishName, 'Paneer Tikka');
      expect(recipe.ingredients, 'Paneer, Curd, Spices');
      expect(recipe.recipe, 'Marinate paneer.');
      expect(recipe.youtubeUrl, 'https://youtube.com/paneer');
      expect(recipe.totalCalories, 300);
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

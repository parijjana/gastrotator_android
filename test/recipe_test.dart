import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/models/recipe.dart';

void main() {
  group('Recipe Model', () {
    test('Recipe should be correctly serialized to a map', () {
      final recipe = Recipe(
        id: 1,
        dishName: 'Chicken Curry',
        category: 'Lunch',
        ingredients: 'Chicken, Spices',
        recipe: 'Cook the chicken with spices.',
        youtubeUrl: 'https://youtube.com/test',
        youtubeTitle: 'Test Video',
        youtubeChannel: 'Test Channel',
        totalCalories: 500,
      );

      final map = recipe.toMap();

      expect(map['id'], 1);
      expect(map['dish_name'], 'Chicken Curry');
      expect(map['category'], 'Lunch');
      expect(map['ingredients'], 'Chicken, Spices');
      expect(map['recipe'], 'Cook the chicken with spices.');
      expect(map['youtube_url'], 'https://youtube.com/test');
      expect(map['youtube_title'], 'Test Video');
      expect(map['youtube_channel'], 'Test Channel');
      expect(map['total_calories'], 500);
    });

    test('Recipe should be correctly deserialized from a map', () {
      final map = {
        'id': 2,
        'dish_name': 'Paneer Tikka',
        'category': 'Snack',
        'ingredients': 'Paneer, Spices',
        'recipe': 'Grill the paneer.',
        'youtube_url': 'https://youtube.com/paneer',
        'youtube_title': 'Paneer Video',
        'youtube_channel': 'Paneer Channel',
        'total_calories': 300,
      };

      final recipe = Recipe.fromMap(map);

      expect(recipe.id, 2);
      expect(recipe.dishName, 'Paneer Tikka');
      expect(recipe.category, 'Snack');
      expect(recipe.ingredients, 'Paneer, Spices');
      expect(recipe.recipe, 'Grill the paneer.');
      expect(recipe.youtubeUrl, 'https://youtube.com/paneer');
      expect(recipe.youtubeTitle, 'Paneer Video');
      expect(recipe.youtubeChannel, 'Paneer Channel');
      expect(recipe.totalCalories, 300);
    });
  });
}

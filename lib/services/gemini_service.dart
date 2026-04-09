import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/recipe.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  final GenerativeModel? _mockModel;

  GeminiService({required this.apiKey, GenerativeModel? mockModel}) : _mockModel = mockModel;

  /// Dynamically identifies the latest stable Gemini Flash model available for the API key.
  Future<String> discoverLatestModel() async {
    try {
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey");
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> models = data['models'] ?? [];
        
        final flashModels = models.where((m) {
          final String name = m['name'] ?? "";
          final List<dynamic> methods = m['supportedGenerationMethods'] ?? [];
          return name.contains('gemini') && 
                 name.contains('flash') && 
                 methods.contains('generateContent') &&
                 !name.contains('experimental');
        }).toList();

        if (flashModels.isNotEmpty) {
          flashModels.sort((a, b) => (b['name'] as String).compareTo(a['name'] as String));
          
          String bestModel = flashModels.first['name'];
          if (bestModel.startsWith('models/')) {
            bestModel = bestModel.replaceFirst('models/', '');
          }
          return bestModel;
        }
      }
    } catch (e) {
      print("Model discovery failed: $e");
    }
    return 'gemini-2.5-flash'; // Fallback
  }

  Recipe? parseRecipe(String jsonText, String title, String channel, String url, String? thumbnail, Map<String, dynamic> nutritionalData) {
    try {
      String cleanedJson = jsonText.trim();
      if (cleanedJson.contains('```json')) {
        cleanedJson = cleanedJson.split('```json').last.split('```').first.trim();
      } else if (cleanedJson.contains('```')) {
        cleanedJson = cleanedJson.split('```').last.split('```').first.trim();
      }

      final dynamic decoded = json.decode(cleanedJson);
      Map<String, dynamic> data;

      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('recipes') && decoded['recipes'] is List && decoded['recipes'].isNotEmpty) {
          data = decoded['recipes'][0];
        } else {
          data = decoded;
        }
      } else {
        throw "Decoded JSON is not a Map";
      }
      
      return Recipe(
        dishName: data['dish_name'] ?? title,
        category: data['category'] ?? 'Uncategorized',
        ingredients: data['ingredients'] ?? '',
        recipe: data['recipe'] ?? '',
        youtubeUrl: url,
        youtubeTitle: title,
        youtubeChannel: channel,
        thumbnailUrl: thumbnail,
        totalCalories: nutritionalData['total_calories']?.toDouble(),
        caloriesPer100g: nutritionalData['calories_per_100g']?.toDouble(),
        totalWeightGrams: nutritionalData['total_weight_grams']?.toDouble(),
        cookingTime: nutritionalData['cooking_time']?.toString(),
      );
    } catch (e) {
      print("Parsing Error: $e");
      return null;
    }
  }

  Future<Recipe?> extractRecipeFromContent(
      {required String title, required String channel, required String url, String? thumbnail, String? transcript, String? description}) async {
    
    // Auto-discover the latest model
    final String modelName = await discoverLatestModel();
    print("DEBUG: Using model: $modelName");

    final model = _mockModel ?? GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );

    final String sourceText = (transcript != null && transcript.isNotEmpty) 
        ? "Transcript:\n$transcript" 
        : "Video Description:\n$description";
    
    final prompt = """
    Extract recipe(s) from the following YouTube video information.
    Video Title: "$title"
    Channel: "$channel"

    For a SINGLE recipe, return this JSON structure:
    {
      "dish_name": "Name of the dish",
      "category": "A comma-separated list of applicable categories from: Breakfast, Lunch, Dinner, Dessert, Snack (e.g., 'Lunch, Dinner')",
      "ingredients": "List of ingredients, one per line (STRING with \\n)",
      "recipe": "Step-by-step cooking instructions (STRING with \\n)"
    }

    Return ONLY the raw JSON object.
    
    $sourceText
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final String textForCalories = (transcript != null && transcript.isNotEmpty) ? transcript : (description ?? title);
        final nutritionalData = await _estimateNutritionalData(title, textForCalories, modelName);

        return parseRecipe(response.text!, title, channel, url, thumbnail, nutritionalData);
      }
    } catch (e) {
      print("Gemini Extraction Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> _estimateNutritionalData(String dishName, String content, String modelName) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );

    final prompt = """
    Estimate the nutritional information and cooking time for the recipe described in the content below.
    Video Title: "$dishName"

    Please provide:
    1. Total estimated calories for the entire dish.
    2. Estimated total weight of the finished dish in grams.
    3. Calories per 100g of the finished dish.
    4. Estimated total time to cook/prepare the dish (e.g., "45 mins", "1.5 hours").

    Return ONLY a raw JSON object with this exact structure:
    {
      "total_calories": <number>,
      "total_weight_grams": <number>,
      "calories_per_100g": <number>,
      "cooking_time": "<string>"
    }

    Content:
    $content
    """;

    try {
      final contentResponse = await model.generateContent([Content.text(prompt)]);
      if (contentResponse.text != null) {
        String jsonText = contentResponse.text!.trim();
        if (jsonText.contains('```json')) {
          jsonText = jsonText.split('```json').last.split('```').first.trim();
        } else if (jsonText.contains('```')) {
          jsonText = jsonText.split('```').last.split('```').first.trim();
        }
        return json.decode(jsonText);
      }
    } catch (e) {
       print("Gemini Nutritional Data Error: $e");
    }
    return {
      "total_calories": 0,
      "total_weight_grams": 0,
      "calories_per_100g": 0,
      "cooking_time": "Unknown"
    };
  }
}

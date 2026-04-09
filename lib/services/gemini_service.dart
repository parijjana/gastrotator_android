import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  final String apiKey;
  final GenerativeModel? _mockModel;

  GeminiService({required this.apiKey, GenerativeModel? mockModel}) : _mockModel = mockModel;

  /// Dynamically identifies the latest stable Gemini Flash model available for the API key.
  Future<String> discoverLatestModel() async {
    try {
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models?key=\");
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
      debugPrint("Model discovery failed: \");
    }
    return 'gemini-2.0-flash'; // Optimized fallback
  }

  Recipe? parseRecipe(String jsonText, String title, String channel, String url, String? thumbnail) {
    try {
      String cleanedJson = jsonText.trim();
      if (cleanedJson.contains('`json')) {
        cleanedJson = cleanedJson.split('`json').last.split('`').first.trim();
      } else if (cleanedJson.contains('`')) {
        cleanedJson = cleanedJson.split('`').last.split('`').first.trim();
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
        totalCalories: (data['total_calories'] as num?)?.toDouble(),
        caloriesPer100g: (data['calories_per_100g'] as num?)?.toDouble(),
        totalWeightGrams: (data['total_weight_grams'] as num?)?.toDouble(),
        cookingTime: data['cooking_time']?.toString(),
        notes: data['tips_warnings']?.toString(),
      );
    } catch (e) {
      debugPrint("Parsing Error: \");
      return null;
    }
  }

  Future<Recipe?> extractRecipeFromContent({
    required String title,
    required String channel,
    required String url,
    String? thumbnail,
    String? transcript,
    String? description,
  }) async {
    final String modelName = await discoverLatestModel();
    
    final model = _mockModel ?? GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system("""
You are a cooking assistant. You will receive a raw auto-generated YouTube transcript or video description. Perform the following two operations in order:

STAGE 1 — CLEAN (internal, do not output):
Fix punctuation, correct likely cooking-related transcription errors (e.g. misheard ingredient names and technique words), and resolve run-on sentences. Do not remove content or change meaning. Treat this stage as internal reasoning only — do not include the cleaned transcript in your response.

STAGE 2 — EXTRACT (output this only):
From the cleaned transcript, extract a structured recipe plan including nutritional estimates and cooking time. 

Return ONLY a raw JSON object with this exact structure:
{
  "dish_name": "Name of the dish",
  "category": "Comma-separated list from: Breakfast, Lunch, Dinner, Dessert, Snack",
  "ingredients": "List of ingredients with quantities, one per line",
  "recipe": "Step-by-step cooking instructions with no gaps",
  "tips_warnings": "Key tips or warnings mentioned by the presenter",
  "total_calories": <number>,
  "total_weight_grams": <number>,
  "calories_per_100g": <number>,
  "cooking_time": "Estimated total time (e.g., '45 mins')"
}

No preamble, no commentary.
"""),
    );

    final String sourceText = (transcript != null && transcript.isNotEmpty)
        ? "RAW TRANSCRIPT:\n\"
        : "VIDEO DESCRIPTION:\n\";

    try {
      final response = await model.generateContent([Content.text(sourceText)]);

      if (response.text != null) {
        return parseRecipe(response.text!, title, channel, url, thumbnail);
      }
    } catch (e) {
      debugPrint("Gemini Unified Extraction Error: \");
    }
    return null;
  }
}

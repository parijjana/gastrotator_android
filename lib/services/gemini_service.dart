import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/recipe.dart';
import '../models/validation_result.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  final String apiKey;
  final GenerativeModel? _mockModel;

  GeminiService({required this.apiKey, GenerativeModel? mockModel}) : _mockModel = mockModel;

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
      debugPrint("Model discovery failed: $e");
    }
    return 'gemini-2.0-flash';
  }

  Future<String?> detectLanguage(String text) async {
    final String modelName = await discoverLatestModel();
    final model = _mockModel ?? GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );

    final prompt = "Detect the language of the following text. Reply with only the ISO 639-1 language code (e.g. 'en', 'hi', 'ta'). Text: ${text.substring(0, text.length > 1000 ? 1000 : text.length)}";

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim().toLowerCase();
    } catch (e) {
      debugPrint("Language Detection Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> validateContent(String transcript) async {
    if (transcript.split(' ').length < 200) {
      return {'result': ValidationResult.insufficientContent};
    }

    final String modelName = await discoverLatestModel();
    final model = _mockModel ?? GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );

    final prompt = """
    You are a content classifier for a cooking app. Analyse the following transcript and return a JSON object with exactly these fields:
    {
      "is_cooking_content": boolean,
      "confidence": "high" | "medium" | "low",
      "content_type": string,
      "has_recipe": boolean,
      "reason": string
    }
    Return only valid JSON. No preamble, no markdown.
    
    Transcript:
    $transcript
    """;

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) return {'result': ValidationResult.lowConfidence};
      
      final data = json.decode(response.text!.replaceAll('```json', '').replaceAll('```', '').trim());
      
      if (data['confidence'] == 'low') return {'result': ValidationResult.lowConfidence};
      if (data['is_cooking_content'] == false) return {'result': ValidationResult.wrongDomain, 'content_type': data['content_type']};
      if (data['has_recipe'] == false) return {'result': ValidationResult.foodAdjacent};
      
      return {'result': ValidationResult.valid};
    } catch (e) {
      debugPrint("Validation Error: $e");
      return {'result': ValidationResult.lowConfidence};
    }
  }

  Future<String?> summarizeSegment(String text) async {
    final String modelName = await discoverLatestModel();
    final model = _mockModel ?? GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );

    final prompt = "This is a segment of a cooking video transcript. Summarize only the cooking-relevant content: ingredients mentioned, steps described, and any tips. Be concise. Text:\n$text";

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      debugPrint("Summarization Error: $e");
      return null;
    }
  }

  Recipe? parseRecipe(String jsonText, String title, String channel, String url, String? thumbnail) {
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
        totalCalories: (data['total_calories'] as num?)?.toDouble(),
        caloriesPer100g: (data['calories_per_100g'] as num?)?.toDouble(),
        totalWeightGrams: (data['total_weight_grams'] as num?)?.toDouble(),
        cookingTime: data['cooking_time']?.toString(),
        notes: data['tips_warnings']?.toString(),
      );
    } catch (e) {
      debugPrint("Parsing Error: $e");
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
        ? "RAW TRANSCRIPT:\n$transcript"
        : "VIDEO DESCRIPTION:\n$description";

    try {
      final response = await model.generateContent([Content.text(sourceText)]);

      if (response.text != null) {
        return parseRecipe(response.text!, title, channel, url, thumbnail);
      }
    } catch (e) {
      debugPrint("Gemini Unified Extraction Error: $e");
    }
    return null;
  }
}

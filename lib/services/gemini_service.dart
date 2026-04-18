import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/recipe.dart';
import '../models/validation_result.dart';
import 'package:http/http.dart' as http;
import '../models/transcript_error.dart';
import 'logger/app_logger.dart';

class GeminiService {
  final String apiKey;
  final GenerativeModel? _mockModel;
  final AppLogger _logger = AppLogger();
  final String? lastSuccessfulModel;
  final Function(String)? onModelSuccess;
  final String? contextId;
  final http.Client _httpClient;

  // Priority order for families (Generic keywords, no hardcoded versions)
  static const List<String> _priorityKeywords = ['flash', 'gemma'];

  GeminiService({
    required this.apiKey,
    GenerativeModel? mockModel,
    this.lastSuccessfulModel,
    this.onModelSuccess,
    this.contextId,
    http.Client? httpClient,
  })  : _mockModel = mockModel,
        _httpClient = httpClient ?? http.Client();

  /// 1. Dynamically discover all available models and rank them into a "Ladder"
  Future<List<String>> discoverAndRankModels() async {
    try {
      _logger.info(
        "Discovering available Gemini models for ladder build...",
        apiKeyToMask: apiKey,
        contextId: contextId,
      );
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey",
      );
      final response = await _httpClient.get(url);

      if (response.statusCode != 200) {
        _logger.warn(
          "Model discovery failed (${response.statusCode})",
          details: response.body,
          apiKeyToMask: apiKey,
          contextId: contextId,
        );
        return ['gemini-flash-latest']; // Version-agnostic fallback
      }

      final data = json.decode(response.body);
      final List<dynamic> rawModels = data['models'] ?? [];
      List<String> discovered = [];

      for (var m in rawModels) {
        final String name = m['name'] ?? "";
        final List<dynamic> methods = m['supportedGenerationMethods'] ?? [];

        final nameLower = name.toLowerCase();
        final isViableFamily =
            nameLower.contains('gemini') || nameLower.contains('gemma');
        final isExperimental =
            nameLower.contains('experimental') || nameLower.contains('-exp');
        final isDeprecated = nameLower.contains('deprecated');

        if (isViableFamily &&
            methods.contains('generateContent') &&
            !isExperimental &&
            !isDeprecated) {
          discovered.add(name.replaceFirst('models/', ''));
        }
      }

      // Build the Ladder (Flash & Gemma Only)
      List<String> ladder = [];

      // If we have a last successful model, it goes to the VERY top of the list
      if (lastSuccessfulModel != null &&
          discovered.contains(lastSuccessfulModel)) {
        ladder.add(lastSuccessfulModel!);
        _logger.info(
          "Prioritizing last successful model: $lastSuccessfulModel",
          contextId: contextId,
        );
      }

      for (var keyword in _priorityKeywords) {
        final matches = discovered
            .where((m) => m.toLowerCase().contains(keyword))
            .toList();
        matches.sort(
          (a, b) => b.compareTo(a),
        ); // Prioritize newer versions/names
        for (var m in matches) {
          if (!ladder.contains(m)) ladder.add(m);
        }
      }

      _logger.info(
        "Dynamic Ladder Built: ${ladder.take(3).join(' -> ')} (+${ladder.length > 3 ? ladder.length - 3 : 0} more)",
        contextId: contextId,
      );
      return ladder.isNotEmpty ? ladder : ['gemini-flash-latest'];
    } catch (e) {
      _logger.error(
        "Model discovery exception",
        details: e.toString(),
        apiKeyToMask: apiKey,
        contextId: contextId,
      );
      return ['gemini-flash-latest'];
    }
  }

  /// 2. Generic execution wrapper that "climbs down" the ladder on failure
  Future<T?> _runWithLadder<T>({
    required String actionName,
    required Future<T?> Function(String modelName) task,
  }) async {
    // 1. Try the last successful model first (FAST PATH)
    if (lastSuccessfulModel != null && lastSuccessfulModel!.isNotEmpty) {
      _logger.info(
        "[$actionName] Attempting with prioritized model: $lastSuccessfulModel",
        contextId: contextId,
      );
      try {
        final result = await task(lastSuccessfulModel!);
        if (result != null) {
          _logger.info(
            "[$actionName] SUCCESS using $lastSuccessfulModel",
            contextId: contextId,
          );
          if (onModelSuccess != null) {
            onModelSuccess!(lastSuccessfulModel!);
          }
          return result;
        }
      } catch (e) {
        _logger.warn(
          "[$actionName] Prioritized model $lastSuccessfulModel failed or unavailable. Falling back to ladder...",
          contextId: contextId,
        );
      }
    }

    // 2. Ladder Fallback (SLOW PATH)
    final ladder = await discoverAndRankModels();

    for (String modelName in ladder) {
      // Skip if we already tried it in the fast path
      if (modelName == lastSuccessfulModel) continue;

      _logger.info(
        "[$actionName] Attempting with ladder model: $modelName",
        contextId: contextId,
      );

      try {
        final result = await task(modelName);
        if (result != null) {
          _logger.info(
            "[$actionName] SUCCESS using $modelName",
            contextId: contextId,
          );
          if (onModelSuccess != null) {
            onModelSuccess!(modelName);
          }
          return result;
        }
      } on GenerativeAIException catch (e) {
        final errStr = e.toString();
        _logger.warn(
          "[$actionName] FAILED with $modelName",
          details: errStr,
          apiKeyToMask: apiKey,
          contextId: contextId,
        );

        // 429 is a personal limit, no point in switching models usually, but ladder might have different quotas
        if (errStr.contains('429')) {
          _logger.error(
            "[$actionName] API Limit Reached (429)",
            contextId: contextId,
          );
          throw TranscriptFetchError.apiLimitReached;
        }

        // 503 (Overloaded) or 404 (Not Found/Deprecated) -> Try next rung
        if (errStr.contains('503') || errStr.contains('404')) {
          _logger.warn(
            "[$actionName] Model $modelName is unavailable. Falling back...",
            contextId: contextId,
          );
          continue;
        }

        rethrow; // Other errors (like 400 Bad Request) shouldn't be retried
      } catch (e) {
        _logger.error(
          "[$actionName] Unexpected Exception",
          details: e.toString(),
          apiKeyToMask: apiKey,
          contextId: contextId,
        );
        continue;
      }
    }

    _logger.error(
      "[$actionName] CRITICAL: All models in ladder failed.",
      contextId: contextId,
    );
    return null;
  }

  Future<String?> detectLanguage(String text) async {
    return _runWithLadder<String>(
      actionName: "Language Detection",
      task: (modelName) async {
        final model =
            _mockModel ?? GenerativeModel(model: modelName, apiKey: apiKey);
        final prompt =
            "Detect the language of the following text. Reply with only the ISO 639-1 language code (e.g. 'en', 'hi', 'ta'). Text: ${text.substring(0, text.length > 1000 ? 1000 : text.length)}";
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text?.trim().toLowerCase();
      },
    );
  }

  Future<Map<String, dynamic>> validateContent(String transcript) async {
    if (transcript.split(' ').length < 200) {
      return {'result': ValidationResult.insufficientContent};
    }

    final result = await _runWithLadder<Map<String, dynamic>>(
      actionName: "Domain Validation",
      task: (modelName) async {
        final model =
            _mockModel ?? GenerativeModel(model: modelName, apiKey: apiKey);
        final prompt =
            """
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

        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text == null) return null;

        final data = json.decode(
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim(),
        );

        if (data['confidence'] == 'low') {
          return {'result': ValidationResult.lowConfidence};
        }
        if (data['is_cooking_content'] == false) {
          return {
            'result': ValidationResult.wrongDomain,
            'content_type': data['content_type'],
          };
        }
        if (data['has_recipe'] == false) {
          return {'result': ValidationResult.foodAdjacent};
        }

        return {'result': ValidationResult.valid};
      },
    );

    return result ?? {'result': ValidationResult.lowConfidence};
  }

  Future<String?> summarizeSegment(String text) async {
    return _runWithLadder<String>(
      actionName: "Segment Summary",
      task: (modelName) async {
        final model =
            _mockModel ?? GenerativeModel(model: modelName, apiKey: apiKey);
        final prompt =
            "This is a segment of a cooking video transcript. Summarize only the cooking-relevant content: ingredients mentioned, steps described, and any tips. Be concise. Text:\n$text";
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text?.trim();
      },
    );
  }

  Recipe? parseRecipe(
    String jsonText,
    String title,
    String channel,
    String url,
    String? thumbnail,
  ) {
    try {
      String cleanedJson = jsonText.trim();
      if (cleanedJson.contains('```json')) {
        cleanedJson = cleanedJson
            .split('```json')
            .last
            .split('```')
            .first
            .trim();
      } else if (cleanedJson.contains('```')) {
        cleanedJson = cleanedJson.split('```').last.split('```').first.trim();
      }

      final dynamic decoded = json.decode(cleanedJson);
      Map<String, dynamic> data;

      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('recipes') &&
            decoded['recipes'] is List &&
            decoded['recipes'].isNotEmpty) {
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
      _logger.error(
        "Recipe Parsing Error",
        details: e.toString(),
        apiKeyToMask: apiKey,
      );
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
    final String sourceText = (transcript != null && transcript.isNotEmpty)
        ? "RAW TRANSCRIPT:\n$transcript"
        : "VIDEO DESCRIPTION:\n$description";

    return _runWithLadder<Recipe>(
      actionName: "Recipe Extraction",
      task: (modelName) async {
        // Note: For complex tasks like this, we need to pass system instructions.
        final specializedModel =
            _mockModel ??
            GenerativeModel(
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
  "recipe": "Step-by-step cooking instructions. Use a numbered list (1., 2., 3.) with each step on a new line. Ensure logical flow and clarity.",
  "tips_warnings": "Key tips or warnings mentioned by the presenter",
  "total_calories": <number>,
  "total_weight_grams": <number>,
  "calories_per_100g": <number>,
  "cooking_time": "Estimated total time (e.g., '45 mins')"
}

No preamble, no commentary.
"""),
            );

        final response = await specializedModel.generateContent([
          Content.text(sourceText),
        ]);
        if (response.text == null) return null;
        return parseRecipe(response.text!, title, channel, url, thumbnail);
      },
    );
  }
}

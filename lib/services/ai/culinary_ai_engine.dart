import '../../models/recipe.dart';

/// [SYSTEM INTEGRITY]: Core interface for all AI culinary engines.
/// Allows for seamless switching between Local LLMs and Remote APIs.
abstract class CulinaryAiEngine {
  String get name;
  bool get isLocal;

  /// Detects the language of a raw transcript.
  /// Returns a record with the result and the specific model name used.
  Future<(String? result, String? modelUsed)> detectLanguage(String text);

  /// Validates if the content is actually about cooking.
  Future<Map<String, dynamic>> validateContent(String transcript, {String? modelName});

  /// Summarizes a long transcript segment into culinary-relevant bits.
  Future<String?> summarize(String text, {String? modelName});

  /// The heavy lift: Transforms unstructured data into a Recipe object.
  Future<Recipe?> extractRecipe({
    required String title,
    required String channel,
    required String url,
    String? thumbnail,
    String? transcript,
    String? description,
    String? modelName,
  });
}

/// Status states for AI Engines (e.g., checking if model is downloaded).
enum AiEngineStatus {
  available,
  unsupported,
  downloadRequired,
  apiKeyMissing,
  error,
}

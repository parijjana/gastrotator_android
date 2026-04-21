import 'culinary_ai_engine.dart';
import 'remote_gemini_engine.dart';
import '../../models/recipe.dart';
import '../logger/app_logger.dart';

/// [SYSTEM INTEGRITY]: The Orchestrator manages the hierarchy of AI backends.
/// Standard Preference: 1. Local LLM (Future) -> 2. Remote Gemini API
class CulinaryAiOrchestrator {
  final List<CulinaryAiEngine> _engines = [];
  final AppLogger _logger = AppLogger();

  CulinaryAiOrchestrator();

  /// Adds a new engine to the hierarchy.
  void registerEngine(CulinaryAiEngine engine) {
    _engines.add(engine);
    _logger.info("AI Engine Registered: ${engine.name} (Local: ${engine.isLocal})");
  }

  /// Helper to get the best available engine for a task.
  Future<CulinaryAiEngine?> _getBestEngine() async {
    // For now, we only have Remote Gemini, but the loop is ready for Local.
    for (var engine in _engines) {
       return engine; 
    }
    return null;
  }

  Future<(String? result, String? modelUsed)> detectLanguage(String text) async {
    final engine = await _getBestEngine();
    if (engine == null) return (null, null);
    _logger.info("Detecting language with: ${engine.name}");
    return await engine.detectLanguage(text);
  }

  Future<Map<String, dynamic>> validateContent(String transcript, {String? modelName}) async {
    final engine = await _getBestEngine();
    if (engine == null) return {'result': null};
    _logger.info("Validating content with: ${engine.name}");
    return await engine.validateContent(transcript, modelName: modelName);
  }

  Future<String?> summarize(String text, {String? modelName}) async {
    final engine = await _getBestEngine();
    if (engine == null) return null;
    _logger.info("Summarizing with: ${engine.name}");
    return await engine.summarize(text, modelName: modelName);
  }

  Future<Recipe?> extractRecipe({
    required String title,
    required String channel,
    required String url,
    String? thumbnail,
    String? transcript,
    String? description,
    String? modelName,
  }) async {
    final engine = await _getBestEngine();
    if (engine == null) return null;
    _logger.info("Extracting recipe with: ${engine.name}");
    return await engine.extractRecipe(
      title: title,
      channel: channel,
      url: url,
      thumbnail: thumbnail,
      transcript: transcript,
      description: description,
      modelName: modelName,
    );
  }

  /// Exposes the specific engines for direct health checks if needed.
  List<CulinaryAiEngine> get engines => List.unmodifiable(_engines);
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/database_helper.dart';
import '../models/recipe.dart';
import '../models/transcript_error.dart';
import '../models/validation_result.dart';
import '../models/video_length.dart';
import '../services/gemini_service.dart';
import '../services/youtube_service.dart';
import '../utils/youtube_url_parser.dart';
import '../services/logger/app_logger.dart';

// --- API Key Provider ---

/// [SYSTEM INTEGRITY]: AsyncNotifier for the Gemini API Key.
/// Ensures that any consumer (like the AI Worker) waits for the disk read to complete.
class ApiKeyNotifier extends AsyncNotifier<String?> {
  static const _key = 'gemini_api_key';
  late FlutterSecureStorage _storage;
  final AppLogger _logger = AppLogger();

  @override
  Future<String?> build() async {
    _storage = ref.watch(secureStorageProvider);
    final key = await _storage.read(key: _key);
    _logger.info("API Key loaded from secure storage.");
    return key;
  }

  Future<void> saveKey(String key) async {
    state = const AsyncValue.loading();
    final trimmedKey = key.trim();
    state = await AsyncValue.guard(() async {
      await _storage.write(key: _key, value: trimmedKey);
      _logger.info("API Key saved securely.");
      return trimmedKey;
    });
  }

  Future<void> deleteKey() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _storage.delete(key: _key);
      _logger.info("API Key deleted from secure storage.");
      return null;
    });
  }
}

final apiKeyProvider = AsyncNotifierProvider<ApiKeyNotifier, String?>(
  ApiKeyNotifier.new,
);

// --- Secure Storage Provider ---

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// --- Gemini Service Provider ---

class LastSuccessfulModelNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

final lastSuccessfulModelProvider =
    NotifierProvider<LastSuccessfulModelNotifier, String?>(
  LastSuccessfulModelNotifier.new,
);

final geminiServiceProvider =
    Provider.family<GeminiService, String?>((ref, contextId) {
  // Note: We use synchronous watch here, but the worker awaits the future first
  final apiKey = ref.watch(apiKeyProvider).value ?? '';
  final lastModel = ref.watch(lastSuccessfulModelProvider);

  return GeminiService(
    apiKey: apiKey,
    lastSuccessfulModel: lastModel,
    onModelSuccess: (modelName) {
      ref.read(lastSuccessfulModelProvider.notifier).set(modelName);
      ref
          .read(secureStorageProvider)
          .write(key: 'last_successful_model', value: modelName);
    },
    contextId: contextId,
  );
});

// --- External Services Providers ---

final youTubeServiceProvider = Provider<YouTubeService>((ref) {
  final yt = YouTubeService();
  ref.onDispose(() => yt.close());
  return yt;
});

// --- Theme Provider ---

class ThemeSettings {
  final Color primaryColor;
  final Brightness brightness;

  ThemeSettings({required this.primaryColor, required this.brightness});

  ThemeSettings copyWith({Color? primaryColor, Brightness? brightness}) {
    return ThemeSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      brightness: brightness ?? this.brightness,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeSettings> {
  static const _colorKey = 'primary_color';
  static const _brightnessKey = 'brightness';
  late FlutterSecureStorage _storage;

  @override
  ThemeSettings build() {
    _storage = ref.watch(secureStorageProvider);
    _loadSettings();
    return ThemeSettings(
      primaryColor: const Color(0xFF944A00),
      brightness: Brightness.light,
    );
  }

  Future<void> _loadSettings() async {
    final colorHex = await _storage.read(key: _colorKey);
    final brightnessStr = await _storage.read(key: _brightnessKey);

    state = ThemeSettings(
      primaryColor:
          colorHex != null
              ? Color(int.parse(colorHex))
              : const Color(0xFF944A00),
      brightness: brightnessStr == 'dark' ? Brightness.dark : Brightness.light,
    );
  }

  Future<void> setPrimaryColor(Color color) async {
    await _storage.write(key: _colorKey, value: color.value.toString());
    state = state.copyWith(primaryColor: color);
  }

  Future<void> setBrightness(Brightness brightness) async {
    await _storage.write(
      key: _brightnessKey,
      value: brightness == Brightness.dark ? 'dark' : 'light',
    );
    state = state.copyWith(brightness: brightness);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeSettings>(
  ThemeNotifier.new,
);

// --- Recipes Provider ---

final recipesProvider = NotifierProvider<RecipesNotifier, List<Recipe>>(
  RecipesNotifier.new,
);

class MagicOverlayNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void show() => state = true;
  void hide() => state = false;
}

final magicOverlayProvider = NotifierProvider<MagicOverlayNotifier, bool>(
  MagicOverlayNotifier.new,
);

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final workerEnabledProvider = Provider<bool>((ref) => true);

class RecipesNotifier extends Notifier<List<Recipe>> {
  final AppLogger _logger = AppLogger();
  late DatabaseHelper _db;

  // New state to notify UI about which recipe should shake
  int? _pendingShakeId;
  int? get pendingShakeId => _pendingShakeId;

  // Queue Worker State
  bool _isWorkerBusy = false;

  @override
  List<Recipe> build() {
    _db = ref.watch(databaseHelperProvider);
    loadRecipes().then((_) {
      if (ref.read(workerEnabledProvider)) {
        if (ref.mounted) _startQueueWorker();
      }
    });
    return [];
  }

  Future<void> loadRecipes() async {
    final recipes = await _db.getAllRecipes();
    if (!ref.mounted) return;
    state = recipes;
  }

  Future<String> exportRecipes() async {
    final recipes = await _db.getAllRecipes();
    final list = recipes.map((r) => r.toMap()).toList();
    return jsonEncode(list);
  }

  Future<void> importRecipes(String jsonString) async {
    final List<dynamic> list = jsonDecode(jsonString);
    for (var item in list) {
      final recipe = Recipe.fromMap(Map<String, dynamic>.from(item));
      // Reset ID to let database handle auto-increment
      final newRecipe = recipe.copyWith(id: null);
      await _db.insert(newRecipe);
    }
    await loadRecipes();
    if (ref.read(workerEnabledProvider)) {
      if (ref.mounted) _startQueueWorker();
    }
  }

  Future<void> loadSamples() async {
    // Basic sample recipes
    final samples = [
      Recipe(
        dishName: "Classic Margherita Pizza",
        category: "Dinner",
        ingredients: "Flour, Water, Yeast, Tomato Sauce, Mozzarella, Basil",
        recipe: "1. Make dough. 2. Add toppings. 3. Bake at 450F.",
        importStatus: "Completed",
        totalCalories: 850,
      ),
      Recipe(
        dishName: "Morning Berry Smoothie",
        category: "Breakfast",
        ingredients: "Banana, Blueberries, Milk, Honey",
        recipe: "1. Blend all ingredients until smooth.",
        importStatus: "Completed",
        totalCalories: 320,
      ),
    ];

    for (var r in samples) {
      await _db.insert(r);
    }
    await loadRecipes();
  }

  Future<void> addRecipe(Recipe recipe) async {
    await _db.insert(recipe);
    await loadRecipes();
    if (ref.read(workerEnabledProvider)) {
      if (!ref.mounted) return;
      _startQueueWorker();
    }
  }

  Future<void> updateManualTranscript(Recipe recipe, String transcript) async {
    await updateRecipe(
      recipe.copyWith(
        transcript: transcript,
        importStatus: "Transcript Fetched",
        transcriptError: TranscriptFetchError.none,
        validationResult: ValidationResult.valid,
      ),
    );
    if (ref.read(workerEnabledProvider)) {
      if (!ref.mounted) return;
      _startQueueWorker();
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _db.update(recipe);
    await loadRecipes();
  }

  Future<void> deleteRecipe(int id) async {
    await _db.delete(id);
    await loadRecipes();
  }

  int getRelativePosition(int id) {
    final queuedItems = state.where((r) => r.importStatus == "In Queue").toList();
    queuedItems.sort(
      (a, b) => (a.queuePosition ?? 0).compareTo(b.queuePosition ?? 0),
    );

    final index = queuedItems.indexWhere((r) => r.id == id);
    return index != -1 ? index + 1 : 0;
  }

  // --- AI Magic Workflow ---

  Future<void> triggerMagicImport(String url) async {
    final videoId = YouTubeUrlParser.extractVideoId(url);
    if (videoId == null) throw "Invalid YouTube URL";

    final normalizedUrl = "https://www.youtube.com/watch?v=$videoId";

    // 1. Centralized Duplicate Check (using normalized ID)
    final existingIndex = state.indexWhere(
      (r) =>
          r.youtubeUrl != null &&
          (YouTubeUrlParser.extractVideoId(r.youtubeUrl!) == videoId),
    );

    if (existingIndex != -1) {
      final existingRecipe = state[existingIndex];
      _pendingShakeId = existingRecipe.id;
      ref.notifyListeners();

      Future.delayed(const Duration(seconds: 1), () {
        _pendingShakeId = null;
      });

      throw "Duplicate Recipe: This video is already in your kitchen.";
    }

    // 2. Assign Queue Position
    int nextPos = 1;
    if (state.isNotEmpty) {
      final positions =
          state.map((r) => r.queuePosition ?? 0).where((p) => p > 0).toList();
      if (positions.isNotEmpty) {
        nextPos = positions.reduce((a, b) => a > b ? a : b) + 1;
      }
    }

    final timestamp = DateTime.now().toString().split('.').first;
    final placeholder = Recipe(
      dishName: "Importing: $timestamp",
      category: "Pending",
      ingredients: "",
      recipe: "",
      youtubeUrl: normalizedUrl,
      importStatus: "In Queue",
      queuePosition: nextPos,
    );

    _logger.info("Import triggered.", contextId: normalizedUrl);
    await addRecipe(placeholder);
  }

  Future<void> processRecipeImmediately(int id) async {
    final recipes = await _db.getAllRecipes();
    final targetIdx = recipes.indexWhere((r) => r.id == id);
    if (targetIdx == -1) return;

    final target = recipes[targetIdx];

    // Find current minimum position in queue
    int minPos = 1;
    final activeQueue =
        recipes
            .where(
              (r) =>
                  r.importStatus == "In Queue" ||
                  r.importStatus == "Placeholder Created",
            )
            .toList();

    if (activeQueue.isNotEmpty) {
      final positions =
          activeQueue
              .map((r) => r.queuePosition ?? 0)
              .where((p) => p > 0)
              .toList();
      if (positions.isNotEmpty) {
        minPos = positions.reduce((a, b) => a < b ? a : b);
      }
    }

    // Set target to be first
    await updateRecipe(
      target.copyWith(
        queuePosition: minPos - 1,
        importStatus: "In Queue", // Ensure it's back in queue if it was failed
      ),
    );

    if (ref.read(workerEnabledProvider)) {
      _startQueueWorker();
    }
  }

  Future<void> _startQueueWorker() async {
    if (_isWorkerBusy) return;
    _isWorkerBusy = true;

    try {
      await _processQueue();
    } finally {
      _isWorkerBusy = false;
    }
  }

  Future<void> _processQueue() async {
    while (true) {
      if (!ref.mounted) break;

      // Reload state to see latest status
      final currentRecipes = await _db.getAllRecipes();
      if (!ref.mounted) break;
      state = currentRecipes;

      // Find the next recipe in queue (lowest position)
      final queue =
          state
              .where(
                (r) =>
                    r.importStatus == "In Queue" ||
                    r.importStatus == "Placeholder Created",
              )
              .toList();

      if (queue.isEmpty) break;

      queue.sort(
        (a, b) => (a.queuePosition ?? 0).compareTo(b.queuePosition ?? 0),
      );
      final nextRecipe = queue.first;

      try {
        await autoProcessRecipe(nextRecipe);
        // Breathing room between recipes to prevent rate-limiting
        await Future.delayed(const Duration(milliseconds: 1500));
      } catch (e) {
        debugPrint("Queue Worker error: $e");
      }

      if (!ref.mounted) break;
    }
  }

  Future<void> autoProcessRecipe(Recipe recipe) async {
    if (recipe.importStatus == "Completed" ||
        recipe.importStatus?.startsWith("Failed") == true) {
      return;
    }

    final contextId = recipe.youtubeUrl;

    try {
      if (recipe.importStatus == "In Queue" ||
          recipe.importStatus == "Placeholder Created") {
        _logger.info("Worker: Starting metadata fetch.", contextId: contextId);
        await _fetchMetadata(recipe);
        if (!ref.mounted) return;
        final updated = state.firstWhere((r) => r.id == recipe.id);
        await autoProcessRecipe(updated);
        return;
      }

      if (recipe.importStatus == "Metadata Fetched") {
        _logger.info("Worker: Starting transcript fetch.", contextId: contextId);
        await _fetchTranscript(recipe);
        if (!ref.mounted) return;
        final updated = state.firstWhere((r) => r.id == recipe.id);
        await autoProcessRecipe(updated);
        return;
      }

      if (recipe.importStatus == "Transcript Fetched") {
        _logger.info("Worker: Starting AI extraction.", contextId: contextId);
        await _runGemini(recipe);
        return;
      }
    } catch (e) {
      _logger.error("Auto-process critical error: $e", contextId: contextId);
      if (ref.mounted) {
        await updateRecipe(
          recipe.copyWith(importStatus: "Failed: Auto-process"),
        );
      }
    }
  }

  Future<void> _fetchMetadata(Recipe recipe) async {
    final contextId = recipe.youtubeUrl;
    await updateRecipe(recipe.copyWith(importStatus: "Fetching Metadata..."));
    if (!ref.mounted) return;

    final yt = ref.read(youTubeServiceProvider);
    final result = await yt.fetchVideoMetadataOnly(recipe.youtubeUrl!);

    if (!ref.mounted) return;
    if (result['success'] == true) {
      _logger.info("Metadata fetched successfully.", contextId: contextId);
      await updateRecipe(
        recipe.copyWith(
          dishName: result['title'],
          youtubeTitle: result['title'],
          youtubeChannel: result['channel'],
          thumbnailUrl: result['thumbnail'],
          importStatus: "Metadata Fetched",
        ),
      );
    } else {
      _logger.warn(
        "Metadata fetch failed: ${result['error']}",
        contextId: contextId,
      );
      await updateRecipe(recipe.copyWith(importStatus: "Failed: Metadata"));
    }
  }

  Future<void> _fetchTranscript(Recipe recipe) async {
    final contextId = recipe.youtubeUrl;
    await updateRecipe(recipe.copyWith(importStatus: "Fetching Transcript..."));
    if (!ref.mounted) return;

    final url = recipe.youtubeUrl!;
    final videoId = YouTubeUrlParser.extractVideoId(url);
    if (videoId == null) {
      _logger.error(
        "Failed to extract Video ID from URL: $url",
        contextId: contextId,
      );
      await updateRecipe(recipe.copyWith(importStatus: "Failed: URL"));
      return;
    }
    final isShort = url.contains('/shorts/');

    final yt = ref.read(youTubeServiceProvider);
    final result = await yt.fetchTranscriptOnly(videoId, isShort: isShort);

    if (!ref.mounted) return;
    if (result['success'] == true) {
      _logger.info("Transcript fetched successfully.", contextId: contextId);
      await updateRecipe(
        recipe.copyWith(
          transcript: result['transcript'],
          durationSeconds: (result['durationSeconds'] as num?)?.toDouble(),
          segments:
              result['segments'] != null
                  ? List<Map<String, dynamic>>.from(result['segments'])
                  : null,
          importStatus: "Transcript Fetched",
          transcriptError: TranscriptFetchError.none,
          validationResult: ValidationResult.valid,
        ),
      );
    } else {
      final errorType = result['errorType'] ?? TranscriptFetchError.unknownError;
      _logger.warn(
        "Transcript fetch failed: ${result['error']}",
        contextId: contextId,
      );
      await updateRecipe(
        recipe.copyWith(
          importStatus: "No transcript found",
          transcriptError: errorType,
        ),
      );
    }
  }

  Future<void> _runGemini(Recipe recipe) async {
    final contextId = recipe.youtubeUrl;
    if (!ref.mounted) return;

    // SAFETY: Await the API key future to ensure eager load has completed
    final apiKey = await ref.read(apiKeyProvider.future);

    if (apiKey == null || apiKey.isEmpty) {
      _logger.error(
        "AI extraction aborted: Missing API Key.",
        contextId: contextId,
      );
      await updateRecipe(
        recipe.copyWith(importStatus: "Failed: Missing API Key"),
      );
      return;
    }

    final transcript = recipe.transcript;
    if (transcript == null || transcript.isEmpty) {
      _logger.error(
        "AI extraction aborted: No transcript found.",
        contextId: contextId,
      );
      await updateRecipe(recipe.copyWith(importStatus: "Failed: No source text"));
      return;
    }

    if (!ref.mounted) return;
    final gemini = ref.read(geminiServiceProvider(contextId));

    await updateRecipe(recipe.copyWith(importStatus: "Analyzing Language..."));
    if (!ref.mounted) return;

    final langCode = await gemini.detectLanguage(transcript);
    if (!ref.mounted) return;
    if (langCode != null && langCode != 'en') {
      _logger.warn(
        "AI detected unsupported language: $langCode",
        contextId: contextId,
      );
      await updateRecipe(
        recipe.copyWith(
          importStatus: "No transcript found",
          transcriptError: TranscriptFetchError.unsupportedLanguage,
          category: langCode,
        ),
      );
      return;
    }

    await updateRecipe(recipe.copyWith(importStatus: "Validating Content..."));
    if (!ref.mounted) return;
    final validation = await gemini.validateContent(transcript);
    if (!ref.mounted) return;
    final valResult = validation['result'] as ValidationResult;

    if (valResult == ValidationResult.wrongDomain ||
        valResult == ValidationResult.insufficientContent) {
      _logger.warn(
        "Content validation failed: ${valResult.name}",
        contextId: contextId,
      );
      await updateRecipe(
        recipe.copyWith(
          importStatus: "No transcript found",
          validationResult: valResult,
          flavorProfile: (validation['content_type'] as String?),
        ),
      );
      return;
    }

    final recipeWithVal = recipe.copyWith(validationResult: valResult);
    await updateRecipe(recipeWithVal);
    if (!ref.mounted) return;

    String finalInputText = transcript;
    if (recipeWithVal.videoLength == VideoLength.long &&
        recipeWithVal.importStatus != "Processing Confirmed") {
      _logger.info(
        "Long video detected. Awaiting user confirmation.",
        contextId: contextId,
      );
      await updateRecipe(
        recipeWithVal.copyWith(
          importStatus: "Awaiting Confirmation (Long Video)",
        ),
      );
      return;
    }

    if (recipeWithVal.videoLength == VideoLength.medium ||
        (recipeWithVal.videoLength == VideoLength.long &&
            recipeWithVal.importStatus == "Processing Confirmed")) {
      await updateRecipe(
        recipeWithVal.copyWith(importStatus: "Summarizing Segments..."),
      );
      if (!ref.mounted) return;
      final segments = recipeWithVal.segments;
      if (segments != null && segments.isNotEmpty) {
        _logger.info(
          "Summarizing video segments for extraction.",
          contextId: contextId,
        );
        List<String> summaries = [];
        String currentChunk = "";
        double chunkStartTime =
            (segments.first['start'] as num?)?.toDouble() ?? 0.0;

        for (var seg in segments) {
          currentChunk += " ${seg['text']}";
          double currentTime = (seg['start'] as num?)?.toDouble() ?? 0.0;

          if (currentTime - chunkStartTime > 300) {
            final summary = await gemini.summarizeSegment(currentChunk);
            if (summary != null) summaries.add(summary);
            currentChunk = "";
            chunkStartTime = currentTime;
          }
        }
        if (currentChunk.isNotEmpty) {
          final summary = await gemini.summarizeSegment(currentChunk);
          if (summary != null) summaries.add(summary);
        }
        finalInputText = summaries.join("\n\n---\n\n");
      }
    }

    if (!ref.mounted) return;
    await updateRecipe(recipeWithVal.copyWith(importStatus: "AI Processing..."));
    try {
      final result = await gemini.extractRecipeFromContent(
        title: recipeWithVal.youtubeTitle ?? recipeWithVal.dishName,
        channel: recipeWithVal.youtubeChannel ?? "Unknown",
        url: recipeWithVal.youtubeUrl!,
        thumbnail: recipeWithVal.thumbnailUrl,
        transcript: finalInputText,
      );

      if (!ref.mounted) return;
      if (result != null) {
        _logger.info(
          "AI extraction completed successfully.",
          contextId: contextId,
        );
        await updateRecipe(
          result.copyWith(
            id: recipeWithVal.id,
            importStatus: "Completed",
            validationResult: valResult,
          ),
        );
      } else {
        _logger.error(
          "Gemini failed to return a valid recipe.",
          contextId: contextId,
        );
        await updateRecipe(recipeWithVal.copyWith(importStatus: "Failed: Gemini"));
      }
    } on TranscriptFetchError catch (e) {
      if (!ref.mounted) return;
      if (e == TranscriptFetchError.apiLimitReached) {
        _logger.error(
          "API Limit Reached during extraction.",
          contextId: contextId,
        );
        await updateRecipe(
          recipeWithVal.copyWith(
            importStatus: "No transcript found",
            transcriptError: TranscriptFetchError.apiLimitReached,
          ),
        );
      } else {
        await updateRecipe(recipeWithVal.copyWith(importStatus: "Failed: Gemini"));
      }
    } catch (e) {
      _logger.error(
        "Unexpected error during Gemini extraction: $e",
        contextId: contextId,
      );
      if (ref.mounted) {
        await updateRecipe(recipeWithVal.copyWith(importStatus: "Failed: Gemini"));
      }
    }
  }

  Future<void> confirmLongVideoProcessing(Recipe recipe) async {
    await updateRecipe(recipe.copyWith(importStatus: "Processing Confirmed"));
    if (!ref.mounted) return;
    final updated = state.firstWhere((r) => r.id == recipe.id);
    _runGemini(updated);
  }
}

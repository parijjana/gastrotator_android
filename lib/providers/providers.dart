import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/database_helper.dart';
import '../models/recipe.dart';
import '../models/transcript_error.dart';
import '../models/video_length.dart';
import '../models/validation_result.dart';
import '../services/youtube_service.dart';
import '../services/gemini_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

class ThemeSettings {
  final Color primaryColor;
  final Brightness brightness;

  ThemeSettings({
    required this.primaryColor,
    required this.brightness,
  });

  ThemeSettings copyWith({
    Color? primaryColor,
    Brightness? brightness,
  }) {
    return ThemeSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      brightness: brightness ?? this.brightness,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeSettings> {
  static const _primaryKey = 'theme_primary';
  static const _darkKey = 'theme_dark';

  @override
  ThemeSettings build() {
    _loadTheme();
    return ThemeSettings(
      primaryColor: const Color(0xFFFF8C00),
      brightness: Brightness.light,
    );
  }

  Future<void> _loadTheme() async {
    final storage = ref.read(secureStorageProvider);
    final primary = await storage.read(key: _primaryKey);
    final dark = await storage.read(key: _darkKey);

    if (!ref.mounted) return;

    if (primary != null || dark != null) {
      state = ThemeSettings(
        primaryColor: primary != null ? Color(int.parse(primary)) : state.primaryColor,
        brightness: dark == 'true' ? Brightness.dark : Brightness.light,
      );
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    await ref.read(secureStorageProvider).write(key: _primaryKey, value: color.value.toString());
  }

  Future<void> toggleBrightness() async {
    final newBrightness = state.brightness == Brightness.light ? Brightness.dark : Brightness.light;
    state = state.copyWith(brightness: newBrightness);
    await ref.read(secureStorageProvider).write(key: _darkKey, value: (newBrightness == Brightness.dark).toString());
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeSettings>(() {
  return ThemeNotifier();
});

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String?>(() {
  return ApiKeyNotifier();
});

class ApiKeyNotifier extends Notifier<String?> {
  static const _key = 'gemini_api_key';

  @override
  String? build() {
    _loadKey();
    return null;
  }

  Future<void> _loadKey() async {
    final storage = ref.read(secureStorageProvider);
    final key = await storage.read(key: _key);
    if (!ref.mounted) return;
    state = key;
  }

  Future<void> saveKey(String key) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _key, value: key);
    state = key;
  }

  Future<void> deleteKey() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _key);
    state = null;
  }
}

final recipesProvider = NotifierProvider<RecipesNotifier, List<Recipe>>(() {
  return RecipesNotifier();
});

class RecipesNotifier extends Notifier<List<Recipe>> {
  @override
  List<Recipe> build() {
    loadRecipes();
    return [];
  }

  Future<void> loadRecipes() async {
    final recipes = await DatabaseHelper.instance.getAllRecipes();
    state = recipes;
  }

  Future<void> addRecipe(Recipe recipe) async {
    final id = await DatabaseHelper.instance.insert(recipe);
    await loadRecipes();
    if (recipe.importStatus == "Placeholder Created") {
      final addedRecipe = state.firstWhere((r) => r.id == id);
      autoProcessRecipe(addedRecipe);
    }
  }

  Future<void> updateManualTranscript(Recipe recipe, String transcript) async {
    await updateRecipe(recipe.copyWith(
      transcript: transcript,
      importStatus: "Transcript Fetched",
      transcriptError: TranscriptFetchError.none,
      validationResult: ValidationResult.valid,
    ));
    final updated = state.firstWhere((r) => r.id == recipe.id);
    autoProcessRecipe(updated);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await DatabaseHelper.instance.update(recipe);
    await loadRecipes();
  }

  Future<void> deleteRecipe(int id) async {
    await DatabaseHelper.instance.delete(id);
    await loadRecipes();
  }

  Future<String> exportRecipes() async {
    final recipes = await DatabaseHelper.instance.getAllRecipes();
    final list = recipes.map((r) => {
      'dishName': r.dishName,
      'category': r.category,
      'ingredients': r.ingredients,
      'recipe': r.recipe,
      'youtubeUrl': r.youtubeUrl,
      'youtubeTitle': r.youtubeTitle,
      'youtubeChannel': r.youtubeChannel,
      'thumbnailUrl': r.thumbnailUrl,
      'totalCalories': r.totalCalories,
      'caloriesPer100g': r.caloriesPer100g,
      'totalWeightGrams': r.totalWeightGrams,
      'cookingTime': r.cookingTime,
    }).toList();
    return jsonEncode(list);
  }

  Future<void> importRecipes(String jsonData) async {
    try {
      final List<dynamic> list = jsonDecode(jsonData);
      final existingRecipes = await DatabaseHelper.instance.getAllRecipes();
      final existingUrls = existingRecipes.map((r) => r.youtubeUrl).toSet();

      for (var item in list) {
        final String? url = item['youtubeUrl'];
        if (url != null && existingUrls.contains(url)) continue;

        final recipe = Recipe(
          dishName: item['dishName'] ?? "Imported Recipe",
          category: item['category'] ?? "General",
          ingredients: item['ingredients'] ?? "",
          recipe: item['recipe'] ?? "",
          youtubeUrl: url,
          youtubeTitle: item['youtubeTitle'],
          youtubeChannel: item['youtubeChannel'],
          thumbnailUrl: item['thumbnailUrl'],
          totalCalories: (item['totalCalories'] as num?)?.toDouble(),
          caloriesPer100g: (item['caloriesPer100g'] as num?)?.toDouble(),
          totalWeightGrams: (item['totalWeightGrams'] as num?)?.toDouble(),
          cookingTime: item['cookingTime'],
          importStatus: "Completed",
        );
        await DatabaseHelper.instance.insert(recipe);
      }
      await loadRecipes();
    } catch (e) {
      debugPrint("Invalid backup file: ${e.toString()}");
    }
  }

  Future<void> loadSamples() async {
    const samples = [
      {
        'dishName': 'Classic Bengali Aloo Bhaja',
        'category': 'Breakfast',
        'ingredients': 'Potatoes: 500g\nTurmeric: 1 tsp\nSalt: to taste\nMustard Oil: 3 tbsp',
        'recipe': '1. Cut potatoes into thin matchsticks.\n2. Heat oil in a pan.\n3. Fry until crispy and golden.',
        'totalCalories': 450.0,
        'caloriesPer100g': 90.0,
      },
      {
        'dishName': 'Decentralized Dal',
        'category': 'Lunch',
        'ingredients': 'Red Lentils: 200g\nWater: 600ml\nGhee: 1 tbsp\nCumin: 1 tsp',
        'recipe': '1. Boil lentils until soft.\n2. Temper with ghee and cumin.\n3. Serve hot with rice.',       
        'totalCalories': 320.0,
        'caloriesPer100g': 110.0,
      }
    ];
    await importRecipes(jsonEncode(samples));
  }

  Future<void> triggerMagicImport(String url) async {
    final timestamp = DateTime.now().toString().split('.').first;
    final placeholder = Recipe(
      dishName: "AI Magic Import: $timestamp",
      category: "Pending",
      ingredients: "",
      recipe: "",
      youtubeUrl: url,
      importStatus: "Placeholder Created",
    );


    await addRecipe(placeholder);
  }

  Future<void> autoProcessRecipe(Recipe recipe) async {
    if (recipe.importStatus == "Completed" || recipe.importStatus?.startsWith("Failed") == true) return;        

    try {
      if (recipe.importStatus == "Placeholder Created") {
        await _fetchMetadata(recipe);
        final updated = state.firstWhere((r) => r.id == recipe.id);
        await autoProcessRecipe(updated);
        return;
      }

      if (recipe.importStatus == "Metadata Fetched") {
        await _fetchTranscript(recipe);
        final updated = state.firstWhere((r) => r.id == recipe.id);
        await autoProcessRecipe(updated);
        return;
      }

      if (recipe.importStatus == "Transcript Fetched") {
        await _runGemini(recipe);
        return;
      }
    } catch (e) {
      debugPrint("Auto-process error: $e");
      await updateRecipe(recipe.copyWith(importStatus: "Failed: Auto-process"));
    }
  }

  Future<void> _fetchMetadata(Recipe recipe) async {
    await updateRecipe(recipe.copyWith(importStatus: "Fetching Metadata..."));
    final yt = YouTubeService();
    final result = await yt.fetchVideoMetadataOnly(recipe.youtubeUrl!);
    yt.close();

    if (result['success']) {
      await updateRecipe(recipe.copyWith(
        dishName: result['title'],
        youtubeTitle: result['title'],
        youtubeChannel: result['channel'],
        thumbnailUrl: result['thumbnail'],
        importStatus: "Metadata Fetched",
      ));
    } else {
      await updateRecipe(recipe.copyWith(importStatus: "Failed: Metadata"));
    }
  }

  Future<void> _fetchTranscript(Recipe recipe) async {
    await updateRecipe(recipe.copyWith(importStatus: "Fetching Transcript..."));
    final url = recipe.youtubeUrl!;
    final videoId = url.contains('v=') ? url.split('v=')[1].split('&')[0] : url.split('/').last;
    final isShort = url.contains('/shorts/');

    final yt = YouTubeService();
    final result = await yt.fetchTranscriptOnly(videoId, isShort: isShort);
    yt.close();

    if (result['success']) {
      await updateRecipe(recipe.copyWith(
        transcript: result['transcript'],
        durationSeconds: (result['durationSeconds'] as num?)?.toDouble(),
        segments: result['segments'] != null ? List<Map<String, dynamic>>.from(result['segments']) : null,
        importStatus: "Transcript Fetched",
        transcriptError: TranscriptFetchError.none,
      ));
    } else {
      final errorType = result['errorType'] ?? TranscriptFetchError.unknownError;
      await updateRecipe(recipe.copyWith(
        importStatus: "No transcript found",
        transcriptError: errorType,
      ));
    }
  }

  Future<void> _runGemini(Recipe recipe) async {
    final apiKey = ref.read(apiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      await updateRecipe(recipe.copyWith(importStatus: "Failed: Missing API Key"));
      return;
    }

    final transcript = recipe.transcript;
    if (transcript == null || transcript.isEmpty) {
      await updateRecipe(recipe.copyWith(importStatus: "Failed: No source text"));
      return;
    }

    final gemini = GeminiService(apiKey: apiKey);

    await updateRecipe(recipe.copyWith(importStatus: "Analyzing Language..."));
    final langCode = await gemini.detectLanguage(transcript);
    if (langCode != null && langCode != 'en') {
      await updateRecipe(recipe.copyWith(
        importStatus: "No transcript found",
        transcriptError: TranscriptFetchError.unsupportedLanguage,
        category: langCode,
      ));
      return;
    }

    await updateRecipe(recipe.copyWith(importStatus: "Validating Content..."));
    final validation = await gemini.validateContent(transcript);
    final valResult = validation['result'] as ValidationResult;
    
    if (valResult == ValidationResult.wrongDomain || valResult == ValidationResult.insufficientContent) {
      await updateRecipe(recipe.copyWith(
        importStatus: "No transcript found", 
        validationResult: valResult,
        flavorProfile: (validation['content_type'] as String?), 
      ));
      return;
    }

    final recipeWithVal = recipe.copyWith(validationResult: valResult);
    await updateRecipe(recipeWithVal);

    String finalInputText = transcript;
    if (recipeWithVal.videoLength == VideoLength.long && recipeWithVal.importStatus != "Processing Confirmed") {
      await updateRecipe(recipeWithVal.copyWith(importStatus: "Awaiting Confirmation (Long Video)"));
      return;
    }

    if (recipeWithVal.videoLength == VideoLength.medium || (recipeWithVal.videoLength == VideoLength.long && recipeWithVal.importStatus == "Processing Confirmed")) {
      await updateRecipe(recipeWithVal.copyWith(importStatus: "Summarizing Segments..."));
      final segments = recipeWithVal.segments;
      if (segments != null && segments.isNotEmpty) {
        List<String> summaries = [];
        String currentChunk = "";
        double chunkStartTime = (segments.first['start'] as num?)?.toDouble() ?? 0.0;

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

    await updateRecipe(recipeWithVal.copyWith(importStatus: "AI Processing..."));
    final result = await gemini.extractRecipeFromContent(
      title: recipeWithVal.youtubeTitle ?? recipeWithVal.dishName,
      channel: recipeWithVal.youtubeChannel ?? "Unknown",
      url: recipeWithVal.youtubeUrl!,
      thumbnail: recipeWithVal.thumbnailUrl,
      transcript: finalInputText,
    );

    if (result != null) {
      await updateRecipe(result.copyWith(
        id: recipeWithVal.id,
        importStatus: "Completed",
        validationResult: valResult, 
      ));
    } else {
      await updateRecipe(recipeWithVal.copyWith(importStatus: "Failed: Gemini"));
    }
  }

  Future<void> confirmLongVideoProcessing(Recipe recipe) async {
    await updateRecipe(recipe.copyWith(importStatus: "Processing Confirmed"));
    final updated = state.firstWhere((r) => r.id == recipe.id);
    _runGemini(updated);
  }
}

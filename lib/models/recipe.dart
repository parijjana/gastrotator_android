import 'validation_result.dart';
import 'video_length.dart';
import 'transcript_error.dart';

class Recipe {
  final int? id;
  final String dishName;
  final String category;
  final String ingredients;
  final String recipe;
  final String? youtubeUrl;
  final String? youtubeTitle;
  final String? youtubeChannel;
  final String? thumbnailUrl;
  final double? totalCalories;
  final double? caloriesPer100g;
  final double? totalWeightGrams;
  final String? cookingTime;
  final String? transcript;
  final String? importStatus;`n  final double? durationSeconds;`n  final List<Map<String, dynamic>>? segments;`n  final ValidationResult validationResult;
  final String? flavorProfile; 
  final double? rating;        
  final String? notes;
  final TranscriptFetchError transcriptError;

  Recipe({
    this.validationResult = ValidationResult.valid,
    this.transcriptError = TranscriptFetchError.none,
    this.id,
    required this.dishName,
    required this.category,
    required this.ingredients,
    required this.recipe,
    this.youtubeUrl,
    this.youtubeTitle,
    this.youtubeChannel,
    this.thumbnailUrl,
    this.totalCalories,
    this.caloriesPer100g,
    this.totalWeightGrams,
    this.cookingTime,
    this.transcript,
    this.importStatus,`n    this.durationSeconds,`n    this.segments,
    this.flavorProfile,
    this.rating,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dish_name': dishName,
      'category': category,
      'ingredients': ingredients,
      'recipe': recipe,
      'youtube_url': youtubeUrl,
      'youtube_title': youtubeTitle,
      'youtube_channel': youtubeChannel,
      'thumbnail_url': thumbnailUrl,
      'total_calories': totalCalories,
      'calories_per_100g': caloriesPer100g,
      'total_weight_grams': totalWeightGrams,
      'cooking_time': cookingTime,
      'transcript': transcript,
      'import_status': importStatus,
      'flavor_profile': flavorProfile,
      'rating': rating,
      'notes': notes,
      'transcript_error': transcriptError.name,
      'validation_result': validationResult.name,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      dishName: map['dish_name'],
      category: map['category'] ?? 'Uncategorized',
      ingredients: map['ingredients'] ?? '',
      recipe: map['recipe'] ?? '',
      youtubeUrl: map['youtube_url'],
      youtubeTitle: map['youtube_title'],
      youtubeChannel: map['youtube_channel'],
      thumbnailUrl: map['thumbnail_url'],
      totalCalories: map['total_calories']?.toDouble(),
      caloriesPer100g: map['calories_per_100g']?.toDouble(),
      totalWeightGrams: map['total_weight_grams']?.toDouble(),
      cookingTime: map['cooking_time'],
      transcript: map['transcript'],
      importStatus: map['import_status'],
      flavorProfile: map['flavor_profile'],
      rating: map['rating']?.toDouble(),
      notes: map['notes'],
      validationResult: ValidationResult.values.firstWhere((e) => e.name == (map['validation_result'] ?? 'valid'), orElse: () => ValidationResult.valid),
      transcriptError: TranscriptFetchError.values.firstWhere(
        (e) => e.name == (map['transcript_error'] ?? 'none'),
        orElse: () => TranscriptFetchError.none,
      ),
    );
  }

    VideoLength get videoLength {
    final ds = durationSeconds ?? 0.0;
    if (ds < 1200) return VideoLength.short;
    if (ds < 3600) return VideoLength.medium;
    return VideoLength.long;
  }

  static String getLanguageName(String code) {
    final map = {
      'en': 'English',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'ta': 'Tamil',
      'te': 'Telugu',
      'mr': 'Marathi',
      'gu': 'Gujarati',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'pa': 'Punjabi',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
    };
    return map[code.toLowerCase()] ?? code.toUpperCase();
  }

  Recipe copyWith({{
    int? id,
    String? dishName,
    String? category,
    String? ingredients,
    String? recipe,
    String? youtubeUrl,
    String? youtubeTitle,
    String? youtubeChannel,
    String? thumbnailUrl,
    double? totalCalories,
    double? caloriesPer100g,
    double? totalWeightGrams,
    String? cookingTime,
    String? transcript,
    String? importStatus,`n    double? durationSeconds,`n    List<Map<String, dynamic>>? segments,
    String? flavorProfile,
    double? rating,
    String? notes,
    TranscriptFetchError? transcriptError,`n    ValidationResult? validationResult,
  }) {
    return Recipe(
      id: id ?? this.id,
      dishName: dishName ?? this.dishName,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      recipe: recipe ?? this.recipe,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      youtubeTitle: youtubeTitle ?? this.youtubeTitle,
      youtubeChannel: youtubeChannel ?? this.youtubeChannel,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalCalories: totalCalories ?? this.totalCalories,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      totalWeightGrams: totalWeightGrams ?? this.totalWeightGrams,
      cookingTime: cookingTime ?? this.cookingTime,
      transcript: transcript ?? this.transcript,
      importStatus: importStatus ?? this.importStatus,`n      durationSeconds: durationSeconds ?? this.durationSeconds,`n      segments: segments ?? this.segments,`n    this.durationSeconds,`n    this.segments,
      flavorProfile: flavorProfile ?? this.flavorProfile,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      transcriptError: transcriptError ?? this.transcriptError,`n      validationResult: validationResult ?? this.validationResult,
    );
  }
}




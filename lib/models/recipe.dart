import 'transcript_error.dart';
import 'video_length.dart';
import 'validation_result.dart';

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
  final String? importStatus;
  final String? flavorProfile;
  final double? rating;
  final String? notes;
  final TranscriptFetchError transcriptError;
  final double? durationSeconds;
  final List<Map<String, dynamic>>? segments;
  final ValidationResult validationResult;
  final int? queuePosition;

  Recipe({
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
    this.importStatus,
    this.flavorProfile,
    this.rating,
    this.notes,
    this.transcriptError = TranscriptFetchError.none,
    this.durationSeconds,
    this.segments,
    this.validationResult = ValidationResult.valid,
    this.queuePosition,
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
      'queue_position': queuePosition,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      dishName: map['dish_name'] ?? 'Unknown Dish',
      category: map['category'] ?? 'Uncategorized',
      ingredients: map['ingredients'] ?? '',
      recipe: map['recipe'] ?? '',
      youtubeUrl: map['youtube_url'],
      youtubeTitle: map['youtube_title'],
      youtubeChannel: map['youtube_channel'],
      thumbnailUrl: map['thumbnail_url'],
      totalCalories: (map['total_calories'] as num?)?.toDouble(),
      caloriesPer100g: (map['calories_per_100g'] as num?)?.toDouble(),
      totalWeightGrams: (map['total_weight_grams'] as num?)?.toDouble(),
      cookingTime: map['cooking_time'],
      transcript: map['transcript'],
      importStatus: map['import_status'],
      flavorProfile: map['flavor_profile'],
      rating: (map['rating'] as num?)?.toDouble(),
      notes: map['notes'],
      transcriptError: TranscriptFetchError.values.firstWhere(
        (e) => e.name == (map['transcript_error'] ?? 'none'),
        orElse: () => TranscriptFetchError.none,
      ),
      validationResult: ValidationResult.values.firstWhere(
        (e) => e.name == (map['validation_result'] ?? 'valid'),
        orElse: () => ValidationResult.valid,
      ),
      queuePosition: map['queue_position'],
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

  Recipe copyWith({
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
    String? importStatus,
    String? flavorProfile,
    double? rating,
    String? notes,
    TranscriptFetchError? transcriptError,
    double? durationSeconds,
    List<Map<String, dynamic>>? segments,
    ValidationResult? validationResult,
    int? queuePosition,
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
      importStatus: importStatus ?? this.importStatus,
      flavorProfile: flavorProfile ?? this.flavorProfile,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      transcriptError: transcriptError ?? this.transcriptError,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      segments: segments ?? this.segments,
      validationResult: validationResult ?? this.validationResult,
      queuePosition: queuePosition ?? this.queuePosition,
    );
  }
}

enum ValidationResult {
  valid,
  foodAdjacent,
  wrongDomain,
  lowConfidence,
  insufficientContent;

  String userMessage(String? contentType) {
    switch (this) {
      case ValidationResult.foodAdjacent:
        return "This looks like food content but may not contain a full recipe. Results may be incomplete.";
      case ValidationResult.wrongDomain:
        return "This doesn't look like a cooking video (\). Please try a recipe or cooking tutorial video.";
      case ValidationResult.lowConfidence:
        return "We're not fully sure this is a recipe video. Results may not be accurate.";
      case ValidationResult.insufficientContent:
        return "The transcript is too short to extract a recipe from. The video may have auto-captions disabled or very little spoken content.";
      case ValidationResult.valid:
        return "";
    }
  }
}

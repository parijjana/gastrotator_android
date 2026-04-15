enum TranscriptFetchError {
  none,
  transcriptsDisabled,
  isShort,
  notAccessible,
  noEnglishTranscript,
  unsupportedLanguage,
  apiLimitReached,
  unknownError;

  String get userMessage {
    switch (this) {
      case TranscriptFetchError.apiLimitReached:
        return "You have reached the free AI limit. Please try again in a few minutes or tomorrow.";
      case TranscriptFetchError.transcriptsDisabled:
        return "This video's creator hasn't enabled captions. Try another video or paste the transcript manually.";
      case TranscriptFetchError.isShort:
        return "YouTube Shorts don't have transcripts. Try a full-length recipe video.";
      case TranscriptFetchError.notAccessible:
        return "there is no transcript associated with this video";
      case TranscriptFetchError.noEnglishTranscript:
        return "Only English transcripts are supported right now. Try a video with English captions.";
      case TranscriptFetchError.unsupportedLanguage:
        return "Unsupported Language"; // Handled dynamically in UI
      case TranscriptFetchError.unknownError:
        return "Couldn't fetch the transcript. Try again or paste it manually.";
      case TranscriptFetchError.none:
        return "";
    }
  }
}

enum TranscriptFetchError {
  none,
  transcriptsDisabled,
  isShort,
  notAccessible,
  noEnglishTranscript,
  unknownError;

  String get userMessage {
    switch (this) {
      case TranscriptFetchError.transcriptsDisabled:
        return "This video's creator hasn't enabled captions. Try another video or paste the transcript manually.";
      case TranscriptFetchError.isShort:
        return "YouTube Shorts don't have transcripts. Try a full-length recipe video.";
      case TranscriptFetchError.notAccessible:
        return "This video isn't publicly accessible.";
      case TranscriptFetchError.noEnglishTranscript:
        return "Only non-English transcripts were found. English-only is supported right now.";
      case TranscriptFetchError.unknownError:
        return "Couldn't fetch the transcript. Try again or paste it manually.";
      case TranscriptFetchError.none:
        return "";
    }
  }
}

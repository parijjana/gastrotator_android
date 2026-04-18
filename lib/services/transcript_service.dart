import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'package:youtube_transcript_api/youtube_transcript_api.dart';
import '../models/transcript_error.dart';

/// [SYSTEM INTEGRITY]: Dedicated service for robust transcript extraction.
/// Implements a multi-stage fetching strategy with fallbacks between specialized APIs.
class TranscriptService {
  final yt_explode.YoutubeExplode _yt;

  TranscriptService({yt_explode.YoutubeExplode? youtubeExplode})
      : _yt = youtubeExplode ?? yt_explode.YoutubeExplode();

  /// Fetches transcript for a given YouTube video ID.
  /// Uses [YouTubeTranscriptApi] as primary and [YouTubeExplode] as fallback.
  Future<Map<String, dynamic>> fetchTranscript(
    String videoId, {
    bool isShort = false,
  }) async {
    if (kIsWeb) {
      return {
        'success': true,
        'transcript': "This is a mock transcript for web testing.",
        'durationSeconds': 120.0,
        'segments': [],
      };
    }

    if (isShort) {
      return {
        'success': false,
        'errorType': TranscriptFetchError.isShort,
      };
    }

    // Phase 1: Try specialized YouTube Transcript API
    try {
      final result = await _fetchViaTranscriptApi(videoId);
      if (result['success']) return result;

      // HALT if we are specifically being rate limited
      if (result['errorType'] == TranscriptFetchError.apiLimitReached) {
        debugPrint("Rate limit detected in Phase 1. Halting.");
        return result;
      }
    } catch (e) {
      debugPrint("Transcript API Phase Error: $e");
    }

    // Phase 2: Fallback to YouTube Explode Closed Captions
    debugPrint("Transcript API failed, falling back to YouTube Explode...");
    try {
      final result = await _fetchViaYoutubeExplode(videoId);
      return result;
    } catch (e) {
      debugPrint("YouTube Explode Phase Error: $e");
      return {
        'success': false,
        'errorType': TranscriptFetchError.unknownError,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _fetchViaTranscriptApi(String videoId) async {
    final transcriptApi = YouTubeTranscriptApi();
    try {
      // Primary: English
      try {
        final fetchedTranscript =
            await transcriptApi.fetch(videoId, languages: ['en']);
        return _processTranscriptApiData(fetchedTranscript);
      } catch (e) {
        // Check for rate limit specifically in the first catch
        if (e.toString().contains('429')) {
          return {
            'success': false,
            'errorType': TranscriptFetchError.apiLimitReached,
            'error': e.toString(),
          };
        }

        // Secondary: List and find English (manual or auto)
        final transcriptList = await transcriptApi.list(videoId);
        final firstTranscript = transcriptList.findTranscript(['en']);
        final data = await firstTranscript.fetch();
        return _processTranscriptApiData(data);
      }
    } catch (e) {
      String errStr = e.toString().toLowerCase();
      TranscriptFetchError errorType = TranscriptFetchError.unknownError;

      if (errStr.contains('429')) {
        errorType = TranscriptFetchError.apiLimitReached;
      } else if (errStr.contains('disabled') || errStr.contains('not enabled')) {
        errorType = TranscriptFetchError.transcriptsDisabled;
      } else if (errStr.contains('private') ||
          errStr.contains('accessible') ||
          errStr.contains('age')) {
        errorType = TranscriptFetchError.notAccessible;
      } else if (errStr.contains('no transcript') ||
          errStr.contains('not found')) {
        errorType = TranscriptFetchError.noEnglishTranscript;
      }

      return {
        'success': false,
        'errorType': errorType,
        'error': e.toString(),
      };
    } finally {
      transcriptApi.dispose();
    }
  }

  Future<Map<String, dynamic>> _fetchViaYoutubeExplode(String videoId) async {
    try {
      final manifest = await _yt.videos.closedCaptions.getManifest(videoId);
      if (manifest.tracks.isEmpty) {
        return {
          'success': false,
          'errorType': TranscriptFetchError.transcriptsDisabled,
          'error': "No closed caption tracks found in manifest.",
        };
      }

      // Try to find English, otherwise take the first available
      final track = manifest.tracks
              .where((t) => t.language.code == 'en')
              .firstOrNull ??
          manifest.tracks.first;
      final closedCaptionTrack = await _yt.videos.closedCaptions.get(track);

      if (closedCaptionTrack.captions.isEmpty) {
        return {
          'success': false,
          'errorType': TranscriptFetchError.notAccessible,
          'error': "Caption track is empty.",
        };
      }

      final fullText = closedCaptionTrack.captions.map((c) => c.text).join(' ');
      final duration = closedCaptionTrack.captions.last.offset.inSeconds.toDouble();

      return {
        'success': true,
        'transcript': fullText,
        'durationSeconds': duration,
        'segments': closedCaptionTrack.captions
            .map(
              (c) => {
                'text': c.text,
                'start': c.offset.inMilliseconds / 1000.0,
                'duration': c.duration.inMilliseconds / 1000.0,
              },
            )
            .toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'errorType': TranscriptFetchError.unknownError,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _processTranscriptApiData(dynamic data) {
    final snippets = data.snippets;
    if (snippets.isEmpty) {
      return {
        'success': false,
        'errorType': TranscriptFetchError.noEnglishTranscript,
      };
    }

    final fullText = snippets.map((s) => s.text).join(' ');
    final start = (snippets.first.start as num?)?.toDouble() ?? 0.0;
    final end = (snippets.last.start as num?)?.toDouble() ?? 0.0;
    final durationSeconds = end - start;

    return {
      'success': true,
      'transcript': fullText,
      'durationSeconds': durationSeconds,
      'segments': snippets
          .map(
            (s) => {
              'text': s.text,
              'start': (s.start as num?)?.toDouble(),
              'duration': (s.duration as num?)?.toDouble(),
            },
          )
          .toList(),
    };
  }

  void close() {
    _yt.close();
  }
}

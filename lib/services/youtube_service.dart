import '../models/transcript_error.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'package:youtube_transcript_api/youtube_transcript_api.dart';

class YouTubeService {
  final yt_explode.YoutubeExplode _yt = yt_explode.YoutubeExplode();

  Future<Map<String, dynamic>> fetchVideoMetadataOnly(String url) async {
    try {
      final video = await _yt.videos.get(url);
      return {
        'success': true,
        'title': video.title,
        'channel': video.author,
        'description': video.description,
        'videoId': video.id.value,
        'thumbnail': video.thumbnails.mediumResUrl,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> fetchTranscriptOnly(String videoId, {bool isShort = false}) async {
    if (isShort) {
      return {
        'success': false,
        'errorType': TranscriptFetchError.isShort,
      };
    }

    final transcriptApi = YouTubeTranscriptApi();
    try {
      // Try English first
      final fetchedTranscript = await transcriptApi.fetch(videoId, languages: ['en']);
      final transcriptText = fetchedTranscript.snippets.map((s) => s.text).join(' ');
      return {
        'success': true,
        'transcript': transcriptText,
      };
    } catch (e) {
      // Fallback to searching all transcripts
      try {
        final transcriptList = await transcriptApi.list(videoId);
        final firstTranscript = transcriptList.findTranscript(['en']);
        final data = await firstTranscript.fetch();
        final transcriptText = data.snippets.map((s) => s.text).join(' ');
        return {
          'success': true,
          'transcript': transcriptText,
        };
      } catch (e2) {
        TranscriptFetchError errorType = TranscriptFetchError.unknownError;
        String errStr = e2.toString().toLowerCase();

        if (errStr.contains('disabled') || errStr.contains('not enabled')) {
          errorType = TranscriptFetchError.transcriptsDisabled;
        } else if (errStr.contains('private') || errStr.contains('accessible') || errStr.contains('age')) {
          errorType = TranscriptFetchError.notAccessible;
        } else if (errStr.contains('no transcript') || errStr.contains('not found')) {
          errorType = TranscriptFetchError.noEnglishTranscript;
        }

        return {
          'success': false,
          'errorType': errorType,
          'error': e2.toString(),
        };
      }
    } finally {
      transcriptApi.dispose();
    }
  }

  Future<Map<String, dynamic>> fetchVideoDetailsAndTranscript(String url) async {
    try {
      final meta = await fetchVideoMetadataOnly(url);
      if (!meta['success']) return meta;

      final isShort = url.contains('/shorts/');
      final transcriptData = await fetchTranscriptOnly(meta['videoId'], isShort: isShort);

      return {
        ...meta,
        'transcript': transcriptData['transcript'] ?? "",
        'transcript_success': transcriptData['success'] == true,
        'transcript_error_type': transcriptData['errorType'],
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  void close() {
    _yt.close();
  }
}

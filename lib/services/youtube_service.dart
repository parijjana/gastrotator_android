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

  Future<Map<String, dynamic>> fetchTranscriptOnly(String videoId) async {
    final transcriptApi = YouTubeTranscriptApi();
    try {
      // Try English first
      final fetchedTranscript = await transcriptApi.fetch(
        videoId,
        languages: ['en'],
      );
      
      final transcriptText = fetchedTranscript.snippets.map((s) => s.text).join(' ');
      return {
        'success': true,
        'transcript': transcriptText,
      };
    } catch (e) {
      // Fallback to auto-generated
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
        return {
          'success': false,
          'error': 'Transcript fetch failed: $e2',
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

      final transcriptData = await fetchTranscriptOnly(meta['videoId']);
      
      return {
        ...meta,
        'transcript': transcriptData['transcript'] ?? "",
        'transcript_success': transcriptData['success'] == true,
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

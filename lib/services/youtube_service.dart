import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'transcript_service.dart';

class YouTubeService {
  final yt_explode.YoutubeExplode _yt = yt_explode.YoutubeExplode();
  final TranscriptService _transcriptService = TranscriptService();

  Future<Map<String, dynamic>> fetchVideoMetadataOnly(String url) async {
    if (kIsWeb) {
      return {
        'success': true,
        'title': "Web Mock: Video Title",
        'channel': "Web Mock: Channel",
        'description': "Web Mock: Description",
        'videoId': "mock_id",
        'thumbnail': "https://picsum.photos/200",
      };
    }
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
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchTranscriptOnly(
    String videoId, {
    bool isShort = false,
  }) async {
    return await _transcriptService.fetchTranscript(videoId, isShort: isShort);
  }

  Future<Map<String, dynamic>> fetchVideoDetailsAndTranscript(
    String url,
  ) async {
    try {
      final meta = await fetchVideoMetadataOnly(url);
      if (!meta['success']) return meta;

      final isShort = url.contains('/shorts/');
      final transcriptData = await fetchTranscriptOnly(
        meta['videoId'],
        isShort: isShort,
      );

      return {
        ...meta,
        'transcript': transcriptData['transcript'] ?? "",
        'transcript_success': transcriptData['success'] == true,
        'durationSeconds': transcriptData['durationSeconds'],
        'segments': transcriptData['segments'],
        'errorType': transcriptData['errorType'],
        'success': true,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  void close() {
    if (!kIsWeb) {
      _yt.close();
      _transcriptService.close();
    }
  }
}


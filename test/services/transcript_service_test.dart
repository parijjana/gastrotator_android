import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/services/transcript_service.dart';
import 'package:android_app/models/transcript_error.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;

class MockYoutubeExplode extends Mock implements yt_explode.YoutubeExplode {}
class MockVideoClient extends Mock implements yt_explode.VideoClient {}
class MockClosedCaptionClient extends Mock implements yt_explode.ClosedCaptionClient {}

void main() {
  group('TranscriptService Fallback Tests', () {
    late MockYoutubeExplode mockYt;
    late MockVideoClient mockVideoClient;
    late MockClosedCaptionClient mockCcClient;

    setUp(() {
      mockYt = MockYoutubeExplode();
      mockVideoClient = MockVideoClient();
      mockCcClient = MockClosedCaptionClient();
      
      when(() => mockYt.videos).thenReturn(mockVideoClient);
      when(() => mockVideoClient.closedCaptions).thenReturn(mockCcClient);
    });

    test('fetchTranscript should fallback to YouTube Explode if primary fails', () async {
      // 1. Primary (YouTubeTranscriptApi) is hard to mock without refactor, 
      // but we can test the fallback method directly or the full flow if it fails naturally.
      
      // For now, let's test the Phase 2 method specifically to ensure logic is correct
      final service = TranscriptService(youtubeExplode: mockYt);
      
      // Mock CC Manifest to be empty (trigger failure)
      when(() => mockCcClient.getManifest(any())).thenAnswer((_) async => yt_explode.ClosedCaptionManifest([]));
      
      final result = await service.fetchTranscript('test_id');
      expect(result['success'], false);
      expect(result['errorType'], TranscriptFetchError.transcriptsDisabled);
    });
  });
}

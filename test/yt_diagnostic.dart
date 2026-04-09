import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';

void main() async {
  final yt = YoutubeExplode();
  const videoUrl = 'https://www.youtube.com/watch?v=3iNyUwPKrXQ';
  
  print('--- YouTube Diagnostic Start ---');
  print('Target URL: $videoUrl');

  try {
    print('\n1. Fetching Video Metadata...');
    final video = await yt.videos.get(videoUrl);
    print('Title: ${video.title}');
    print('Author: ${video.author}');
    print('Description Length: ${video.description.length}');

    print('\n2. Fetching Closed Caption Manifest...');
    try {
      final manifest = await yt.videos.closedCaptions.getManifest(video.id);
      print('Manifest Tracks Found: ${manifest.tracks.length}');
      
      if (manifest.tracks.isNotEmpty) {
        for (var track in manifest.tracks) {
          print(' - ${track.language.name} (${track.language.code})');
        }
        
        print('\n3. Attempting to fetch first track content...');
        final track = await yt.videos.closedCaptions.get(manifest.tracks.first);
        print('Captions count: ${track.captions.length}');
        print('Sample: ${track.captions.first.text}');
      } else {
        print('No caption tracks found.');
      }
    } catch (e) {
      print('\n!!! CAPTION MANIFEST FAILURE !!!');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      
      if (e.toString().contains('XmlParserException')) {
        print('\nANALYSIS: "Expected a single root element at 1:1" usually indicates that');
        print('the server returned an HTML error page (like a 404, 403, or bot check)');
        print('instead of the expected XML data structure.');
      }
    }

  } catch (e) {
    print('General Error: $e');
  } finally {
    yt.close();
    print('\n--- Diagnostic End ---');
    exit(0);
  }
}

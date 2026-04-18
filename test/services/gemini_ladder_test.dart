import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/services/gemini_service.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
class MockHttpClient extends Mock implements http.Client {}
// GenerativeModel is final, we should mock the service or use a wrapper if we wanted to mock the model itself.
// For ladder tests, we are mocking the HTTP responses for discovery.

void main() {
  group('GeminiService Ladder & Resiliency Tests', () {
    late MockHttpClient mockHttp;
    const apiKey = 'test-api-key';

    setUp(() {
      mockHttp = MockHttpClient();
      registerFallbackValue(Uri());
    });

    test('discoverAndRankModels should filter and rank correctly', () async {
      final mockResponse = {
        'models': [
          {'name': 'models/gemini-1.5-pro', 'supportedGenerationMethods': ['generateContent']},
          {'name': 'models/gemini-1.5-flash', 'supportedGenerationMethods': ['generateContent']},
          {'name': 'models/gemini-2.0-flash-exp', 'supportedGenerationMethods': ['generateContent']}, // Experimental
          {'name': 'models/gemma-2b', 'supportedGenerationMethods': ['generateContent']},
          {'name': 'models/embedding-001', 'supportedGenerationMethods': ['embedContent']}, // Wrong method
        ]
      };

      when(() => mockHttp.get(any())).thenAnswer(
        (_) async => http.Response(json.encode(mockResponse), 200),
      );

      final service = GeminiService(apiKey: apiKey, httpClient: mockHttp);
      final ladder = await service.discoverAndRankModels();

      // Should contain: gemini-1.5-flash, gemini-1.5-pro, gemma-2b
      // Ranked: Flash families first, then Gemma, then others
      expect(ladder.first, contains('flash'));
      expect(ladder.any((m) => m.contains('gemma')), true);
      expect(ladder.any((m) => m.contains('exp')), false);
    });

    test('Should prioritize lastSuccessfulModel', () async {
      final mockResponse = {
        'models': [
          {'name': 'models/gemini-pro', 'supportedGenerationMethods': ['generateContent']},
          {'name': 'models/gemini-flash', 'supportedGenerationMethods': ['generateContent']},
        ]
      };

      when(() => mockHttp.get(any())).thenAnswer(
        (_) async => http.Response(json.encode(mockResponse), 200),
      );

      final service = GeminiService(
        apiKey: apiKey, 
        httpClient: mockHttp,
        lastSuccessfulModel: 'gemini-pro',
      );
      
      final ladder = await service.discoverAndRankModels();
      expect(ladder.first, 'gemini-pro');
    });

    test('Should handle API discovery failure with fallback', () async {
      when(() => mockHttp.get(any())).thenAnswer(
        (_) async => http.Response('Error', 500),
      );

      final service = GeminiService(apiKey: apiKey, httpClient: mockHttp);
      final ladder = await service.discoverAndRankModels();
      
      expect(ladder, ['gemini-flash-latest']);
    });
  });
}

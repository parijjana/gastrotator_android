import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/services/ai/remote_gemini_engine.dart';
import 'package:android_app/services/rate_limit_dispatcher.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockRateLimitDispatcher extends Mock implements RateLimitDispatcher {}

void main() {
  group('RemoteGeminiEngine Ladder & Resiliency Tests', () {
    late MockHttpClient mockHttp;
    late MockRateLimitDispatcher mockDispatcher;
    const apiKey = 'test-api-key';

    setUp(() {
      mockHttp = MockHttpClient();
      mockDispatcher = MockRateLimitDispatcher();
      registerFallbackValue(Uri());
      registerFallbackValue(ApiType.gemini);

      // Default behavior for mock dispatcher: pass-through
      when(() => mockDispatcher.dispatch<http.Response>(
        type: any(named: 'type'),
        description: any(named: 'description'),
        contextId: any(named: 'contextId'),
        task: any(named: 'task'),
      )).thenAnswer((invocation) async {
        final task = invocation.namedArguments[Symbol('task')] as Future<http.Response> Function();
        return await task();
      });
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

      final service = RemoteGeminiEngine(apiKey: apiKey, httpClient: mockHttp, dispatcher: mockDispatcher);
      final ladder = await service.discoverAndRankModels();

      // Should contain: gemini-1.5-flash, gemini-1.5-pro, gemma-2b
      // Ranked: Flash families first, then Gemma, then others
      expect(ladder.first, contains('flash'));
      expect(ladder.any((m) => m.contains('pro')), true);
      expect(ladder.any((m) => m.contains('gemma')), true);
      expect(ladder.any((m) => m.contains('exp')), false);
      expect(ladder.any((m) => m.contains('embedding')), false);
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

      final service = RemoteGeminiEngine(
        apiKey: apiKey, 
        httpClient: mockHttp,
        dispatcher: mockDispatcher,
        lastSuccessfulModel: 'gemini-pro',
      );
      
      final ladder = await service.discoverAndRankModels();
      expect(ladder.first, 'gemini-pro');
    });

    test('Should handle API discovery failure with fallback', () async {
      when(() => mockHttp.get(any())).thenAnswer(
        (_) async => http.Response('Error', 500),
      );

      final service = RemoteGeminiEngine(apiKey: apiKey, httpClient: mockHttp, dispatcher: mockDispatcher);
      final ladder = await service.discoverAndRankModels();
      
      expect(ladder, ['gemini-flash-latest']);
    });
  });
}

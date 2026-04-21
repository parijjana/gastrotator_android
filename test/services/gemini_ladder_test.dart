import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/services/gemini_service.dart';
import 'package:android_app/providers/providers.dart';
import 'package:android_app/services/rate_limit_dispatcher.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockHttpClient extends Mock implements http.Client {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockRateLimitDispatcher extends Mock implements RateLimitDispatcher {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GeminiService Ladder & Persistence Tests', () {
    late MockHttpClient mockHttp;
    late MockSecureStorage mockStorage;
    late MockRateLimitDispatcher mockDispatcher;
    const apiKey = 'test-api-key';

    setUp(() {
      mockHttp = MockHttpClient();
      mockStorage = MockSecureStorage();
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

    test('Eager Load: LastSuccessfulModelNotifier should load from disk on startup', () async {
      when(() => mockStorage.read(key: 'last_successful_model'))
          .thenAnswer((_) async => 'gemini-1.5-pro');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWith((ref) => mockStorage),
        ],
      );
      addTearDown(container.dispose);

      // Trigger build
      container.read(lastSuccessfulModelProvider);
      
      // Give async load time
      await Future.delayed(Duration.zero);
      
      expect(container.read(lastSuccessfulModelProvider), 'gemini-1.5-pro');
    });

    test('discoverAndRankModels should filter and rank correctly', () async {
      final mockResponse = {
        'models': [
          {'name': 'models/gemini-1.5-pro', 'supportedGenerationMethods': ['generateContent']},
          {'name': 'models/gemini-1.5-flash', 'supportedGenerationMethods': ['generateContent']},
          {'name': 'models/gemini-2.0-flash-exp', 'supportedGenerationMethods': ['generateContent']},
          {'name': 'models/gemma-2b', 'supportedGenerationMethods': ['generateContent']},
        ]
      };

      when(() => mockHttp.get(any())).thenAnswer(
        (_) async => http.Response(json.encode(mockResponse), 200),
      );

      final service = GeminiService(apiKey: apiKey, httpClient: mockHttp, dispatcher: mockDispatcher);
      final ladder = await service.discoverAndRankModels();

      expect(ladder.first, contains('flash'));
      expect(ladder.any((m) => m.contains('pro')), true);
      expect(ladder.any((m) => m.contains('gemma')), true);
      expect(ladder.any((m) => m.contains('exp')), false);
    });

    test('Should prioritize lastSuccessfulModel in discovery', () async {
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
        dispatcher: mockDispatcher,
        lastSuccessfulModel: 'gemini-pro',
      );
      
      final ladder = await service.discoverAndRankModels();
      expect(ladder.first, 'gemini-pro');
    });
  });
}

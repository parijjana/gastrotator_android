import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/providers/providers.dart';
import 'package:android_app/models/recipe.dart';
import 'package:android_app/models/validation_result.dart';
import 'package:android_app/data/database_helper.dart';
import 'package:android_app/services/youtube_service.dart';
import 'package:android_app/services/gemini_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockYouTubeService extends Mock implements YouTubeService {}
class MockGeminiService extends Mock implements GeminiService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockApiKeyNotifier extends ApiKeyNotifier {
  @override
  Future<String?> build() async => 'test-api-key';
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setTestMode(enabled: true);
    registerFallbackValue(Recipe(dishName: '', category: '', ingredients: '', recipe: ''));
  });

  group('Worker Lifecycle Tests', () {
    late MockSecureStorage mockStorage;
    late MockYouTubeService mockYT;
    late MockGeminiService mockGemini;
    late MockDatabaseHelper mockDB;
    late ProviderContainer container;
    late List<Recipe> stateList;

    setUp(() async {
      mockStorage = MockSecureStorage();
      mockYT = MockYouTubeService();
      mockGemini = MockGeminiService();
      mockDB = MockDatabaseHelper();
      stateList = [];

      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => {});

      // Mock DB logic to update our local stateList
      when(() => mockDB.getAllRecipes()).thenAnswer((_) async => stateList);
      when(() => mockDB.insert(any())).thenAnswer((inv) async {
        final r = inv.positionalArguments[0] as Recipe;
        final newR = r.copyWith(id: stateList.length + 1);
        stateList.add(newR);
        return newR.id!;
      });
      when(() => mockDB.update(any())).thenAnswer((inv) async {
        final r = inv.positionalArguments[0] as Recipe;
        final idx = stateList.indexWhere((existing) => existing.id == r.id);
        if (idx != -1) stateList[idx] = r;
        return 1;
      });

      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWith((ref) => mockStorage),
          apiKeyProvider.overrideWith(() => MockApiKeyNotifier()),
          youTubeServiceProvider.overrideWith((ref) => mockYT),
          geminiServiceProvider.overrideWith((ref, contextId) => mockGemini),
          databaseHelperProvider.overrideWith((ref) => mockDB),
          workerEnabledProvider.overrideWith((ref) => true),
        ],
      );
    });

    test('Full Lifecycle: Metadata -> Transcript -> Gemini -> Completed', () async {
      const testUrl = 'https://www.youtube.com/watch?v=12345678901';

      // 1. Mock Metadata
      when(() => mockYT.fetchVideoMetadataOnly(testUrl)).thenAnswer((_) async => {
        'success': true,
        'title': 'AI Pizza',
        'channel': 'Test Chef',
        'thumbnail': 'https://test.com/thumb.jpg',
      });

      // 2. Mock Transcript
      when(() => mockYT.fetchTranscriptOnly(any(), isShort: any(named: 'isShort'))).thenAnswer((_) async => {
        'success': true,
        'transcript': 'Bake at 400F.',
        'durationSeconds': 60.0,
      });

      // 3. Mock Gemini
      when(() => mockGemini.detectLanguage(any())).thenAnswer((_) async => 'en');
      when(() => mockGemini.validateContent(any())).thenAnswer((_) async => {'result': ValidationResult.valid});
      when(() => mockGemini.extractRecipeFromContent(
        title: any(named: 'title'),
        channel: any(named: 'channel'),
        url: any(named: 'url'),
        thumbnail: any(named: 'thumbnail'),
        transcript: any(named: 'transcript'),
      )).thenAnswer((_) async => Recipe(
        dishName: 'AI Extracted Pizza',
        category: 'Dinner',
        ingredients: 'Flour, Water',
        recipe: '1. Mix. 2. Bake.',
        youtubeUrl: testUrl,
      ));

      await container.read(recipesProvider.notifier).triggerMagicImport(testUrl);
      
      bool completed = false;
      for (int i = 0; i < 40; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (stateList.isNotEmpty && stateList.any((r) => r.importStatus == 'Completed')) {
          completed = true;
          break;
        }
      }

      expect(completed, true, reason: 'Worker should complete import flow within timeout');
      final finalRecipe = stateList.firstWhere((r) => r.importStatus == 'Completed');
      expect(finalRecipe.dishName, 'AI Extracted Pizza');
    });

    test('Should handle Transcript Failure gracefully', () async {
      const testUrl = 'https://www.youtube.com/watch?v=FAIL1234567';
      
      when(() => mockYT.fetchVideoMetadataOnly(testUrl)).thenAnswer((_) async => {
        'success': true,
        'title': 'Failing Recipe',
      });

      when(() => mockYT.fetchTranscriptOnly(any(), isShort: any(named: 'isShort'))).thenAnswer((_) async => {
        'success': false,
        'error': 'No Transcript Found',
      });

      await container.read(recipesProvider.notifier).triggerMagicImport(testUrl);
      
      bool failed = false;
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (stateList.isNotEmpty && stateList.any((r) => r.importStatus == 'No transcript found')) {
          failed = true;
          break;
        }
      }

      expect(failed, true);
    });
  });
}

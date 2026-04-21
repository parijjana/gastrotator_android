import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/providers/providers.dart';
import 'package:android_app/models/recipe.dart';
import 'package:android_app/data/database_helper.dart';
import 'package:android_app/services/youtube_service.dart';
import 'package:android_app/services/rate_limit_dispatcher.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockYouTubeService extends Mock implements YouTubeService {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockRateLimitDispatcher extends Mock implements RateLimitDispatcher {}

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

  group('RecipesNotifier FIFO & Manual Control Tests', () {
    late MockSecureStorage mockStorage;
    late MockYouTubeService mockYT;
    late MockDatabaseHelper mockDB;
    late MockRateLimitDispatcher mockDispatcher;
    late ProviderContainer container;
    late List<Recipe> mockDbState;

    setUp(() async {
      mockStorage = MockSecureStorage();
      mockYT = MockYouTubeService();
      mockDB = MockDatabaseHelper();
      mockDispatcher = MockRateLimitDispatcher();
      mockDbState = [];

      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => {});
      
      // Stop worker from doing anything
      when(() => mockYT.fetchVideoMetadataOnly(any())).thenAnswer((_) => Completer<Map<String, dynamic>>().future);

      when(() => mockDB.getAllRecipes()).thenAnswer((_) async => mockDbState);
      when(() => mockDB.insert(any())).thenAnswer((inv) async {
        final r = inv.positionalArguments[0] as Recipe;
        final newR = r.copyWith(id: mockDbState.length + 1);
        mockDbState.add(newR);
        return newR.id!;
      });
      when(() => mockDB.update(any())).thenAnswer((inv) async {
        final r = inv.positionalArguments[0] as Recipe;
        final idx = mockDbState.indexWhere((existing) => existing.id == r.id);
        if (idx != -1) mockDbState[idx] = r;
        return 1;
      });

      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWith((ref) => mockStorage),
          apiKeyProvider.overrideWith(() => MockApiKeyNotifier()),
          youTubeServiceProvider.overrideWith((ref) => mockYT),
          databaseHelperProvider.overrideWith((ref) => mockDB),
          rateLimitDispatcherProvider.overrideWith((ref) => mockDispatcher),
          workerEnabledProvider.overrideWith((ref) => false),
        ],
      );

      await container.read(recipesProvider.notifier).loadRecipes();
    });

    test('First import should start as In Queue, second as Paused (FIFO)', () async {
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=ABC12345678');
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=XYZ09876543');
      
      final recipes = container.read(recipesProvider);
      expect(recipes.firstWhere((r) => r.youtubeUrl!.contains('ABC12345678')).importStatus, 'In Queue');
      expect(recipes.firstWhere((r) => r.youtubeUrl!.contains('XYZ09876543')).importStatus, 'Paused');
    });

    test('pauseExtraction should update status to Paused', () async {
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=ABC12345678');
      final id = container.read(recipesProvider).first.id!;
      
      await container.read(recipesProvider.notifier).pauseExtraction(id);
      expect(container.read(recipesProvider).first.importStatus, 'Paused');
    });

    test('resumeExtraction should throw error if pipeline is busy', () async {
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=ABC12345678');
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=XYZ09876543');
      final pausedId = container.read(recipesProvider).firstWhere((r) => r.importStatus == 'Paused').id!;

      expect(
        () => container.read(recipesProvider.notifier).resumeExtraction(pausedId),
        throwsA(contains('Extraction pipeline in use')),
      );
    });

    test('resumeExtraction should succeed and clear Global Halt', () async {
      container.read(globalHaltProvider.notifier).set(true);
      
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=ABC12345678');
      final id = container.read(recipesProvider).first.id!;
      await container.read(recipesProvider.notifier).pauseExtraction(id);

      await container.read(recipesProvider.notifier).resumeExtraction(id);
      
      expect(container.read(recipesProvider).first.importStatus, 'In Queue');
      expect(container.read(globalHaltProvider), false);
    });
   group('getRelativePosition - Not Used but kept for legacy check', () {
      // Actually we removed getRelativePosition in the FIFO refactor because it was complex.
      // But if we want to add a test for it, we should re-implement it or just skip.
    });
  });
}

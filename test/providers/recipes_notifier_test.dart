import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/providers/providers.dart';
import 'package:android_app/models/recipe.dart';
import 'package:android_app/data/database_helper.dart';
import 'package:android_app/services/youtube_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockYouTubeService extends Mock implements YouTubeService {}
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

  group('RecipesNotifier Expanded Logic Tests', () {
    late MockSecureStorage mockStorage;
    late MockYouTubeService mockYT;
    late MockDatabaseHelper mockDB;
    late ProviderContainer container;
    late List<Recipe> mockDbState;
    late Completer<Map<String, dynamic>> metadataCompleter;

    setUp(() async {
      mockStorage = MockSecureStorage();
      mockYT = MockYouTubeService();
      mockDB = MockDatabaseHelper();
      mockDbState = [];
      metadataCompleter = Completer();

      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => {});
      
      // Hold the worker at the first metadata fetch to keep queue stable
      when(() => mockYT.fetchVideoMetadataOnly(any())).thenAnswer((_) => metadataCompleter.future);

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
          workerEnabledProvider.overrideWith((ref) => false),
        ],
      );

      await container.read(recipesProvider.notifier).loadRecipes();
    });

    test('triggerMagicImport should add a placeholder recipe with In Queue status', () async {
      const testUrl = 'https://www.youtube.com/watch?v=12345678901';
      await container.read(recipesProvider.notifier).triggerMagicImport(testUrl);

      final recipes = container.read(recipesProvider);
      final recipe = recipes.firstWhere((r) => r.youtubeUrl == testUrl);
      expect(recipe.importStatus, 'In Queue');
    });

    test('triggerMagicImport should throw error and trigger shake on duplicate', () async {
      const testUrl = 'https://www.youtube.com/watch?v=12345678901';
      
      await container.read(recipesProvider.notifier).triggerMagicImport(testUrl);
      final firstId = container.read(recipesProvider).first.id;

      const duplicateUrl = 'https://youtu.be/12345678901';
      
      expect(
        () => container.read(recipesProvider.notifier).triggerMagicImport(duplicateUrl),
        throwsA(contains('Duplicate Recipe')),
      );

      expect(container.read(recipesProvider.notifier).pendingShakeId, firstId);
    });

    test('getRelativePosition should return correct queue position for items in queue', () async {
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=AAAAA111111');
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=BBBBB222222');
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=CCCCC333333');
      
      await container.read(recipesProvider.notifier).loadRecipes();
      final recipes = container.read(recipesProvider);
      
      final id1 = recipes.firstWhere((r) => r.youtubeUrl!.contains('AAAAA')).id!;
      final id2 = recipes.firstWhere((r) => r.youtubeUrl!.contains('BBBBB')).id!;
      final id3 = recipes.firstWhere((r) => r.youtubeUrl!.contains('CCCCC')).id!;

      expect(container.read(recipesProvider.notifier).getRelativePosition(id1), 1);
      expect(container.read(recipesProvider.notifier).getRelativePosition(id2), 2);
      expect(container.read(recipesProvider.notifier).getRelativePosition(id3), 3);
    });

    test('processRecipeImmediately should move recipe to front of queue', () async {
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=AAAAA111111');
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=BBBBB222222');
      await container.read(recipesProvider.notifier).triggerMagicImport('https://www.youtube.com/watch?v=CCCCC333333');
      
      await container.read(recipesProvider.notifier).loadRecipes();
      final recipes = container.read(recipesProvider);
      final id3 = recipes.firstWhere((r) => r.youtubeUrl!.contains('CCCCC')).id!;

      // Act: Move CCCC to front
      await container.read(recipesProvider.notifier).processRecipeImmediately(id3);
      await container.read(recipesProvider.notifier).loadRecipes();

      expect(container.read(recipesProvider.notifier).getRelativePosition(id3), 1);
    });
  });
}

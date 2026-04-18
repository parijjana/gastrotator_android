import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/providers/providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ApiKeyNotifier Logic Tests', () {
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
    });

    test('build should load key from storage', () async {
      when(() => mockStorage.read(key: 'gemini_api_key'))
          .thenAnswer((_) async => 'stored-key');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWith((ref) => mockStorage),
        ],
      );
      addTearDown(container.dispose);

      final key = await container.read(apiKeyProvider.future);
      expect(key, 'stored-key');
    });

    test('saveKey should trim and persist key', () async {
      when(() => mockStorage.write(key: 'gemini_api_key', value: 'new-key'))
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWith((ref) => mockStorage),
        ],
      );
      addTearDown(container.dispose);

      await container.read(apiKeyProvider.notifier).saveKey('  new-key  ');
      
      final key = container.read(apiKeyProvider).value;
      expect(key, 'new-key');
      verify(() => mockStorage.write(key: 'gemini_api_key', value: 'new-key')).called(1);
    });

    test('deleteKey should remove from storage and state', () async {
      when(() => mockStorage.delete(key: 'gemini_api_key'))
          .thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWith((ref) => mockStorage),
        ],
      );
      addTearDown(container.dispose);

      await container.read(apiKeyProvider.notifier).deleteKey();
      
      expect(container.read(apiKeyProvider).value, isNull);
      verify(() => mockStorage.delete(key: 'gemini_api_key')).called(1);
    });
  });
}

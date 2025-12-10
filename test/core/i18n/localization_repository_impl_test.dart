import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/i18n/localization_repository_impl.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('LocalizationRepositoryImpl', () {
    late LocalizationRepositoryImpl repository;
    late MockFlutterSecureStorage mockStorage;
    late Logger logger;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      logger = Logger('test');
      repository = LocalizationRepositoryImpl(
        secureStorage: mockStorage,
        logger: logger,
      );
    });

    group('loadLanguageCode', () {
      test('should return Right(String) when language code is stored', () async {
        // Given
        const storedCode = 'es';
        when(() => mockStorage.read(key: 'app_language_code'))
            .thenAnswer((_) async => storedCode);

        // When
        final result = await repository.loadLanguageCode();

        // Then
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (code) => expect(code, storedCode),
        );
        verify(() => mockStorage.read(key: 'app_language_code')).called(1);
      });

      test('should return Right(null) when no language code is stored', () async {
        // Given
        when(() => mockStorage.read(key: 'app_language_code'))
            .thenAnswer((_) async => null);

        // When
        final result = await repository.loadLanguageCode();

        // Then
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (code) => expect(code, isNull),
        );
      });

      test('should return CacheFailure when storage read fails', () async {
        // Given
        when(() => mockStorage.read(key: 'app_language_code'))
            .thenThrow(Exception('Storage error'));

        // When
        final result = await repository.loadLanguageCode();

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to read language preference'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('saveLanguageCode', () {
      test('should return Right(void) when save succeeds', () async {
        // Given
        const languageCode = 'es';
        when(
          () => mockStorage.write(
            key: 'app_language_code',
            value: languageCode,
          ),
        ).thenAnswer((_) async => {});

        // When
        final result = await repository.saveLanguageCode(languageCode);

        // Then
        expect(result.isRight(), true);
        verify(
          () => mockStorage.write(
            key: 'app_language_code',
            value: languageCode,
          ),
        ).called(1);
      });

      test('should return CacheFailure when storage write fails', () async {
        // Given
        const languageCode = 'es';
        when(
          () => mockStorage.write(
            key: 'app_language_code',
            value: languageCode,
          ),
        ).thenThrow(Exception('Storage error'));

        // When
        final result = await repository.saveLanguageCode(languageCode);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to save language preference'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });
    });
  });
}


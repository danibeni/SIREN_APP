import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'package:siren_app/core/error/failures.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('ServerConfigService', () {
    late ServerConfigService service;
    late MockFlutterSecureStorage mockStorage;
    late Logger logger;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      logger = Logger('test');
      service = ServerConfigService(secureStorage: mockStorage, logger: logger);
    });

    group('storeServerUrl', () {
      test('should return Right(String) when URL is valid '
          'and storage succeeds', () async {
        // Given
        const validUrl = 'https://openproject.example.com';
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async => {});

        // When
        final result = await service.storeServerUrl(validUrl);

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          storedUrl,
        ) {
          expect(storedUrl, 'https://openproject.example.com');
        });
        verify(
          () => mockStorage.write(
            key: 'openproject_server_url',
            value: 'https://openproject.example.com',
          ),
        ).called(1);
      });

      test('should normalize URL by removing trailing slash '
          'before storing', () async {
        // Given
        const urlWithSlash = 'https://openproject.example.com/';
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async => {});

        // When
        final result = await service.storeServerUrl(urlWithSlash);

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          storedUrl,
        ) {
          expect(storedUrl, 'https://openproject.example.com');
        });
        verify(
          () => mockStorage.write(
            key: 'openproject_server_url',
            value: 'https://openproject.example.com',
          ),
        ).called(1);
      });

      test('should return ValidationFailure when URL is empty', () async {
        // Given
        const emptyUrl = '';

        // When
        final result = await service.storeServerUrl(emptyUrl);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Server URL cannot be empty');
        }, (_) => fail('Expected failure but got success'));
        verifyNever(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        );
      });

      test(
        'should return ValidationFailure when URL has no protocol',
        () async {
          // Given
          const urlWithoutProtocol = 'openproject.example.com';

          // When
          final result = await service.storeServerUrl(urlWithoutProtocol);

          // Then
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ValidationFailure>());
            expect(
              failure.message,
              'Server URL must start with http:// or https://',
            );
          }, (_) => fail('Expected failure but got success'));
        },
      );

      test(
        'should return ValidationFailure when URL has invalid protocol',
        () async {
          // Given
          const urlWithInvalidProtocol = 'ftp://openproject.example.com';

          // When
          final result = await service.storeServerUrl(urlWithInvalidProtocol);

          // Then
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ValidationFailure>());
            expect(
              failure.message,
              'Server URL must start with http:// or https://',
            );
          }, (_) => fail('Expected failure but got success'));
        },
      );

      test('should return ValidationFailure when URL has no domain', () async {
        // Given
        const urlWithoutDomain = 'https://';

        // When
        final result = await service.storeServerUrl(urlWithoutDomain);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Server URL must contain a valid domain');
        }, (_) => fail('Expected failure but got success'));
      });

      test('should accept URL with port number', () async {
        // Given
        const urlWithPort = 'https://openproject.example.com:8080';
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async => {});

        // When
        final result = await service.storeServerUrl(urlWithPort);

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          storedUrl,
        ) {
          expect(storedUrl, 'https://openproject.example.com:8080');
        });
      });

      test('should return CacheFailure when storage write fails', () async {
        // Given
        const validUrl = 'https://openproject.example.com';
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(Exception('Storage error'));

        // When
        final result = await service.storeServerUrl(validUrl);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, contains('Failed to store server URL'));
        }, (_) => fail('Expected failure but got success'));
      });
    });

    group('getServerUrl', () {
      test('should return Right(String) when URL is stored', () async {
        // Given
        const storedUrl = 'https://openproject.example.com';
        when(
          () => mockStorage.read(key: 'openproject_server_url'),
        ).thenAnswer((_) async => storedUrl);

        // When
        final result = await service.getServerUrl();

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          url,
        ) {
          expect(url, storedUrl);
        });
        verify(() => mockStorage.read(key: 'openproject_server_url')).called(1);
      });

      test('should return Right(null) when no URL is stored', () async {
        // Given
        when(
          () => mockStorage.read(key: 'openproject_server_url'),
        ).thenAnswer((_) async => null);

        // When
        final result = await service.getServerUrl();

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          url,
        ) {
          expect(url, isNull);
        });
      });

      test('should return CacheFailure when storage read fails', () async {
        // Given
        when(
          () => mockStorage.read(key: 'openproject_server_url'),
        ).thenThrow(Exception('Storage error'));

        // When
        final result = await service.getServerUrl();

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, contains('Failed to retrieve server URL'));
        }, (_) => fail('Expected failure but got success'));
      });
    });

    group('isConfigured', () {
      test('should return Right(true) when URL is stored', () async {
        // Given
        const storedUrl = 'https://openproject.example.com';
        when(
          () => mockStorage.read(key: 'openproject_server_url'),
        ).thenAnswer((_) async => storedUrl);

        // When
        final result = await service.isConfigured();

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          isConfigured,
        ) {
          expect(isConfigured, true);
        });
      });

      test('should return Right(false) when no URL is stored', () async {
        // Given
        when(
          () => mockStorage.read(key: 'openproject_server_url'),
        ).thenAnswer((_) async => null);

        // When
        final result = await service.isConfigured();

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          isConfigured,
        ) {
          expect(isConfigured, false);
        });
      });

      test('should return Right(false) when stored URL is empty', () async {
        // Given
        when(
          () => mockStorage.read(key: 'openproject_server_url'),
        ).thenAnswer((_) async => '');

        // When
        final result = await service.isConfigured();

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          isConfigured,
        ) {
          expect(isConfigured, false);
        });
      });
    });

    group('clearServerUrl', () {
      test('should return Right(void) when deletion succeeds', () async {
        // Given
        when(
          () => mockStorage.delete(key: 'openproject_server_url'),
        ).thenAnswer((_) async => {});

        // When
        final result = await service.clearServerUrl();

        // Then
        expect(result.isRight(), true);
        verify(
          () => mockStorage.delete(key: 'openproject_server_url'),
        ).called(1);
      });

      test('should return CacheFailure when deletion fails', () async {
        // Given
        when(
          () => mockStorage.delete(key: 'openproject_server_url'),
        ).thenThrow(Exception('Storage error'));

        // When
        final result = await service.clearServerUrl();

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<CacheFailure>());
          expect(failure.message, contains('Failed to clear server URL'));
        }, (_) => fail('Expected failure but got success'));
      });
    });
  });
}

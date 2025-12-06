import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/auth/auth_service.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/config/presentation/cubit/server_config_cubit.dart';
import 'package:siren_app/features/config/presentation/cubit/server_config_state.dart';

class MockServerConfigService extends Mock implements ServerConfigService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late ServerConfigCubit cubit;
  late MockServerConfigService mockServerConfigService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockServerConfigService = MockServerConfigService();
    mockAuthService = MockAuthService();
    cubit = ServerConfigCubit(mockServerConfigService, mockAuthService);
  });

  tearDown(() {
    cubit.close();
  });

  group('ServerConfigCubit', () {
    test('initial state should be ServerConfigInitial', () {
      // Then
      expect(cubit.state, const ServerConfigInitial());
    });

    group('validateServerUrl', () {
      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigValidating] with isServerUrlValid false '
        'when URL is empty',
        build: () => cubit,
        act: (cubit) => cubit.validateServerUrl(''),
        expect: () => [
          const ServerConfigValidating(
            serverUrlError: null,
            isServerUrlValid: false,
          ),
        ],
      );

      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigValidating] with error '
        'when URL does not start with http:// or https://',
        build: () => cubit,
        act: (cubit) => cubit.validateServerUrl('openproject.example.com'),
        expect: () => [
          const ServerConfigValidating(
            serverUrlError: 'URL must start with http:// or https://',
            isServerUrlValid: false,
          ),
        ],
      );

      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigValidating] with isServerUrlValid true '
        'when URL starts with https://',
        build: () => cubit,
        act: (cubit) =>
            cubit.validateServerUrl('https://openproject.example.com'),
        expect: () => [
          const ServerConfigValidating(
            serverUrlError: null,
            isServerUrlValid: true,
          ),
        ],
      );

      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigValidating] with isServerUrlValid true '
        'when URL starts with http://',
        build: () => cubit,
        act: (cubit) => cubit.validateServerUrl('http://localhost:8080'),
        expect: () => [
          const ServerConfigValidating(
            serverUrlError: null,
            isServerUrlValid: true,
          ),
        ],
      );
    });

    group('saveConfiguration', () {
      const testServerUrl = 'https://openproject.example.com';

      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigLoading, ServerConfigSuccess] '
        'when configuration is saved successfully',
        build: () {
          // Given
          when(
            () => mockServerConfigService.storeServerUrl(testServerUrl),
          ).thenAnswer((_) async => const Right(testServerUrl));
          return cubit;
        },
        act: (cubit) => cubit.saveConfiguration(serverUrl: testServerUrl),
        expect: () => [
          const ServerConfigLoading(),
          const ServerConfigSuccess(testServerUrl),
        ],
        verify: (_) {
          // Then
          verify(
            () => mockServerConfigService.storeServerUrl(testServerUrl),
          ).called(1);
        },
      );

      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigLoading, ServerConfigError] '
        'when server URL validation fails',
        build: () {
          // Given
          when(() => mockServerConfigService.storeServerUrl(any())).thenAnswer(
            (_) async => const Left(
              ValidationFailure(
                'Server URL must start with http:// or https://',
              ),
            ),
          );
          return cubit;
        },
        act: (cubit) => cubit.saveConfiguration(serverUrl: 'invalid-url'),
        expect: () => [
          const ServerConfigLoading(),
          const ServerConfigError(
            'Server URL must start with http:// or https://',
          ),
        ],
        verify: (_) {
          // Then
          verify(
            () => mockServerConfigService.storeServerUrl('invalid-url'),
          ).called(1);
        },
      );
    });

    group('isConfigured', () {
      test('should return true when server URL is configured', () async {
        // Given
        when(
          () => mockServerConfigService.isConfigured(),
        ).thenAnswer((_) async => const Right(true));

        // When
        final result = await cubit.isConfigured();

        // Then
        expect(result, true);
        verify(() => mockServerConfigService.isConfigured()).called(1);
      });

      test('should return false when server URL is not configured', () async {
        // Given
        when(
          () => mockServerConfigService.isConfigured(),
        ).thenAnswer((_) async => const Right(false));

        // When
        final result = await cubit.isConfigured();

        // Then
        expect(result, false);
      });

      test('should return false when checking configuration fails', () async {
        // Given
        when(
          () => mockServerConfigService.isConfigured(),
        ).thenAnswer((_) async => const Left(CacheFailure('Error')));

        // When
        final result = await cubit.isConfigured();

        // Then
        expect(result, false);
      });
    });

    group('loadExistingConfiguration', () {
      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigLoading, ServerConfigLoaded] '
        'when configuration exists',
        build: () {
          // Given
          when(
            () => mockServerConfigService.getServerUrl(),
          ).thenAnswer((_) async => const Right('https://example.com'));
          return cubit;
        },
        act: (cubit) => cubit.loadExistingConfiguration(),
        expect: () => [
          const ServerConfigLoading(),
          const ServerConfigLoaded(serverUrl: 'https://example.com'),
        ],
      );

      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigLoading, ServerConfigLoaded] '
        'when no configuration exists',
        build: () {
          // Given
          when(
            () => mockServerConfigService.getServerUrl(),
          ).thenAnswer((_) async => const Right(null));
          return cubit;
        },
        act: (cubit) => cubit.loadExistingConfiguration(),
        expect: () => [
          const ServerConfigLoading(),
          const ServerConfigLoaded(serverUrl: null),
        ],
      );

      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigLoading, ServerConfigError] '
        'when loading fails',
        build: () {
          // Given
          when(
            () => mockServerConfigService.getServerUrl(),
          ).thenAnswer((_) async => const Left(CacheFailure('Load error')));
          return cubit;
        },
        act: (cubit) => cubit.loadExistingConfiguration(),
        expect: () => [
          const ServerConfigLoading(),
          const ServerConfigError('Load error'),
        ],
      );
    });

    group('clearConfiguration', () {
      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigLoading, ServerConfigInitial] '
        'when configuration is cleared successfully',
        build: () {
          // Given
          when(
            () => mockServerConfigService.clearServerUrl(),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockAuthService.clearCredentials(),
          ).thenAnswer((_) async {});
          return cubit;
        },
        act: (cubit) => cubit.clearConfiguration(),
        expect: () => [
          const ServerConfigLoading(),
          const ServerConfigInitial(),
        ],
        verify: (_) {
          verify(() => mockServerConfigService.clearServerUrl()).called(1);
          verify(() => mockAuthService.clearCredentials()).called(1);
        },
      );

      blocTest<ServerConfigCubit, ServerConfigState>(
        'emits [ServerConfigLoading, ServerConfigError] '
        'when clearing server URL fails',
        build: () {
          // Given
          when(
            () => mockServerConfigService.clearServerUrl(),
          ).thenAnswer((_) async => const Left(CacheFailure('Clear error')));
          when(
            () => mockAuthService.clearCredentials(),
          ).thenAnswer((_) async {});
          return cubit;
        },
        act: (cubit) => cubit.clearConfiguration(),
        expect: () => [
          const ServerConfigLoading(),
          const ServerConfigError('Clear error'),
        ],
      );
    });
  });
}

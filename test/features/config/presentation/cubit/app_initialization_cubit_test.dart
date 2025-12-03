import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/auth/auth_service.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/config/presentation/cubit/app_initialization_cubit.dart';
import 'package:siren_app/features/config/presentation/cubit/app_initialization_state.dart';

class MockServerConfigService extends Mock implements ServerConfigService {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late AppInitializationCubit cubit;
  late MockServerConfigService mockServerConfigService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockServerConfigService = MockServerConfigService();
    mockAuthService = MockAuthService();
    cubit = AppInitializationCubit(
      mockServerConfigService,
      mockAuthService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('AppInitializationCubit', () {
    test('initial state should be AppInitializationChecking', () {
      // Then
      expect(cubit.state, const AppInitializationChecking());
    });

    group('checkConfiguration', () {
      blocTest<AppInitializationCubit, AppInitializationState>(
        'emits [AppInitializationChecking, AppInitializationConfigured] '
        'when server is configured and user is authenticated',
        build: () {
          // Given
          when(() => mockServerConfigService.isConfigured())
              .thenAnswer((_) async => const Right(true));
          when(() => mockAuthService.isAuthenticated())
              .thenAnswer((_) async => true);
          return cubit;
        },
        act: (cubit) => cubit.checkConfiguration(),
        expect: () => [
          const AppInitializationChecking(),
          const AppInitializationConfigured(),
        ],
        verify: (_) {
          verify(() => mockServerConfigService.isConfigured()).called(1);
          verify(() => mockAuthService.isAuthenticated()).called(1);
        },
      );

      blocTest<AppInitializationCubit, AppInitializationState>(
        'emits [AppInitializationChecking, AppInitializationNotConfigured] '
        'when server is configured but user is not authenticated',
        build: () {
          // Given
          when(() => mockServerConfigService.isConfigured())
              .thenAnswer((_) async => const Right(true));
          when(() => mockAuthService.isAuthenticated())
              .thenAnswer((_) async => false);
          return cubit;
        },
        act: (cubit) => cubit.checkConfiguration(),
        expect: () => [
          const AppInitializationChecking(),
          const AppInitializationNotConfigured(),
        ],
        verify: (_) {
          verify(() => mockServerConfigService.isConfigured()).called(1);
          verify(() => mockAuthService.isAuthenticated()).called(1);
        },
      );

      blocTest<AppInitializationCubit, AppInitializationState>(
        'emits [AppInitializationChecking, AppInitializationNotConfigured] '
        'when server is not configured',
        build: () {
          // Given
          when(() => mockServerConfigService.isConfigured())
              .thenAnswer((_) async => const Right(false));
          return cubit;
        },
        act: (cubit) => cubit.checkConfiguration(),
        expect: () => [
          const AppInitializationChecking(),
          const AppInitializationNotConfigured(),
        ],
        verify: (_) {
          verify(() => mockServerConfigService.isConfigured()).called(1);
        },
      );

      blocTest<AppInitializationCubit, AppInitializationState>(
        'emits [AppInitializationChecking, AppInitializationNotConfigured] '
        'when server config check fails',
        build: () {
          // Given
          when(() => mockServerConfigService.isConfigured())
              .thenAnswer((_) async => const Left(CacheFailure('Error')));
          return cubit;
        },
        act: (cubit) => cubit.checkConfiguration(),
        expect: () => [
          const AppInitializationChecking(),
          const AppInitializationNotConfigured(),
        ],
      );


      blocTest<AppInitializationCubit, AppInitializationState>(
        'emits [AppInitializationChecking, AppInitializationError] '
        'when an exception is thrown',
        build: () {
          // Given
          when(() => mockServerConfigService.isConfigured())
              .thenThrow(Exception('Unexpected error'));
          return cubit;
        },
        act: (cubit) => cubit.checkConfiguration(),
        expect: () => [
          const AppInitializationChecking(),
          const AppInitializationError(
            'Initialization failed: Exception: Unexpected error',
          ),
        ],
      );
    });
  });
}


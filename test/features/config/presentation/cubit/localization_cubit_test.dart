import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/i18n/localization_service.dart';
import 'package:siren_app/core/i18n/usecases/get_language_usecase.dart';
import 'package:siren_app/core/i18n/usecases/set_language_usecase.dart';
import 'package:siren_app/features/config/presentation/cubit/localization_cubit.dart';
import 'package:siren_app/features/config/presentation/cubit/localization_state.dart';

class MockGetLanguageUseCase extends Mock implements GetLanguageUseCase {}

class MockSetLanguageUseCase extends Mock implements SetLanguageUseCase {}

class MockLocalizationService extends Mock implements LocalizationService {}

void main() {
  group('LocalizationCubit', () {
    late LocalizationCubit cubit;
    late MockGetLanguageUseCase mockGetLanguage;
    late MockSetLanguageUseCase mockSetLanguage;
    late MockLocalizationService mockService;

    setUp(() {
      mockGetLanguage = MockGetLanguageUseCase();
      mockSetLanguage = MockSetLanguageUseCase();
      mockService = MockLocalizationService();
      when(() => mockService.fallbackLocale).thenReturn(const Locale('en'));
      when(() => mockService.supportedLocales)
          .thenReturn([const Locale('en'), const Locale('es')]);
      when(() => mockService.currentLocale).thenReturn(const Locale('en'));
      cubit = LocalizationCubit(
        mockGetLanguage,
        mockSetLanguage,
        mockService,
      );
    });

    test('initial state should have loading status and fallback locale', () {
      // Then
      expect(
        cubit.state,
        LocalizationState(
          locale: mockService.fallbackLocale,
          status: LocalizationStatus.loading,
        ),
      );
    });

    blocTest<LocalizationCubit, LocalizationState>(
      'should emit ready state with locale when load succeeds',
      build: () {
        when(() => mockGetLanguage())
            .thenAnswer((_) async => const Right(Locale('es')));
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        LocalizationState(
          locale: mockService.fallbackLocale,
          status: LocalizationStatus.loading,
          errorMessage: null,
        ),
        LocalizationState(
          locale: const Locale('es'),
          status: LocalizationStatus.ready,
          errorMessage: null,
        ),
      ],
    );

    blocTest<LocalizationCubit, LocalizationState>(
      'should emit error state when load fails',
      build: () {
        const failure = CacheFailure('Storage error');
        when(() => mockGetLanguage())
            .thenAnswer((_) async => const Left(failure));
        return cubit;
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        LocalizationState(
          locale: mockService.fallbackLocale,
          status: LocalizationStatus.loading,
          errorMessage: null,
        ),
        LocalizationState(
          locale: mockService.currentLocale,
          status: LocalizationStatus.error,
          errorMessage: 'Storage error',
        ),
      ],
    );

    blocTest<LocalizationCubit, LocalizationState>(
      'should emit ready state with new locale when changeLanguage succeeds',
      build: () {
        when(() => mockGetLanguage())
            .thenAnswer((_) async => const Right(Locale('en')));
        when(() => mockSetLanguage(const Locale('es')))
            .thenAnswer((_) async => const Right(Locale('es')));
        return cubit;
      },
      seed: () => LocalizationState(
        locale: const Locale('en'),
        status: LocalizationStatus.ready,
      ),
      act: (cubit) => cubit.changeLanguage('es'),
      expect: () => [
        LocalizationState(
          locale: const Locale('en'),
          status: LocalizationStatus.loading,
          errorMessage: null,
        ),
        LocalizationState(
          locale: const Locale('es'),
          status: LocalizationStatus.ready,
          errorMessage: null,
        ),
      ],
    );

    blocTest<LocalizationCubit, LocalizationState>(
      'should emit error state when changeLanguage fails',
      build: () {
        when(() => mockGetLanguage())
            .thenAnswer((_) async => const Right(Locale('en')));
        const failure = ValidationFailure('Unsupported language');
        when(() => mockSetLanguage(const Locale('en')))
            .thenAnswer((_) async => const Left(failure));
        return cubit;
      },
      seed: () => LocalizationState(
        locale: const Locale('en'),
        status: LocalizationStatus.ready,
      ),
      act: (cubit) => cubit.changeLanguage('fr'),
      expect: () => [
        LocalizationState(
          locale: const Locale('en'),
          status: LocalizationStatus.loading,
          errorMessage: null,
        ),
        LocalizationState(
          locale: const Locale('en'),
          status: LocalizationStatus.error,
          errorMessage: 'Unsupported language',
        ),
      ],
    );
  });
}


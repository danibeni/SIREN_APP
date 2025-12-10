import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/i18n/localization_repository.dart';
import 'package:siren_app/core/i18n/localization_service_impl.dart';

class MockLocalizationRepository extends Mock
    implements LocalizationRepository {}

void main() {
  group('LocalizationServiceImpl', () {
    late LocalizationServiceImpl service;
    late MockLocalizationRepository mockRepository;

    setUp(() {
      mockRepository = MockLocalizationRepository();
      service = LocalizationServiceImpl(mockRepository);
    });

    group('supportedLocales', () {
      test('should return list with en and es locales', () {
        // When
        final locales = service.supportedLocales;

        // Then
        expect(locales.length, 2);
        expect(locales[0].languageCode, 'en');
        expect(locales[1].languageCode, 'es');
      });
    });

    group('fallbackLocale', () {
      test('should return English locale', () {
        // When
        final fallback = service.fallbackLocale;

        // Then
        expect(fallback.languageCode, 'en');
      });
    });

    group('loadInitialLocale', () {
      test('should return stored locale when available', () async {
        // Given
        const storedCode = 'es';
        when(() => mockRepository.loadLanguageCode())
            .thenAnswer((_) async => const Right(storedCode));

        // When
        final result = await service.loadInitialLocale();

        // Then
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (locale) => expect(locale.languageCode, 'es'),
        );
        verify(() => mockRepository.loadLanguageCode()).called(1);
      });

      test('should return fallback locale when no stored code', () async {
        // Given
        when(() => mockRepository.loadLanguageCode())
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.saveLanguageCode('en'))
            .thenAnswer((_) async => const Right(null));

        // When
        final result = await service.loadInitialLocale();

        // Then
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (locale) => expect(locale.languageCode, 'en'),
        );
      });

      test('should return CacheFailure when repository fails', () async {
        // Given
        when(() => mockRepository.loadLanguageCode()).thenAnswer(
          (_) async => const Left(CacheFailure('Storage error')),
        );
        when(() => mockRepository.saveLanguageCode(any()))
            .thenAnswer((_) async => const Right(null));

        // When
        final result = await service.loadInitialLocale();

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('changeLocale', () {
      test('should return Right(Locale) when change succeeds', () async {
        // Given
        const newLocale = Locale('es');
        when(() => mockRepository.saveLanguageCode('es'))
            .thenAnswer((_) async => const Right(null));

        // When
        final result = await service.changeLocale(newLocale);

        // Then
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (locale) => expect(locale.languageCode, 'es'),
        );
        verify(() => mockRepository.saveLanguageCode('es')).called(1);
      });

      test('should return ValidationFailure for unsupported locale', () async {
        // Given
        const unsupportedLocale = Locale('fr');

        // When
        final result = await service.changeLocale(unsupportedLocale);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Requested language is not supported');
          },
          (_) => fail('Expected failure but got success'),
        );
        verifyNever(() => mockRepository.saveLanguageCode(any()));
      });

      test('should return CacheFailure when save fails', () async {
        // Given
        const newLocale = Locale('es');
        when(() => mockRepository.saveLanguageCode('es')).thenAnswer(
          (_) async => const Left(CacheFailure('Storage error')),
        );

        // When
        final result = await service.changeLocale(newLocale);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected failure but got success'),
        );
      });
    });
  });
}


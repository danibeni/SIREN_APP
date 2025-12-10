import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/i18n/localization_service.dart';
import 'package:siren_app/core/i18n/usecases/get_language_usecase.dart';

class MockLocalizationService extends Mock implements LocalizationService {}

void main() {
  group('GetLanguageUseCase', () {
    late GetLanguageUseCase useCase;
    late MockLocalizationService mockService;

    setUp(() {
      mockService = MockLocalizationService();
      useCase = GetLanguageUseCase(mockService);
    });

    test('should return Right(Locale) when service call succeeds', () async {
      // Given
      const expectedLocale = Locale('es');
      when(() => mockService.loadInitialLocale())
          .thenAnswer((_) async => const Right(expectedLocale));

      // When
      final result = await useCase();

      // Then
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure'),
        (locale) => expect(locale, expectedLocale),
      );
      verify(() => mockService.loadInitialLocale()).called(1);
    });

    test('should return Left(Failure) when service call fails', () async {
      // Given
      const failure = CacheFailure('Storage error');
      when(() => mockService.loadInitialLocale())
          .thenAnswer((_) async => const Left(failure));

      // When
      final result = await useCase();

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, failure),
        (_) => fail('Expected failure but got success'),
      );
    });
  });
}


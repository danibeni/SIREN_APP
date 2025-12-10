import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/i18n/localization_service.dart';
import 'package:siren_app/core/i18n/usecases/set_language_usecase.dart';

class MockLocalizationService extends Mock implements LocalizationService {}

void main() {
  group('SetLanguageUseCase', () {
    late SetLanguageUseCase useCase;
    late MockLocalizationService mockService;

    setUp(() {
      mockService = MockLocalizationService();
      useCase = SetLanguageUseCase(mockService);
    });

    test('should return Right(Locale) when service call succeeds', () async {
      // Given
      const locale = Locale('es');
      const expectedLocale = Locale('es');
      when(() => mockService.changeLocale(locale))
          .thenAnswer((_) async => const Right(expectedLocale));

      // When
      final result = await useCase(locale);

      // Then
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure'),
        (resultLocale) => expect(resultLocale, expectedLocale),
      );
      verify(() => mockService.changeLocale(locale)).called(1);
    });

    test('should return Left(Failure) when service call fails', () async {
      // Given
      const locale = Locale('es');
      const failure = ValidationFailure('Unsupported language');
      when(() => mockService.changeLocale(locale))
          .thenAnswer((_) async => const Left(failure));

      // When
      final result = await useCase(locale);

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, failure),
        (_) => fail('Expected failure but got success'),
      );
    });
  });
}


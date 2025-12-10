import 'dart:ui' show PlatformDispatcher;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/i18n/localization_repository.dart';
import 'package:siren_app/core/i18n/localization_service.dart';

@LazySingleton(as: LocalizationService)
class LocalizationServiceImpl implements LocalizationService {
  LocalizationServiceImpl(this._repository);

  final LocalizationRepository _repository;

  final List<Locale> _supportedLocales = const [
    Locale('en'),
    Locale('es'),
  ];

  Locale _currentLocale = const Locale('en');

  @override
  List<Locale> get supportedLocales => _supportedLocales;

  @override
  Locale get fallbackLocale => const Locale('en');

  @override
  Locale get currentLocale => _currentLocale;

  @override
  Future<Either<Failure, Locale>> loadInitialLocale() async {
    Failure? failure;
    String? storedCode;

    final storedResult = await _repository.loadLanguageCode();
    storedResult.fold(
      (error) => failure = error,
      (code) => storedCode = code,
    );

    final deviceLocale = PlatformDispatcher.instance.locale;
    final storedLocale =
        storedCode != null ? Locale(storedCode!) : deviceLocale;

    final resolvedLocale = _resolveLocale(storedLocale);
    _currentLocale = resolvedLocale;

    if (storedCode == null) {
      await _repository.saveLanguageCode(resolvedLocale.languageCode);
    }

    if (failure != null) {
      return Left(failure!);
    }

    return Right(resolvedLocale);
  }

  @override
  Future<Either<Failure, Locale>> changeLocale(Locale locale) async {
    if (!_isSupported(locale)) {
      return Left(
        const ValidationFailure('Requested language is not supported'),
      );
    }

    final saveResult =
        await _repository.saveLanguageCode(locale.languageCode);

    return saveResult.fold(
      (failure) => Left(failure),
      (_) {
        _currentLocale = _resolveLocale(locale);
        return Right(_currentLocale);
      },
    );
  }

  Locale _resolveLocale(Locale? locale) {
    if (locale == null) {
      return fallbackLocale;
    }

    return _supportedLocales.firstWhere(
      (supported) => supported.languageCode == locale.languageCode,
      orElse: () => fallbackLocale,
    );
  }

  bool _isSupported(Locale locale) {
    return _supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }
}


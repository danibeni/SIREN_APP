import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/i18n/localization_service.dart';

@lazySingleton
class GetLanguageUseCase {
  GetLanguageUseCase(this._service);

  final LocalizationService _service;

  Future<Either<Failure, Locale>> call() {
    return _service.loadInitialLocale();
  }
}


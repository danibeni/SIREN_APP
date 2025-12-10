import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:siren_app/core/error/failures.dart';

abstract class LocalizationService {
  List<Locale> get supportedLocales;

  Locale get fallbackLocale;

  Locale get currentLocale;

  Future<Either<Failure, Locale>> loadInitialLocale();

  Future<Either<Failure, Locale>> changeLocale(Locale locale);
}


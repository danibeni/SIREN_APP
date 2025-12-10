import 'package:dartz/dartz.dart';
import 'package:siren_app/core/error/failures.dart';

abstract class LocalizationRepository {
  Future<Either<Failure, String?>> loadLanguageCode();

  Future<Either<Failure, void>> saveLanguageCode(String code);
}


import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/i18n/localization_repository.dart';

@LazySingleton(as: LocalizationRepository)
class LocalizationRepositoryImpl implements LocalizationRepository {
  LocalizationRepositoryImpl({
    required FlutterSecureStorage secureStorage,
    required Logger logger,
  })  : _secureStorage = secureStorage,
        _logger = logger;

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  static const String _languageCodeKey = 'app_language_code';

  @override
  Future<Either<Failure, String?>> loadLanguageCode() async {
    try {
      final code = await _secureStorage.read(key: _languageCodeKey);
      return Right(code);
    } catch (e) {
      _logger.severe('Error reading language code: $e');
      return Left(
        CacheFailure('Failed to read language preference: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveLanguageCode(String code) async {
    try {
      await _secureStorage.write(key: _languageCodeKey, value: code);
      _logger.info('Language code saved: $code');
      return const Right(null);
    } catch (e) {
      _logger.severe('Error saving language code: $e');
      return Left(
        CacheFailure('Failed to save language preference: ${e.toString()}'),
      );
    }
  }
}


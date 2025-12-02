import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

/// Core module for third-party dependencies
///
/// Registers dependencies that cannot be annotated directly
/// (e.g., FlutterSecureStorage, Logger)
@module
abstract class CoreModule {
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  Logger get logger => Logger('SIREN');
}


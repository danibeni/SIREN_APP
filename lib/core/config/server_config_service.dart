import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import '../error/failures.dart';

/// Service for managing OpenProject server URL configuration
///
/// Handles secure storage and retrieval of server URL with validation.
/// The server URL should be the base URL without the API path.
/// Format: https://your-openproject-instance.com
/// The API path `/api/v3/` will be appended automatically by DioClient.
@lazySingleton
class ServerConfigService {
  final FlutterSecureStorage _secureStorage;
  final Logger logger;

  static const String _serverUrlKey = 'openproject_server_url';

  ServerConfigService({
    required FlutterSecureStorage secureStorage,
    required this.logger,
  }) : _secureStorage = secureStorage;

  /// Store server URL with validation
  ///
  /// Validates URL format (protocol, domain, optional port) before storing.
  /// Normalizes URL by removing trailing slash.
  /// Returns [Right] with stored URL on success, [Left] with [Failure] on error.
  Future<Either<Failure, String>> storeServerUrl(String url) async {
    // Validate URL
    final validationResult = _validateUrl(url);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Normalize URL: remove trailing slash
    final normalizedUrl = url.trim().endsWith('/')
        ? url.trim().substring(0, url.trim().length - 1)
        : url.trim();

    try {
      await _secureStorage.write(key: _serverUrlKey, value: normalizedUrl);
      logger.info('Server URL stored successfully: $normalizedUrl');
      return Right(normalizedUrl);
    } catch (e) {
      logger.severe('Error storing server URL: $e');
      return Left(CacheFailure('Failed to store server URL: ${e.toString()}'));
    }
  }

  /// Retrieve stored server URL
  ///
  /// Returns [Right] with stored URL (or null if not configured),
  /// [Left] with [Failure] on error.
  Future<Either<Failure, String?>> getServerUrl() async {
    try {
      final url = await _secureStorage.read(key: _serverUrlKey);
      return Right(url);
    } catch (e) {
      logger.severe('Error retrieving server URL: $e');
      return Left(
        CacheFailure('Failed to retrieve server URL: ${e.toString()}'),
      );
    }
  }

  /// Check if server URL is configured
  ///
  /// Returns [Right] with true if URL is stored and non-empty,
  /// false otherwise. [Left] with [Failure] on error.
  Future<Either<Failure, bool>> isConfigured() async {
    final result = await getServerUrl();
    return result.fold(
      (failure) => Left(failure),
      (url) => Right(url != null && url.isNotEmpty),
    );
  }

  /// Clear stored server URL
  ///
  /// Returns [Right] with void on success, [Left] with [Failure] on error.
  Future<Either<Failure, void>> clearServerUrl() async {
    try {
      await _secureStorage.delete(key: _serverUrlKey);
      logger.info('Server URL cleared');
      return const Right(null);
    } catch (e) {
      logger.severe('Error clearing server URL: $e');
      return Left(CacheFailure('Failed to clear server URL: ${e.toString()}'));
    }
  }

  /// Validate URL format
  ///
  /// Validates:
  /// - URL is not empty
  /// - URL starts with http:// or https://
  /// - URL contains a valid domain
  /// - Optional port number is valid
  ///
  /// Returns null if valid, [ValidationFailure] if invalid.
  ValidationFailure? _validateUrl(String url) {
    final trimmedUrl = url.trim();

    // Check if empty
    if (trimmedUrl.isEmpty) {
      return const ValidationFailure('Server URL cannot be empty');
    }

    // Check protocol
    if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      return const ValidationFailure(
        'Server URL must start with http:// or https://',
      );
    }

    // Parse URL to validate format
    try {
      final uri = Uri.parse(trimmedUrl);

      // Check if has valid host
      if (uri.host.isEmpty) {
        return const ValidationFailure(
          'Server URL must contain a valid domain',
        );
      }

      // Check port if specified
      if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
        return const ValidationFailure(
          'Server URL port must be between 1 and 65535',
        );
      }

      return null;
    } catch (e) {
      return ValidationFailure('Invalid URL format: ${e.toString()}');
    }
  }
}

/// Base exception for all custom exceptions in the application
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when a server error occurs
class ServerException extends AppException {
  const ServerException(super.message);
}

/// Exception thrown when a network error occurs
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Exception thrown when a resource is not found (404)
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Exception thrown when a conflict occurs (409) - e.g., optimistic locking
class ConflictException extends AppException {
  const ConflictException(super.message);
}

/// Exception thrown when validation fails (422)
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Exception thrown when authentication fails (401)
class AuthenticationException extends AppException {
  const AuthenticationException(super.message);
}

/// Exception thrown when authorization fails (403)
class AuthorizationException extends AppException {
  const AuthorizationException(super.message);
}

/// Exception thrown when a cache operation fails
class CacheException extends AppException {
  const CacheException(super.message);
}

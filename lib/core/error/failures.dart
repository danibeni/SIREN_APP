import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
///
/// All failure types should extend this class to ensure consistent error handling
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure representing server/API errors
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure representing network connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Failure representing validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure representing authentication/authorization errors
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

/// Failure representing cache/local storage errors
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Special failure indicating data was loaded from cache (offline mode)
class CachedDataInfo extends Failure {
  const CachedDataInfo(super.message);
}

/// Failure representing resource not found errors
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Failure representing unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

/// Failure representing conflict errors (e.g., optimistic locking conflicts)
class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

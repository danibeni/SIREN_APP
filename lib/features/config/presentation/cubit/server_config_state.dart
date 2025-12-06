import 'package:equatable/equatable.dart';

/// States for server configuration
abstract class ServerConfigState extends Equatable {
  const ServerConfigState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ServerConfigInitial extends ServerConfigState {
  const ServerConfigInitial();
}

/// Loaded state with existing configuration
class ServerConfigLoaded extends ServerConfigState {
  final String? serverUrl;

  const ServerConfigLoaded({this.serverUrl});

  @override
  List<Object?> get props => [serverUrl];
}

/// Loading state (saving configuration)
class ServerConfigLoading extends ServerConfigState {
  const ServerConfigLoading();
}

/// Success state (configuration saved)
class ServerConfigSuccess extends ServerConfigState {
  final String serverUrl;

  const ServerConfigSuccess(this.serverUrl);

  @override
  List<Object?> get props => [serverUrl];
}

/// Error state (validation or storage failed)
class ServerConfigError extends ServerConfigState {
  final String message;

  const ServerConfigError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Validation state for real-time feedback
class ServerConfigValidating extends ServerConfigState {
  final String? serverUrlError;
  final bool isServerUrlValid;

  const ServerConfigValidating({
    this.serverUrlError,
    this.isServerUrlValid = false,
  });

  @override
  List<Object?> get props => [serverUrlError, isServerUrlValid];

  ServerConfigValidating copyWith({
    String? serverUrlError,
    bool? isServerUrlValid,
  }) {
    return ServerConfigValidating(
      serverUrlError: serverUrlError,
      isServerUrlValid: isServerUrlValid ?? this.isServerUrlValid,
    );
  }
}

class ServerConfigAuthenticating extends ServerConfigState {
  const ServerConfigAuthenticating();
}

class ServerConfigAuthenticationSuccess extends ServerConfigState {
  const ServerConfigAuthenticationSuccess();
}

/// State after successful logout (tokens cleared, config preserved)
class ServerConfigLoggedOut extends ServerConfigState {
  const ServerConfigLoggedOut();
}

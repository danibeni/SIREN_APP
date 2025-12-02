import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/auth/auth_service.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'server_config_state.dart';

@injectable
class ServerConfigCubit extends Cubit<ServerConfigState> {
  final ServerConfigService _serverConfigService;
  final AuthService _authService;

  ServerConfigCubit(
    this._serverConfigService,
    this._authService,
  ) : super(const ServerConfigInitial());

  /// Validate server URL in real-time
  void validateServerUrl(String url) {
    final currentState = state;
    
    if (url.trim().isEmpty) {
      emit(const ServerConfigValidating(
        serverUrlError: null,
        isServerUrlValid: false,
      ));
      return;
    }

    // Basic validation (detailed validation happens on save)
    if (!url.trim().startsWith('http://') &&
        !url.trim().startsWith('https://')) {
      emit(const ServerConfigValidating(
        serverUrlError: 'URL must start with http:// or https://',
        isServerUrlValid: false,
      ));
      return;
    }

    // URL looks valid
    if (currentState is ServerConfigValidating) {
      emit(currentState.copyWith(
        serverUrlError: null,
        isServerUrlValid: true,
      ));
    } else {
      emit(const ServerConfigValidating(
        serverUrlError: null,
        isServerUrlValid: true,
      ));
    }
  }

  /// Save server configuration
  Future<void> saveConfiguration({
    required String serverUrl,
  }) async {
    emit(const ServerConfigLoading());

    // Validate and store server URL
    final serverUrlResult = await _serverConfigService.storeServerUrl(serverUrl);

    serverUrlResult.fold(
      (failure) => emit(ServerConfigError(failure.message)),
      (storedUrl) => emit(ServerConfigSuccess(storedUrl)),
    );
  }

  /// Check if configuration already exists
  Future<bool> isConfigured() async {
    final result = await _serverConfigService.isConfigured();
    return result.fold(
      (failure) => false,
      (isConfigured) => isConfigured,
    );
  }

  /// Load existing configuration for editing
  Future<void> loadExistingConfiguration() async {
    emit(const ServerConfigLoading());

    final urlResult = await _serverConfigService.getServerUrl();

    urlResult.fold(
      (failure) => emit(ServerConfigError(failure.message)),
      (url) => emit(ServerConfigLoaded(
        serverUrl: url,
      )),
    );
  }

  /// Clear all configuration
  Future<void> clearConfiguration() async {
    emit(const ServerConfigLoading());

    final clearUrlResult = await _serverConfigService.clearServerUrl();
    await _authService.clearCredentials();

    clearUrlResult.fold(
      (failure) => emit(ServerConfigError(failure.message)),
      (_) => emit(const ServerConfigInitial()),
    );
  }

  Future<void> authenticate({
    required String serverUrl,
    required String clientId,
  }) async {
    emit(const ServerConfigAuthenticating());

    final success = await _authService.login(
      serverUrl: serverUrl,
      clientId: clientId,
    );

    if (success) {
      emit(const ServerConfigAuthenticationSuccess());
    } else {
      emit(const ServerConfigError('Authentication failed'));
    }
  }

  /// Logout: Clear only authentication tokens, preserve server configuration
  Future<void> logout() async {
    emit(const ServerConfigLoading());

    await _authService.clearCredentials();

    emit(const ServerConfigLoggedOut());
  }
}

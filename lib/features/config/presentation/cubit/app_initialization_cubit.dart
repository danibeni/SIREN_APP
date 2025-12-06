import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/auth/auth_service.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'app_initialization_state.dart';

@injectable
class AppInitializationCubit extends Cubit<AppInitializationState> {
  final ServerConfigService _serverConfigService;
  final AuthService _authService;

  AppInitializationCubit(this._serverConfigService, this._authService)
    : super(const AppInitializationChecking());

  /// Check if app is properly configured
  Future<void> checkConfiguration() async {
    emit(const AppInitializationChecking());

    try {
      final serverUrlResult = await _serverConfigService.isConfigured();
      final isServerConfigured = serverUrlResult.fold(
        (failure) => false,
        (isConfigured) => isConfigured,
      );

      if (!isServerConfigured) {
        emit(const AppInitializationNotConfigured());
        return;
      }

      final isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) {
        emit(const AppInitializationNotConfigured());
        return;
      }

      emit(const AppInitializationConfigured());
    } catch (e) {
      emit(AppInitializationError('Initialization failed: $e'));
    }
  }
}

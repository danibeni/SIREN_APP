import 'package:equatable/equatable.dart';

/// States for app initialization
abstract class AppInitializationState extends Equatable {
  const AppInitializationState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking configuration
class AppInitializationChecking extends AppInitializationState {
  const AppInitializationChecking();
}

/// Configuration exists - proceed to main app
class AppInitializationConfigured extends AppInitializationState {
  const AppInitializationConfigured();
}

/// No configuration - redirect to setup
class AppInitializationNotConfigured extends AppInitializationState {
  const AppInitializationNotConfigured();
}

/// Error during initialization
class AppInitializationError extends AppInitializationState {
  final String message;

  const AppInitializationError(this.message);

  @override
  List<Object?> get props => [message];
}

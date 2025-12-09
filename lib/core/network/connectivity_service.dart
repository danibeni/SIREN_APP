import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Service for detecting network connectivity
///
/// Provides methods to check online/offline status
/// Used by repository to determine save behavior
@lazySingleton
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Check if device is currently connected to the internet
  ///
  /// Returns true if connected (wifi, mobile, ethernet)
  /// Returns false if not connected (none)
  Future<bool> isConnected() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    return results.isNotEmpty &&
        !results.every((result) => result == ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  ///
  /// Emits connectivity result whenever connection status changes
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;
}

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/auth/oauth2_service.dart';
import 'package:siren_app/core/auth/pkce_helper.dart';

@lazySingleton
class AuthService {
  final OAuth2Service _oauth2Service;
  final Logger logger;

  static const String _redirectUri = 'siren://oauth/callback';
  static const String _scope = 'api_v3';

  String? _codeVerifier;
  Completer<String?>? _authCompleter;
  ChromeSafariBrowser? _browser;

  AuthService({required OAuth2Service oauth2Service, required this.logger})
    : _oauth2Service = oauth2Service;

  Future<bool> isAuthenticated() async {
    return await _oauth2Service.hasValidToken();
  }

  Future<void> clearCredentials() async {
    await _oauth2Service.clearTokens();
    logger.info('Credentials cleared');
  }

  /// Verify server reachability before opening OAuth2 browser
  ///
  /// Returns true if server is reachable, false otherwise
  /// Uses short timeout (5 seconds) to prevent long waiting periods
  Future<bool> _verifyServerReachability(String serverUrl) async {
    try {
      logger.info('Verifying server reachability: $serverUrl');

      // Create a temporary Dio instance with short timeout for reachability check
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      // Try to reach the server root or a lightweight endpoint
      final response = await dio
          .head(serverUrl)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Server reachability check timed out');
            },
          );

      final isReachable = response.statusCode != null;
      logger.info(
        'Server reachability check: ${isReachable ? "successful" : "failed"}',
      );
      return isReachable;
    } on TimeoutException {
      logger.warning('Server reachability check timed out after 5 seconds');
      return false;
    } on DioException catch (e) {
      // Any connection error means server is not reachable
      logger.warning('Server reachability check failed: ${e.message}');
      return false;
    } catch (e) {
      logger.warning('Unexpected error during server reachability check: $e');
      return false;
    }
  }

  Future<bool> login({
    required String serverUrl,
    required String clientId,
  }) async {
    try {
      // Step 1: Verify server reachability before opening browser
      logger.info('Verifying server reachability before OAuth2 flow');
      final isReachable = await _verifyServerReachability(serverUrl);

      if (!isReachable) {
        logger.severe(
          'Server is not reachable. Cannot proceed with OAuth2 authentication.',
        );
        throw Exception(
          'Cannot connect to OpenProject server. Please verify:\n'
          '• The server URL is correct\n'
          '• The server is accessible via Wi-Fi\n'
          '• The server is running and responding',
        );
      }

      _codeVerifier = PkceHelper.generateCodeVerifier();
      final codeChallenge = PkceHelper.generateCodeChallenge(_codeVerifier!);

      final authorizationUrl = Uri.parse('$serverUrl/oauth/authorize').replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': clientId,
          'redirect_uri': _redirectUri,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'scope': _scope,
        },
      );

      logger.info('Starting OAuth2 login flow');

      _authCompleter = Completer<String?>();
      _browser = ChromeSafariBrowser();

      await _browser!.open(
        url: WebUri(authorizationUrl.toString()),
        settings: ChromeSafariBrowserSettings(
          shareState: CustomTabsShareState.SHARE_STATE_OFF,
          showTitle: true,
        ),
      );

      // Step 2: Wait for authorization code
      // User needs time to enter credentials and authorize the app
      // No timeout here - let user complete the authentication process
      // The browser will be closed automatically if user cancels or completes
      final authorizationCode = await _authCompleter!.future;

      if (authorizationCode == null) {
        logger.warning('Authorization cancelled or failed');
        return false;
      }

      logger.info('Authorization code received, exchanging for tokens');

      final tokenData = await _oauth2Service.exchangeCodeForTokens(
        authorizationCode: authorizationCode,
        codeVerifier: _codeVerifier!,
        clientId: clientId,
        redirectUri: _redirectUri,
        serverUrl: serverUrl,
      );

      if (tokenData == null) {
        logger.warning('Token exchange failed');
        return false;
      }

      await _oauth2Service.storeTokens(
        accessToken: tokenData['access_token'] as String,
        refreshToken: tokenData['refresh_token'] as String,
        expiresIn: tokenData['expires_in'] as int,
        clientId: clientId,
      );

      logger.info('OAuth2 login successful');
      return true;
    } catch (e) {
      logger.severe('Error during OAuth2 login: $e');
      // Close browser if still open
      _closeBrowser();
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(null);
      }
      // Re-throw to allow cubit to handle error message
      rethrow;
    } finally {
      _codeVerifier = null;
      _authCompleter = null;
      _browser = null;
    }
  }

  /// Close browser if still open
  void _closeBrowser() {
    try {
      if (_browser != null) {
        _browser!.close();
        logger.info('Browser closed');
      }
    } catch (e) {
      logger.warning('Error closing browser: $e');
    }
  }

  void handleAuthCallback(
    String? authorizationCode, {
    String? error,
    String? errorDescription,
  }) {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      if (error != null) {
        logger.warning('OAuth2 error: $error - $errorDescription');
        _authCompleter!.complete(null);
      } else {
        _authCompleter!.complete(authorizationCode);
      }
    }
  }

  Future<String?> getAccessToken() async {
    return await _oauth2Service.getAccessToken();
  }
}

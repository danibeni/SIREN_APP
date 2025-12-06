import 'dart:async';
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

  Future<bool> login({
    required String serverUrl,
    required String clientId,
  }) async {
    try {
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

      final authorizationCode = await _authCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          logger.warning('OAuth2 authentication timeout');
          return null;
        },
      );

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
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(null);
      }
      return false;
    } finally {
      _codeVerifier = null;
      _authCompleter = null;
      _browser = null;
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

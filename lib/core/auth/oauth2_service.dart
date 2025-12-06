import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

@lazySingleton
class OAuth2Service {
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;
  final Logger _logger;

  static const String _accessTokenKey = 'oauth2_access_token';
  static const String _refreshTokenKey = 'oauth2_refresh_token';
  static const String _tokenExpiryKey = 'oauth2_token_expiry';
  static const String _clientIdKey = 'oauth2_client_id';

  OAuth2Service(this._secureStorage, this._dio, this._logger);

  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required String clientId,
  }) async {
    final expiryTimestamp =
        DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      _secureStorage.write(
        key: _tokenExpiryKey,
        value: expiryTimestamp.toString(),
      ),
      _secureStorage.write(key: _clientIdKey, value: clientId),
    ]);

    _logger.info('OAuth2 tokens stored successfully');
  }

  Future<String?> getAccessToken() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null) {
      _logger.warning('No access token found');
      return null;
    }

    final isExpired = await _isTokenExpired();
    if (isExpired) {
      _logger.info('Access token expired, refreshing...');
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        return await _secureStorage.read(key: _accessTokenKey);
      } else {
        _logger.warning('Failed to refresh token');
        return null;
      }
    }

    return token;
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<String?> getClientId() async {
    return await _secureStorage.read(key: _clientIdKey);
  }

  Future<bool> hasValidToken() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    if (accessToken == null) {
      return false;
    }

    final isExpired = await _isTokenExpired();
    if (isExpired) {
      return await refreshAccessToken();
    }

    return true;
  }

  Future<bool> _isTokenExpired() async {
    final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
    if (expiryString == null) {
      return true;
    }

    final expiryTimestamp = int.tryParse(expiryString);
    if (expiryTimestamp == null) {
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final bufferTime = 5 * 60 * 1000;
    return now >= (expiryTimestamp - bufferTime);
  }

  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      final clientId = await getClientId();

      if (refreshToken == null || clientId == null) {
        _logger.warning('Missing refresh token or client ID');
        return false;
      }

      final serverUrl = await _secureStorage.read(key: 'server_url');
      if (serverUrl == null) {
        _logger.warning('No server URL configured');
        return false;
      }

      _logger.info('Refreshing access token');

      final response = await _dio.post(
        '$serverUrl/oauth/token',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await storeTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String? ?? refreshToken,
          expiresIn: data['expires_in'] as int,
          clientId: clientId,
        );
        _logger.info('Access token refreshed successfully');
        return true;
      } else {
        _logger.warning('Failed to refresh token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.severe('Error refreshing access token: $e');
      return false;
    }
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _tokenExpiryKey),
      _secureStorage.delete(key: _clientIdKey),
    ]);
    _logger.info('OAuth2 tokens cleared');
  }

  Future<Map<String, dynamic>?> exchangeCodeForTokens({
    required String authorizationCode,
    required String codeVerifier,
    required String clientId,
    required String redirectUri,
    required String serverUrl,
  }) async {
    try {
      _logger.info('Exchanging authorization code for tokens');

      final response = await _dio.post(
        '$serverUrl/oauth/token',
        data: {
          'grant_type': 'authorization_code',
          'code': authorizationCode,
          'redirect_uri': redirectUri,
          'client_id': clientId,
          'code_verifier': codeVerifier,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        _logger.info('Token exchange successful');
        return response.data as Map<String, dynamic>;
      } else {
        _logger.warning('Token exchange failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.severe('Error exchanging code for tokens: $e');
      return null;
    }
  }
}

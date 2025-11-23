import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

/// Authentication service for OpenProject API
/// 
/// Handles secure storage and retrieval of API credentials.
/// Supports API Key authentication (MVP) with future OAuth 2.0 support.
class AuthService {
  final FlutterSecureStorage _secureStorage;
  final Logger logger;

  static const String _apiKeyKey = 'openproject_api_key';
  static const String _baseUrlKey = 'openproject_base_url';

  AuthService({
    required FlutterSecureStorage secureStorage,
    required this.logger,
  }) : _secureStorage = secureStorage;

  /// Store API key securely
  /// 
  /// The API key is used with Basic Auth:
  /// - Username: "apikey" (literal string)
  /// - Password: The API key
  Future<void> storeApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _apiKeyKey, value: apiKey);
      logger.info('API key stored successfully');
    } catch (e) {
      logger.severe('Error storing API key: $e');
      rethrow;
    }
  }

  /// Retrieve stored API key
  /// 
  /// Returns null if no API key is stored
  Future<String?> getApiKey() async {
    try {
      return await _secureStorage.read(key: _apiKeyKey);
    } catch (e) {
      logger.severe('Error retrieving API key: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  /// 
  /// Returns true if an API key is stored
  Future<bool> isAuthenticated() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Clear stored credentials
  /// 
  /// Used for logout functionality
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _apiKeyKey);
      await _secureStorage.delete(key: _baseUrlKey);
      logger.info('Credentials cleared');
    } catch (e) {
      logger.severe('Error clearing credentials: $e');
      rethrow;
    }
  }

  /// Store OpenProject base URL
  /// 
  /// Base URL should be the server URL without the API path.
  /// Format: https://your-openproject-instance.com
  /// The API path `/api/v3/` will be appended automatically by DioClient.
  /// 
  /// Example: If your OpenProject instance is at https://openproject.example.com,
  /// store "https://openproject.example.com" (without trailing slash or /api/v3/)
  Future<void> storeBaseUrl(String baseUrl) async {
    try {
      // Normalize URL: remove trailing slash
      final normalizedUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      
      await _secureStorage.write(key: _baseUrlKey, value: normalizedUrl);
      logger.info('Base URL stored successfully: $normalizedUrl');
    } catch (e) {
      logger.severe('Error storing base URL: $e');
      rethrow;
    }
  }

  /// Retrieve stored base URL
  /// 
  /// Returns the server base URL (without /api/v3/ path).
  /// Returns null if no base URL is stored.
  /// 
  /// To get the full API base URL, use getApiBaseUrl() instead.
  Future<String?> getBaseUrl() async {
    try {
      return await _secureStorage.read(key: _baseUrlKey);
    } catch (e) {
      logger.severe('Error retrieving base URL: $e');
      return null;
    }
  }

  /// Get the full API base URL with /api/v3/ path
  /// 
  /// Returns the complete base URL for OpenProject API v3 requests.
  /// Format: https://your-instance.com/api/v3
  /// Returns null if base URL is not stored.
  Future<String?> getApiBaseUrl() async {
    final baseUrl = await getBaseUrl();
    if (baseUrl == null) {
      return null;
    }
    
    // Ensure /api/v3 is appended correctly
    return '$baseUrl/api/v3';
  }

  /// Generate Basic Auth header value
  /// 
  /// Returns Base64 encoded "apikey:{API_KEY}" for Basic Auth
  Future<String?> getBasicAuthHeader() async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    // Basic Auth: Username is "apikey", Password is the API key
    final credentials = 'apikey:$apiKey';
    final bytes = utf8.encode(credentials);
    final base64Str = base64.encode(bytes);
    return 'Basic $base64Str';
  }
}

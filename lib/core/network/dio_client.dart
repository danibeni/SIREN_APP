import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../auth/auth_interceptor.dart';
import '../auth/auth_service.dart';

/// Dio client factory for OpenProject API
/// 
/// Creates and configures Dio instance with authentication and error handling
class DioClient {
  final AuthService authService;
  final Logger logger;

  DioClient({
    required this.authService,
    required Logger? logger,
  }) : logger = logger ?? Logger('DioClient');

  /// Create configured Dio instance for OpenProject API v3
  /// 
  /// [baseUrl] - OpenProject server base URL (e.g., https://your-instance.com)
  /// The method automatically appends `/api/v3` to construct the API base URL.
  /// 
  /// According to OpenProject API v3 documentation:
  /// - Base URL: All API requests must be directed to `/api/v3/`
  /// - Content Format: `application/hal+json` for both requests and responses
  Dio createDio(String baseUrl) {
    // Normalize base URL: remove trailing slash
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    
    // Construct API base URL: server URL + /api/v3
    final apiBaseUrl = '$normalizedBaseUrl/api/v3';
    
    final dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/hal+json',
          'Accept': 'application/hal+json',
        },
      ),
    );

    // Add authentication interceptor
    dio.interceptors.add(
      AuthInterceptor(
        authService: authService,
        logger: logger,
      ),
    );

    // Add logging interceptor for debugging
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => logger.info(object.toString()),
      ),
    );

    return dio;
  }
}


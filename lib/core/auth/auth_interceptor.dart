import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'auth_service.dart';

/// Dio interceptor for OpenProject API authentication
/// 
/// Automatically adds Basic Auth header to all API requests
class AuthInterceptor extends Interceptor {
  final AuthService authService;
  final Logger logger;

  AuthInterceptor({
    required this.authService,
    required this.logger,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final authHeader = await authService.getBasicAuthHeader();
      if (authHeader != null) {
        options.headers['Authorization'] = authHeader;
      }

      // Set required headers for OpenProject API v3
      options.headers['Content-Type'] = 'application/hal+json';
      options.headers['Accept'] = 'application/hal+json';

      handler.next(options);
    } catch (e) {
      logger.severe('Error in AuthInterceptor: $e');
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.severe('API Error: ${err.response?.statusCode} - ${err.message}');
    handler.next(err);
  }
}


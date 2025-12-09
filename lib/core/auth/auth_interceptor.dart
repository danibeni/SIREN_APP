import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/auth/auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService authService;
  final Logger logger;

  AuthInterceptor({required this.authService, required this.logger});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final accessToken = await authService.getAccessToken();
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Only set Content-Type if not FormData (multipart)
      // Dio automatically sets multipart/form-data with boundary for FormData
      if (options.data is! FormData) {
        options.headers['Content-Type'] = 'application/hal+json';
      }
      options.headers['Accept'] = 'application/hal+json';

      handler.next(options);
    } catch (e) {
      logger.severe('Error in AuthInterceptor: $e');
      handler.reject(DioException(requestOptions: options, error: e));
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.severe('API Error: ${err.response?.statusCode} - ${err.message}');
    handler.next(err);
  }
}

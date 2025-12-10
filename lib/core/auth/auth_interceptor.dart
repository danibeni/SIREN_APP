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
    // Enhanced error detection for server inaccessibility
    String errorMessage = err.message ?? 'Unknown error';
    
    // Detect server inaccessibility scenarios
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Server connection timeout. The OpenProject server may be unreachable via Wi-Fi.';
      logger.severe('Server connection timeout: ${err.requestOptions.uri}');
    } else if (err.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Server response timeout. The OpenProject server may be slow or unreachable.';
      logger.severe('Server response timeout: ${err.requestOptions.uri}');
    } else if (err.type == DioExceptionType.connectionError) {
      errorMessage = 'Cannot connect to server. Please verify the OpenProject server is accessible via Wi-Fi.';
      logger.severe('Connection error: ${err.message}');
    } else if (err.response?.statusCode == null) {
      // No response received - likely network/server issue
      errorMessage = 'Server unreachable. Please check your Wi-Fi connection and verify the OpenProject server is accessible.';
      logger.severe('Server unreachable: ${err.requestOptions.uri} - ${err.message}');
    } else {
      logger.severe('API Error: ${err.response?.statusCode} - ${err.message}');
    }
    
    // Enhance error with clearer message
    final enhancedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: err.error,
      message: errorMessage,
    );
    
    handler.next(enhancedError);
  }
}

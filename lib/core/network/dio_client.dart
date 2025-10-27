import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../error/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  DioClient({
    required FlutterSecureStorage secureStorage,
    required Logger logger,
  })  : _secureStorage = secureStorage,
        _logger = logger {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
        },
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      _loggingInterceptor(),
      _errorInterceptor(),
    ]);
  }

  // Auth Interceptor - Adds token to requests
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers[ApiConstants.authorization] =
              '${ApiConstants.bearer} $token';
        }
        handler.next(options);
      },
    );
  }

  // Logging Interceptor
  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
        _logger.d('Headers: ${options.headers}');
        _logger.d('Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.i(
          'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
        );
        _logger.d('Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e(
          'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
        );
        _logger.e('Message: ${error.message}');
        handler.next(error);
      },
    );
  }

  // Error Interceptor - Handles token refresh
  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          try {
            final refreshToken =
                await _secureStorage.read(key: AppConstants.refreshTokenKey);
            if (refreshToken != null) {
              final response = await _dio.post(
                ApiConstants.refreshToken,
                data: {'refresh_token': refreshToken},
              );

              final newToken = response.data['access_token'];
              await _secureStorage.write(
                key: AppConstants.tokenKey,
                value: newToken,
              );

              // Retry the original request
              final opts = error.requestOptions;
              opts.headers[ApiConstants.authorization] =
                  '${ApiConstants.bearer} $newToken';
              final cloneReq = await _dio.fetch(opts);
              return handler.resolve(cloneReq);
            }
          } catch (e) {
            _logger.e('Token refresh failed: $e');
            // Clear tokens and throw authentication exception
            await _secureStorage.delete(key: AppConstants.tokenKey);
            await _secureStorage.delete(key: AppConstants.refreshTokenKey);
          }
        }
        handler.next(error);
      },
    );
  }

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle Dio Errors
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'Server error occurred';

        if (statusCode == 401) {
          return AuthenticationException(message: message);
        } else if (statusCode == 422) {
          return ValidationException(
            message: message,
            errors: error.response?.data['errors'],
          );
        } else {
          return ServerException(
            message: message,
            statusCode: statusCode,
          );
        }

      case DioExceptionType.cancel:
        return ServerException(message: 'Request cancelled');

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'No internet connection. Please check your network.',
        );

      case DioExceptionType.badCertificate:
        return NetworkException(message: 'Invalid SSL certificate');

      case DioExceptionType.unknown:
        return ServerException(
          message: error.message ?? 'An unexpected error occurred',
        );
    }
  }
}

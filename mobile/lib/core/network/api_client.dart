import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException($code): $message';
}

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  // Default to localhost:4000 (Windows/Web), or 10.0.2.2:4000 for Android emulator
  static const String defaultBaseUrl = 'http://127.0.0.1:4000/api/v1';

  ApiClient({
    required this.tokenStorage,
    String baseUrl = defaultBaseUrl,
    Dio? customDio,
  }) : dio = customDio ?? Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          final response = error.response;
          if (response?.data != null && response?.data is Map) {
            final errorData = response!.data['error'];
            if (errorData != null) {
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  response: error.response,
                  error: ApiException(
                    code: errorData['code'] ?? 'SERVER_ERROR',
                    message: errorData['message'] ?? 'Terjadi kesalahan pada server',
                    statusCode: response.statusCode,
                    details: errorData['details'],
                  ),
                ),
              );
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return dio.delete<T>(path);
  }
}

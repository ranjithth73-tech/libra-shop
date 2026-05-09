import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip token for public endpoints — they don't need auth

          final isPublic =
              options.path.contains('login') ||
              options.path.contains('register') ||
              options.path.contains('token/refresh');

          if (!isPublic) {
            final token = await TokenStorage.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isAuthPath =
              path.contains('login') ||
              path.contains('register') ||
              path.contains('token/refresh');

          if (error.response?.statusCode == 401 && !isAuthPath) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final token = await TokenStorage.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
    return dio;
  }

  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await dio.post(
        ApiConstants.tokenRefresh,
        data: {'refresh': refreshToken},
      );

      await TokenStorage.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
      );
      return true;
    } catch (e) {
      await TokenStorage.clearTokens();
      return false;
    }
  }

  // Creates a plain Dio with optional token in headers
  // Used when already have the token and want to pass it directly
  static Dio createDio({String? token}) {
    return Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'content-type': 'application/json',
          'Accept':
              'application/json', // Only adds Authorization header if token is not null
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }
  // Reads token from secure storage then creates authenticated Dio
  // Used by screens like cart, orders, profile that need auth

  static Future<Dio> authenticatedDio() async {
    final token = await TokenStorage.getAccessToken();
    return createDio(token: token);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'env.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              try {
                final response = await _dio.post('/auth/refresh', data: {
                  'refreshToken': refreshToken,
                });
                
                if (response.statusCode == 200) {
                  final data = response.data['data'];
                  await _storage.write(key: 'access_token', value: data['accessToken']);
                  
                  // Retry the original request
                  final options = error.requestOptions;
                  options.headers['Authorization'] = 'Bearer ${data['accessToken']}';
                  final retryResponse = await _dio.fetch(options);
                  handler.resolve(retryResponse);
                  return;
                }
              } catch (e) {
                // Refresh failed, clear tokens and redirect to login
                await _storage.deleteAll();
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

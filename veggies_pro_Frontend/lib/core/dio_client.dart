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

    // Debug logging
    print('DioClient initialized with base URL: ${Env.apiBase}');

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
          print('DioClient error: ${error.message}');
          print('Error type: ${error.type}');
          print('Response: ${error.response?.data}');
          
          final statusCode = error.response?.statusCode;
          
          // Handle authentication errors
          if (statusCode == 401 || statusCode == 403) {
            // Try to refresh token first for 401 errors
            if (statusCode == 401) {
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
                  print('Token refresh failed: $e');
                  // Refresh failed, proceed to logout
                }
              }
            }
            
            // Clear tokens and redirect to login
            await _storage.deleteAll();
            
            // Show logout message and redirect
            // Note: We can't use context here directly, so we'll handle this in the calling code
            print('Authentication failed - tokens cleared');
          }
          
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

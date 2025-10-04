import 'package:dio/dio.dart';

class ErrorHandler {
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      // Check for network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Please check your internet connection.';
      }
      
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to server. Please check your internet connection.';
      }

      if (error.type == DioExceptionType.cancel) {
        return 'Request was cancelled.';
      }

      // Extract error message from response
      if (error.response?.data != null) {
        final responseData = error.response!.data;
        
        // Try to get error message from various possible fields
        if (responseData is Map) {
          final errorMsg = responseData['error'] ?? 
                          responseData['message'] ?? 
                          responseData['msg'] ??
                          responseData['detail'];
          
          if (errorMsg != null && errorMsg is String && errorMsg.isNotEmpty) {
            return errorMsg;
          }
        } else if (responseData is String) {
          return responseData;
        }
      }

      // Default messages based on status code
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        switch (statusCode) {
          case 400:
            return 'Invalid request. Please check your input.';
          case 401:
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied. You don\'t have permission.';
          case 404:
            return 'Resource not found.';
          case 409:
            return 'Conflict. This resource already exists.';
          case 422:
            return 'Validation failed. Please check your input.';
          case 429:
            return 'Too many requests. Please try again later.';
          case 500:
            return 'Server error. Please try again later.';
          case 502:
            return 'Bad gateway. Server is temporarily unavailable.';
          case 503:
            return 'Service unavailable. Please try again later.';
          default:
            return 'An error occurred (Code: $statusCode). Please try again.';
        }
      }
    }

    // Generic error message
    final errorString = error.toString();
    if (errorString.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}


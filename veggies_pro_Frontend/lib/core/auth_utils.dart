import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class AuthUtils {
  static const _storage = FlutterSecureStorage();

  /// Clears all authentication tokens and redirects to login
  static Future<void> logout(BuildContext context) async {
    try {
      // Clear all stored tokens
      await _storage.deleteAll();
      
      // Show logout message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to login screen and clear navigation stack
        // Use go() to replace the entire navigation stack
        context.go('/auth/phone-login');
      }
    } catch (e) {
      print('Error during logout: $e');
      // Even if there's an error, try to navigate to login
      if (context.mounted) {
        context.go('/auth/phone-login');
      }
    }
  }

  /// Checks if user is authenticated by verifying token exists
  static Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(key: 'access_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  /// Clears all stored data (tokens, user data, etc.)
  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  /// Handles authentication errors and logs out if needed
  static Future<void> handleAuthError(BuildContext context, dynamic error) async {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      
      // Handle 401 Unauthorized or 403 Forbidden
      if (statusCode == 401 || statusCode == 403) {
        await logout(context);
        return;
      }
    }
    
    // For other errors, show appropriate message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication error: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

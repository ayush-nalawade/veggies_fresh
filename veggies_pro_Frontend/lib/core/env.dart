import 'dart:io';

class Env {
  // Use different URLs for different platforms
  static String get apiBase {
    if (Platform.isAndroid) {
      // For Android emulator, try multiple IPs
      // First try the host machine IP, then fallback to emulator IP
      return 'http://192.168.0.2:3000';
      // return 'http://10.174.64.236:3000';
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost
      return 'http://localhost:3000';
    } else {
      // For web and other platforms
      return 'http://localhost:3000';
    }
  }
  
  // Alternative API base for Android if the primary one fails
  static const String androidApiBaseAlt = 'http://10.0.2.2:3000';
  
  // Razorpay Configuration
  // TODO: Replace with your actual Razorpay Key ID from https://dashboard.razorpay.com/app/keys
  // For testing, use the test key ID (starts with 'rzp_test_')
  // For production, use the live key ID (starts with 'rzp_live_')
  static const String razorpayKeyId = 'rzp_test_RSXHAozrHExWxD';
  
  // Google Sign-In configuration
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
}

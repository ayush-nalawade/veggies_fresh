import 'dart:io';

class Env {
  // Use different URLs for different platforms
  static String get apiBase {
    if (Platform.isAndroid) {
      // For Android emulator, try multiple IPs
      // First try the host machine IP, then fallback to emulator IP
      return 'http://192.168.0.4:3000';
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
  
  static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';
  
  // Google Sign-In configuration
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';
}

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import 'auth_utils.dart';
import 'env.dart';

/// Payment service for handling Razorpay payments with industry-standard security practices
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  late Razorpay _razorpay;
  bool _isInitialized = false;
  BuildContext? _currentContext;
  Function()? _onPaymentSuccess;
  Function(String)? _onPaymentError;

  /// Initialize Razorpay with proper configuration
  void initialize() {
    if (_isInitialized) return;
    
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _isInitialized = true;
      print('Razorpay initialized successfully');
    } catch (e) {
      print('Failed to initialize Razorpay: $e');
      throw Exception('Failed to initialize Razorpay: $e');
    }
  }

  /// Dispose Razorpay resources
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
    }
  }

  /// Process payment with comprehensive error handling
  Future<void> processPayment({
    required BuildContext context,
    required Map<String, dynamic> orderData,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      _currentContext = context;
      _onPaymentSuccess = onSuccess;
      _onPaymentError = onError;

      // Check Razorpay key configuration
      if (Env.razorpayKeyId == 'YOUR_RAZORPAY_KEY_ID') {
        onError('Razorpay configuration error. Please contact support.');
        print('ERROR: Razorpay key not configured. Please set your actual Razorpay key in env.dart');
        return;
      }

      // Validate order data
      if (!_validateOrderData(orderData)) {
        onError('Invalid order data. Please try again.');
        return;
      }

      // Initialize Razorpay if not already done
      initialize();

      // Create Razorpay options with security best practices
      final options = _createRazorpayOptions(orderData);
      
      print('Opening Razorpay with options: $options');

      // Open Razorpay checkout
      _razorpay.open(options);
    } catch (e) {
      print('Payment initialization error: $e');
      onError('Failed to initialize payment: ${e.toString()}');
    }
  }

  /// Create Razorpay options with security best practices
  Map<String, dynamic> _createRazorpayOptions(Map<String, dynamic> orderData) {
    return {
      'key': Env.razorpayKeyId,
      'amount': orderData['amount'],
      'currency': 'INR',
      'name': 'VeggieFresh',
      'description': 'Fresh vegetables delivery',
      'order_id': orderData['razorpayOrderId'],
      'prefill': {
        'email': _getUserEmail(),
        'contact': _getUserPhone(),
        'name': _getUserName(),
      },
      'theme': {
        'color': '#2E7D32',
        'backdrop_color': '#000000',
      },
      'modal': {
        'backdropclose': false,
        'escape': true,
        'handleback': true,
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'callback_url': 'https://veggiefresh.com/payment/callback',
      'notes': {
        'order_id': orderData['orderId']?.toString() ?? '',
        'merchant_order_id': orderData['orderId']?.toString() ?? '',
      },
    };
  }

  /// Validate order data before processing payment
  bool _validateOrderData(Map<String, dynamic> orderData) {
    try {
      // Check required fields
      if (orderData['amount'] == null || orderData['razorpayOrderId'] == null) {
        return false;
      }

      // Validate amount (should be positive and in paise)
      final amount = orderData['amount'];
      if (amount is! int || amount <= 0) {
        return false;
      }

      // Validate order ID format
      final orderId = orderData['razorpayOrderId'];
      if (orderId is! String || orderId.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      print('Order data validation error: $e');
      return false;
    }
  }

  /// Get user email for prefill (with fallback)
  String _getUserEmail() {
    // In a real app, get this from user profile or secure storage
    return 'user@veggiefresh.com';
  }

  /// Get user phone for prefill (with fallback)
  String _getUserPhone() {
    // In a real app, get this from user profile or secure storage
    return '1234567890';
  }

  /// Get user name for prefill (with fallback)
  String _getUserName() {
    // In a real app, get this from user profile or secure storage
    return 'VeggieFresh Customer';
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print('Payment success: ${response.paymentId}');
      
      if (_currentContext == null || !_currentContext!.mounted) {
        print('Context not available for payment success');
        return;
      }

      // Show loading indicator
      _showPaymentProcessingDialog();

      // Verify payment with backend
      final isVerified = await _verifyPaymentWithBackend(response);
      
      if (isVerified) {
        // Hide loading dialog
        if (_currentContext!.mounted) {
          Navigator.of(_currentContext!).pop();
        }

        // Show success message
        _showSuccessMessage();
        
        // Call success callback
        _onPaymentSuccess?.call();
      } else {
        // Hide loading dialog
        if (_currentContext!.mounted) {
          Navigator.of(_currentContext!).pop();
        }

        // Show verification failed message
        _showErrorMessage('Payment verification failed. Please contact support.');
      }
    } catch (e) {
      print('Payment success handling error: $e');
      
      // Hide loading dialog if showing
      if (_currentContext != null && _currentContext!.mounted) {
        Navigator.of(_currentContext!).pop();
      }

      _showErrorMessage('Payment processing failed. Please contact support.');
    }
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment error: ${response.code} - ${response.message}');
    
    String errorMessage = 'Payment failed. Please try again.';
    
    // Provide specific error messages based on error code
    switch (response.code) {
      case Razorpay.PAYMENT_CANCELLED:
        errorMessage = 'Payment was cancelled by user.';
        break;
      case Razorpay.NETWORK_ERROR:
        errorMessage = 'Network error. Please check your internet connection.';
        break;
      case Razorpay.INVALID_OPTIONS:
        errorMessage = 'Invalid payment options. Please try again.';
        break;
      default:
        // Check for common error messages
        final message = response.message ?? '';
        if (message.toLowerCase().contains('key')) {
          errorMessage = 'Payment configuration error. Please contact support.';
        } else if (message.toLowerCase().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (message.toLowerCase().contains('amount')) {
          errorMessage = 'Invalid payment amount. Please try again.';
        } else {
          errorMessage = 'Payment failed: $message';
        }
    }

    _showErrorMessage(errorMessage);
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External wallet selected: ${response.walletName}');
    
    if (_currentContext != null && _currentContext!.mounted) {
      ScaffoldMessenger.of(_currentContext!).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Verify payment with backend
  Future<bool> _verifyPaymentWithBackend(PaymentSuccessResponse response) async {
    try {
      final verifyResponse = await DioClient().dio.post('/checkout/verify-payment', data: {
        'razorpayOrderId': response.orderId,
        'paymentId': response.paymentId,
        'signature': response.signature,
        'orderId': response.orderId,
      });

      return verifyResponse.statusCode == 200;
    } catch (e) {
      print('Payment verification error: $e');
      
      // Handle authentication errors
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          if (_currentContext != null && _currentContext!.mounted) {
            await AuthUtils.logout(_currentContext!);
          }
        }
      }
      
      return false;
    }
  }

  /// Show payment processing dialog
  void _showPaymentProcessingDialog() {
    if (_currentContext == null || !_currentContext!.mounted) return;

    showDialog(
      context: _currentContext!,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Processing payment...'),
          ],
        ),
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage() {
    if (_currentContext == null || !_currentContext!.mounted) return;

    ScaffoldMessenger.of(_currentContext!).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Order placed successfully.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(String message) {
    if (_currentContext == null || !_currentContext!.mounted) return;

    ScaffoldMessenger.of(_currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Retry payment logic can be implemented here
            _onPaymentError?.call('Retry payment');
          },
        ),
      ),
    );
  }
}


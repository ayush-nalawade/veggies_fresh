import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/dio_client.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String phone;
  
  const OTPVerificationScreen({
    super.key,
    required this.phone,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 30;
  bool _canResend = false;
  String? _otpErrorMessage;
  bool _isOtpErrorVisible = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer = 0; // Stop the timer
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_resendTimer > 0) {
          setState(() {
            _resendTimer--;
          });
          _startResendTimer();
        } else {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  void _showOtpError(String message) {
    setState(() {
      _otpErrorMessage = message;
      _isOtpErrorVisible = true;
    });

    // Clear the error message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isOtpErrorVisible = false;
          _otpErrorMessage = null;
        });
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 4-digit OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await DioClient().dio.post('/auth/verify-otp', data: {
        'phone': widget.phone,
        'otp': _otpController.text,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        if (data['isNewUser'] == true) {
          // New user - redirect to details screen
          if (mounted) {
            context.push('/auth/user-details', extra: {
              'tempToken': data['tempToken'],
            });
          }
        } else {
          // Existing user - save tokens and go to home
          const storage = FlutterSecureStorage();
          await storage.write(key: 'access_token', value: data['accessToken']);
          await storage.write(key: 'refresh_token', value: data['refreshToken']);
          
          if (mounted) {
            context.go('/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Clear the OTP input when verification fails
        _otpController.clear();

        // Check if it's an OTP-related error (you can customize this based on your backend response)
        String errorMessage = 'OTP verification failed';
        if (e.toString().toLowerCase().contains('invalid') ||
            e.toString().toLowerCase().contains('incorrect') ||
            e.toString().toLowerCase().contains('wrong')) {
          errorMessage = 'Incorrect OTP. Please try again.';
        }

        _showOtpError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      final response = await DioClient().dio.post('/auth/send-otp', data: {
        'phone': widget.phone,
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _startResendTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.sms,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Title
              Text(
                'Verify Your Number',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a 4-digit code to +91 ${widget.phone}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // OTP input field
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 60,
                  fieldWidth: 60,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.grey[100],
                  selectedFillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.grey[300],
                  selectedColor: Theme.of(context).colorScheme.primary,
                ),
                enableActiveFill: true,
                onCompleted: (value) {
                  _verifyOTP();
                },
                onChanged: (value) {},
              ),

              // Error message
              if (_isOtpErrorVisible && _otpErrorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _otpErrorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),
              
              // Verify button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              
              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_canResend)
                    TextButton(
                      onPressed: _isResending ? null : _resendOTP,
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resend'),
                    )
                  else
                    Text(
                      'Resend in ${_resendTimer}s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

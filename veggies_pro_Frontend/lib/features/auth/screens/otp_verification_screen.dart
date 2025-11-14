import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/dio_client.dart';
import '../../../core/error_handler.dart';

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
  int _otpTimerSeconds = 60; // OTP valid for 1 minute
  bool _canResend = false;
  String? _otpErrorMessage;
  bool _isOtpErrorVisible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startOTPTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startOTPTimer() {
    setState(() {
      _canResend = false;
      _otpTimerSeconds = 60; // Reset to 60 seconds
    });

    _timer?.cancel(); // Cancel any existing timer
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_otpTimerSeconds > 0) {
        setState(() {
          _otpTimerSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 4-digit OTP'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        if (data['isNewUser'] == true) {
          // New user - redirect to details screen
          context.push('/auth/user-details', extra: {
            'tempToken': data['tempToken'],
          });
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
      if (!mounted) return;
      
      // Clear the OTP input when verification fails
      _otpController.clear();

      // Extract meaningful error message
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      _showOtpError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    try {
      final response = await DioClient().dio.post('/auth/send-otp', data: {
        'phone': widget.phone,
      });

      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('OTP sent successfully to your phone')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Clear any previous OTP errors
        setState(() {
          _isOtpErrorVisible = false;
          _otpErrorMessage = null;
          _otpController.clear();
        });
        
        // Restart the timer
        _startOTPTimer();
      }
    } catch (e) {
      if (!mounted) return;
      
      // Extract meaningful error message
      final errorMessage = ErrorHandler.extractErrorMessage(e);
      
      // Check if it's a rate limiting error (429 status)
      final isRateLimitError = e.toString().contains('429') || 
                              errorMessage.toLowerCase().contains('wait') ||
                              errorMessage.toLowerCase().contains('retry');
      
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isRateLimitError ? Icons.timer_outlined : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: isRateLimitError ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      // If rate limited, extract retry time and update timer if available
      if (isRateLimitError) {
        // Try to extract retry time from error message
        final retryMatch = RegExp(r'(\d+)\s*seconds?').firstMatch(errorMessage);
        if (retryMatch != null) {
          final retrySeconds = int.tryParse(retryMatch.group(1) ?? '');
          if (retrySeconds != null && retrySeconds > 0) {
            setState(() {
              _otpTimerSeconds = retrySeconds;
              _canResend = false;
            });
            _startOTPTimer();
          }
        }
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
              const SizedBox(height: 20),
              
              // OTP Timer Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _otpTimerSeconds > 0 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _otpTimerSeconds > 0
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _otpTimerSeconds > 0 ? Icons.timer : Icons.timer_off,
                      color: _otpTimerSeconds > 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _otpTimerSeconds > 0
                          ? 'OTP expires in ${_formatTimer(_otpTimerSeconds)}'
                          : 'OTP expired',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _otpTimerSeconds > 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
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
              const SizedBox(height: 24),
              
              // Resend OTP Section
              Column(
                children: [
                  Text(
                    "Didn't receive the code?",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _canResend
                      ? ElevatedButton.icon(
                          onPressed: _isResending ? null : _resendOTP,
                          icon: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(_isResending ? 'Resending...' : 'Resend OTP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Resend in ${_formatTimer(_otpTimerSeconds)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
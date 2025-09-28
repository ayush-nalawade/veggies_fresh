# OTP Authentication Setup Guide

This guide explains how to set up the OTP-based authentication system for the VeggieFresh mobile application.

## Backend Setup

### 1. Environment Variables

Add the following environment variables to your `.env` file:

```env
# Twilio Configuration
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=your-twilio-phone-number
```

### 2. Twilio Account Setup

1. Sign up for a Twilio account at [twilio.com](https://www.twilio.com)
2. Get your Account SID and Auth Token from the Twilio Console
3. Purchase a phone number from Twilio (required for sending SMS)
4. Add the credentials to your `.env` file

### 3. Install Dependencies

The Twilio package has already been installed. If you need to reinstall:

```bash
npm install twilio
```

### 4. Database Models

The following models have been created/updated:

- **OTP Model**: Stores OTP codes with expiration and usage tracking
- **User Model**: Updated to support phone-based authentication with `isPhoneVerified` field

### 5. API Endpoints

New authentication endpoints:

- `POST /auth/send-otp` - Send OTP to phone number
- `POST /auth/verify-otp` - Verify OTP and check if user exists
- `POST /auth/complete-profile` - Complete profile for new users

## Frontend Setup

### 1. Dependencies

The following packages have been added to `pubspec.yaml`:

```yaml
dependencies:
  pin_code_fields: ^8.0.1  # For OTP input UI
  fluttertoast: ^8.2.4     # For toast notifications
```

### 2. New Screens

- **PhoneLoginScreen**: Mobile number input with validation
- **OTPVerificationScreen**: 4-digit OTP input with resend functionality
- **UserDetailsScreen**: Profile completion for new users

### 3. Updated Routing

The app now redirects to phone login instead of traditional email/password login.

## Authentication Flow

### For New Users:

1. **Phone Input**: User enters 10-digit mobile number
2. **OTP Send**: System sends 4-digit OTP via Twilio SMS
3. **OTP Verification**: User enters OTP, system verifies and detects new user
4. **Profile Completion**: User enters name, optional email, and city (pre-filled as Mumbai)
5. **Dashboard**: User is redirected to home screen

### For Existing Users:

1. **Phone Input**: User enters registered mobile number
2. **OTP Send**: System sends 4-digit OTP via Twilio SMS
3. **OTP Verification**: User enters OTP, system verifies and logs in
4. **Dashboard**: User is redirected to home screen

## Security Features

- **OTP Expiration**: OTPs expire after 5 minutes
- **Single Use**: Each OTP can only be used once
- **Rate Limiting**: Prevents spam OTP requests
- **Phone Validation**: Ensures 10-digit Indian mobile numbers
- **Temporary Tokens**: New users get temporary tokens for profile completion

## Testing

### Backend Testing

Use the provided Postman collection or test with curl:

```bash
# Send OTP
curl -X POST http://localhost:3000/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "9876543210"}'

# Verify OTP
curl -X POST http://localhost:3000/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "9876543210", "otp": "1234"}'

# Complete Profile (for new users)
curl -X POST http://localhost:3000/auth/complete-profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TEMP_TOKEN" \
  -d '{"name": "John Doe", "email": "john@example.com", "city": "Mumbai"}'
```

### Frontend Testing

1. Run the Flutter app: `flutter run`
2. The app will redirect to phone login screen
3. Enter a test phone number (10 digits)
4. Check your Twilio logs for the OTP
5. Enter the OTP to complete authentication

## Troubleshooting

### Common Issues:

1. **OTP not received**: Check Twilio credentials and phone number format
2. **Invalid OTP**: Ensure OTP is entered within 5 minutes and not used before
3. **Network errors**: Verify backend is running and CORS is configured
4. **Token issues**: Clear app storage and restart authentication flow

### Debug Mode:

Enable debug logging by checking the console output for detailed authentication flow information.

## Production Considerations

1. **Twilio Costs**: Monitor SMS usage and costs
2. **Rate Limiting**: Implement stricter rate limiting for production
3. **Error Handling**: Add comprehensive error handling and user feedback
4. **Analytics**: Track authentication success rates and user behavior
5. **Backup Auth**: Consider fallback authentication methods

## Support

For issues or questions regarding the OTP authentication system, please check the logs and ensure all environment variables are properly configured.

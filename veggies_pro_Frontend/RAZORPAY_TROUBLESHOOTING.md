# Razorpay Payment Troubleshooting Guide

## Common Error: "Uh! oh! Something went wrong"

This error typically occurs due to configuration issues. Here's how to fix it:

## 1. Razorpay Key Configuration

### Issue: Razorpay Key Not Set
**Error**: "Uh! oh! Something went wrong" with Razorpay branding

**Solution**:
1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/app/keys)
2. Copy your **Key ID** (starts with `rzp_test_` for test mode)
3. Update `lib/core/env.dart`:

```dart
static const String razorpayKeyId = 'rzp_test_YOUR_ACTUAL_KEY_ID';
```

### Test vs Live Keys
- **Test Mode**: Use key starting with `rzp_test_`
- **Live Mode**: Use key starting with `rzp_live_`

## 2. Backend Integration Issues

### Check Backend Endpoints
Ensure your backend has these endpoints:

```typescript
// Create order endpoint
POST /checkout/create-order
{
  "address": { ... },
  "paymentMethod": "razorpay",
  "timeSlot": { ... }
}

// Verify payment endpoint
POST /checkout/verify-payment
{
  "razorpayOrderId": "order_xxx",
  "paymentId": "pay_xxx",
  "signature": "signature_xxx",
  "orderId": "order_xxx"
}
```

### Backend Response Format
```json
{
  "success": true,
  "data": {
    "orderId": "order_123",
    "razorpayOrderId": "order_razorpay_123",
    "amount": 10000,
    "currency": "INR"
  }
}
```

## 3. Common Configuration Issues

### Amount Format
- Razorpay expects amount in **paise** (smallest currency unit)
- ₹100 = 10000 paise
- Ensure backend sends correct amount

### Order ID Format
- Must be unique for each order
- Should be a string
- Cannot be empty or null

### Currency
- Must be "INR" for Indian Rupees
- Case sensitive

## 4. Debugging Steps

### Enable Debug Logging
The app now includes debug logging. Check console for:

```
Razorpay initialized successfully
Opening Razorpay with options: {...}
Payment error: CODE - MESSAGE
```

### Check Network Connectivity
- Ensure device has internet connection
- Check if backend is running
- Verify API endpoints are accessible

### Test with Sample Data
```dart
// Test order data
final testOrderData = {
  'orderId': 'test_order_123',
  'razorpayOrderId': 'order_razorpay_test_123',
  'amount': 10000, // ₹100 in paise
  'currency': 'INR'
};
```

## 5. Platform-Specific Issues

### Android
- Ensure `android/app/src/main/AndroidManifest.xml` has internet permission
- Check if Razorpay SDK is properly integrated

### iOS
- Ensure `ios/Runner/Info.plist` has proper configuration
- Check if Razorpay SDK is properly integrated

## 6. Error Code Reference

| Error Code | Description | Solution |
|------------|-------------|----------|
| `PAYMENT_CANCELLED` | User cancelled payment | Normal behavior, no action needed |
| `NETWORK_ERROR` | Network connectivity issue | Check internet connection |
| `INVALID_OPTIONS` | Invalid Razorpay configuration | Check key ID and options |
| `PAYMENT_ERROR` | General payment failure | Check amount, order ID, etc. |

## 7. Testing Checklist

### Before Testing
- [ ] Razorpay key ID is set correctly
- [ ] Backend is running and accessible
- [ ] Order creation endpoint works
- [ ] Payment verification endpoint works
- [ ] Device has internet connection

### Test Scenarios
- [ ] Test with valid order data
- [ ] Test payment cancellation
- [ ] Test with invalid amount
- [ ] Test with invalid order ID
- [ ] Test network error scenarios

## 8. Quick Fix Commands

### Reset Razorpay Instance
```dart
// In PaymentService
dispose();
initialize();
```

### Clear App Data
```bash
# Android
adb shell pm clear com.yourapp.package

# iOS
# Delete and reinstall app
```

## 9. Support Resources

### Razorpay Documentation
- [Razorpay Flutter Integration](https://razorpay.com/docs/payment-gateway/flutter-integration/)
- [Razorpay Dashboard](https://dashboard.razorpay.com/)

### Debug Tools
- Use Razorpay test cards for testing
- Check Razorpay webhook logs
- Monitor backend logs for errors

## 10. Production Checklist

Before going live:
- [ ] Replace test key with live key
- [ ] Test with real payment methods
- [ ] Verify webhook configuration
- [ ] Test payment verification
- [ ] Monitor error rates
- [ ] Set up proper logging

## Still Having Issues?

If the problem persists:
1. Check the console logs for specific error messages
2. Verify your Razorpay account is active
3. Ensure backend integration is working
4. Test with Razorpay's test environment first
5. Contact Razorpay support if needed

Remember: Always test in test mode before going to production!

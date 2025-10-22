# Razorpay Setup Guide - Fix "Uh! oh! Something went wrong" Error

## 🔍 Root Cause Analysis

The error "Uh! oh! Something went wrong" occurs because:

1. **Frontend**: Razorpay key is not configured (still set to placeholder)
2. **Backend**: Razorpay environment variables are not set
3. **Result**: Backend creates mock orders, but frontend can't process them with Razorpay

## 🛠️ Step-by-Step Fix

### Step 1: Get Razorpay Credentials

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Sign up/Login to your account
3. Go to **Settings** → **API Keys**
4. Copy your **Key ID** and **Key Secret**
   - For testing: Use **Test Mode** keys (start with `rzp_test_`)
   - For production: Use **Live Mode** keys (start with `rzp_live_`)

### Step 2: Configure Backend

1. **Create/Update `.env` file** in `veggies_backend/` directory:

```env
# Database
MONGO_URI=mongodb://localhost:27017/veggiefresh

# JWT
JWT_SECRET=my-super-secret-jwt-keyis-here
JWT_EXPIRES_IN=7d

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Razorpay - ADD YOUR ACTUAL KEYS HERE
RAZORPAY_KEY_ID=rzp_test_YOUR_ACTUAL_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_ACTUAL_KEY_SECRET

# Server
PORT=3000
NODE_ENV=development

# CORS
FRONTEND_URL=http://localhost:8080

# Twilio
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=your-twilio-phone-number
```

2. **Restart the backend server**:
```bash
cd veggies_backend
npm run dev
```

### Step 3: Configure Frontend

1. **Update `veggies_pro_Frontend/lib/core/env.dart`**:

```dart
// Razorpay Configuration
// Replace with your actual Razorpay Key ID from https://dashboard.razorpay.com/app/keys
// For testing, use the test key ID (starts with 'rzp_test_')
// For production, use the live key ID (starts with 'rzp_live_')
static const String razorpayKeyId = 'rzp_test_YOUR_ACTUAL_KEY_ID';
```

2. **Hot restart the Flutter app**:
```bash
cd veggies_pro_Frontend
flutter run
```

## 🧪 Testing the Fix

### Test 1: Check Backend Configuration
1. Start the backend server
2. Check console logs - you should see Razorpay initialized
3. Test the create-order endpoint with Postman

### Test 2: Check Frontend Configuration
1. Run the Flutter app
2. Try to make a payment
3. Check console logs for Razorpay initialization

### Test 3: End-to-End Payment Test
1. Add items to cart
2. Go to checkout
3. Select "Card/UPI Payment"
4. Click "Proceed to Payment"
5. You should see Razorpay payment dialog (not the error)

## 🔧 Debugging Steps

### Check Backend Logs
```bash
cd veggies_backend
npm run dev
# Look for: "Razorpay initialized" or similar message
```

### Check Frontend Logs
```bash
cd veggies_pro_Frontend
flutter run
# Look for: "Razorpay initialized successfully" in console
```

### Test with Postman
1. Import the Postman collection
2. Test the create-order endpoint
3. Check if it returns proper Razorpay order data

## 🚨 Common Issues & Solutions

### Issue 1: "Razorpay configuration error"
**Solution**: Check if the key ID is properly set in `env.dart`

### Issue 2: "Invalid payment options"
**Solution**: Check if the backend is returning proper order data

### Issue 3: "Network error"
**Solution**: Check if backend is running and accessible

### Issue 4: Backend returns mock data
**Solution**: Check if Razorpay environment variables are set in backend `.env`

## 📋 Verification Checklist

- [ ] Razorpay account created and verified
- [ ] Test mode keys obtained from dashboard
- [ ] Backend `.env` file updated with Razorpay keys
- [ ] Frontend `env.dart` updated with Razorpay key ID
- [ ] Backend server restarted
- [ ] Flutter app hot restarted
- [ ] Payment flow tested end-to-end

## 🔒 Security Notes

1. **Never commit real keys to version control**
2. **Use test keys for development**
3. **Use live keys only for production**
4. **Keep key secret secure on backend only**

## 📞 Support

If you still face issues:
1. Check the troubleshooting guide: `RAZORPAY_TROUBLESHOOTING.md`
2. Verify your Razorpay account is active
3. Check Razorpay dashboard for any account issues
4. Contact Razorpay support if needed

## 🎯 Expected Result

After following these steps:
- ✅ Razorpay payment dialog should open
- ✅ No "Uh! oh! Something went wrong" error
- ✅ Payment processing should work
- ✅ Success/error handling should work properly

Remember: Always test in test mode before going to production!

import express from 'express';
import { register, login, getGoogleAuthUrl, googleCallback, refreshToken, logout, sendOTPToPhone, verifyOTP, completeProfile } from '../controllers/auth';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refreshToken);
router.post('/logout', logout);
router.get('/google/url', getGoogleAuthUrl);
router.get('/google/callback', googleCallback);

// OTP-based authentication routes
router.post('/send-otp', sendOTPToPhone);
router.post('/verify-otp', verifyOTP);
router.post('/complete-profile', completeProfile);

export default router;

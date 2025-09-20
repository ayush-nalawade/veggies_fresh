import express from 'express';
import { register, login, getGoogleAuthUrl, googleCallback, refreshToken, logout } from '../controllers/auth';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refreshToken);
router.post('/logout', logout);
router.get('/google/url', getGoogleAuthUrl);
router.get('/google/callback', googleCallback);

export default router;

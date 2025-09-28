import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import passport from 'passport';
import { z } from 'zod';
import { User } from '../models/User';
import { OTP } from '../models/OTP';
import { logger } from '../utils/logger';
import { sendOTP, generateOTP } from '../utils/twilio';

// Validation schemas
const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email format'),
  phone: z.string().regex(/^[0-9]{10}$/, 'Phone number must be exactly 10 digits'),
  password: z.string().min(6, 'Password must be at least 6 characters')
});

const loginSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string().min(1, 'Password is required')
});

const sendOTPSchema = z.object({
  phone: z.string().regex(/^[0-9]{10}$/, 'Phone number must be exactly 10 digits')
});

const verifyOTPSchema = z.object({
  phone: z.string().regex(/^[0-9]{10}$/, 'Phone number must be exactly 10 digits'),
  otp: z.string().regex(/^[0-9]{4}$/, 'OTP must be exactly 4 digits')
});

const completeProfileSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email format').optional(),
  city: z.string().min(1, 'City is required')
});

// Generate JWT tokens
const generateTokens = (userId: string) => {
  const accessToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET!,
    { expiresIn: '1h' } // Extended to 1 hour
  );
  
  const refreshToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET!,
    { expiresIn: '30d' } // Extended to 30 days
  );
  
  return { accessToken, refreshToken };
};

export const register = async (req: Request, res: Response) => {
  try {
    const { name, email, phone, password } = registerSchema.parse(req.body);

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'User already exists with this email'
      });
    }

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const user = await User.create({
      name,
      email,
      phone,
      passwordHash,
      addresses: []
    });

    const { accessToken, refreshToken } = generateTokens(user._id.toString());

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          avatarUrl: user.avatarUrl,
          role: user.role
        },
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    logger.error('Register error:', error);
    res.status(400).json({
      success: false,
      error: error instanceof z.ZodError ? 'Validation error' : 'Registration failed'
    });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const { email, password } = loginSchema.parse(req.body);

    // Find user
    const user = await User.findOne({ email });
    if (!user || !user.passwordHash) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    const { accessToken, refreshToken } = generateTokens(user._id.toString());

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          avatarUrl: user.avatarUrl,
          role: user.role
        },
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(400).json({
      success: false,
      error: error instanceof z.ZodError ? 'Validation error' : 'Login failed'
    });
  }
};

export const getGoogleAuthUrl = (req: Request, res: Response) => {
  try {
    const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
      `client_id=${process.env.GOOGLE_CLIENT_ID}&` +
      `redirect_uri=${process.env.FRONTEND_URL}/auth/google/callback&` +
      `scope=profile email&` +
      `response_type=code&` +
      `access_type=offline`;
    
    res.json({
      success: true,
      data: { authUrl }
    });
  } catch (error) {
    logger.error('Google auth URL error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate Google auth URL'
    });
  }
};

export const refreshToken = async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: 'Refresh token is required'
      });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET!) as any;
    const userId = decoded.userId;

    // Check if user still exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'User not found'
      });
    }

    // Generate new tokens
    const { accessToken, refreshToken: newRefreshToken } = generateTokens(userId);

    res.json({
      success: true,
      data: {
        accessToken,
        refreshToken: newRefreshToken
      }
    });
  } catch (error) {
    logger.error('Refresh token error:', error);
    res.status(401).json({
      success: false,
      error: 'Invalid refresh token'
    });
  }
};

export const logout = async (req: Request, res: Response) => {
  try {
    // In a real app, you might want to blacklist the token
    // For now, we'll just return success
    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: 'Logout failed'
    });
  }
};

export const googleCallback = async (req: Request, res: Response) => {
  try {
    const { code } = req.query;
    
    if (!code) {
      return res.status(400).json({
        success: false,
        error: 'Authorization code not provided'
      });
    }

    // Exchange code for tokens
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: process.env.GOOGLE_CLIENT_ID!,
        client_secret: process.env.GOOGLE_CLIENT_SECRET!,
        code: code as string,
        grant_type: 'authorization_code',
        redirect_uri: `${process.env.FRONTEND_URL}/auth/google/callback`
      })
    });

    const tokens = await tokenResponse.json() as any;
    
    if (!tokens.access_token) {
      return res.status(400).json({
        success: false,
        error: 'Failed to get access token'
      });
    }

    // Get user info from Google
    const userResponse = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: { Authorization: `Bearer ${tokens.access_token}` }
    });

    const googleUser = await userResponse.json() as any;

    // Find or create user
    let user = await User.findOne({ googleId: googleUser.id });
    
    if (!user) {
      // Check if user exists with same email
      user = await User.findOne({ email: googleUser.email });
      
      if (user) {
        // Link Google account to existing user
        user.googleId = googleUser.id;
        user.avatarUrl = googleUser.picture;
        await user.save();
      } else {
        // Create new user
        user = await User.create({
          name: googleUser.name,
          email: googleUser.email,
          googleId: googleUser.id,
          avatarUrl: googleUser.picture,
          addresses: []
        });
      }
    }

    const { accessToken, refreshToken } = generateTokens(user._id.toString());

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          avatarUrl: user.avatarUrl,
          role: user.role
        },
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    logger.error('Google callback error:', error);
    res.status(500).json({
      success: false,
      error: 'Google authentication failed'
    });
  }
};

// Send OTP to phone number
export const sendOTPToPhone = async (req: Request, res: Response) => {
  try {
    const { phone } = sendOTPSchema.parse(req.body);
    
    // Generate 4-digit OTP
    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes from now
    
    // Invalidate any existing OTPs for this phone
    await OTP.updateMany(
      { phone, isUsed: false },
      { isUsed: true }
    );
    
    // Create new OTP record
    await OTP.create({
      phone,
      otp,
      expiresAt
    });
    
    // Send OTP via Twilio
    const sent = await sendOTP(phone, otp);
    
    if (!sent) {
      return res.status(500).json({
        success: false,
        error: 'Failed to send OTP. Please try again.'
      });
    }
    
    res.json({
      success: true,
      message: 'OTP sent successfully'
    });
  } catch (error) {
    logger.error('Send OTP error:', error);
    res.status(400).json({
      success: false,
      error: error instanceof z.ZodError ? 'Invalid phone number format' : 'Failed to send OTP'
    });
  }
};

// Verify OTP and check if user exists
export const verifyOTP = async (req: Request, res: Response) => {
  try {
    const { phone, otp } = verifyOTPSchema.parse(req.body);
    
    // Find valid OTP
    const otpRecord = await OTP.findOne({
      phone,
      otp,
      isUsed: false,
      expiresAt: { $gt: new Date() }
    });
    
    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        error: 'Invalid or expired OTP'
      });
    }
    
    // Mark OTP as used
    otpRecord.isUsed = true;
    await otpRecord.save();
    
    // Check if user exists
    const existingUser = await User.findOne({ phone });
    
    if (existingUser) {
      // User exists, update phone verification status
      existingUser.isPhoneVerified = true;
      await existingUser.save();
      
      const { accessToken, refreshToken } = generateTokens(existingUser._id.toString());
      
      return res.json({
        success: true,
        data: {
          user: {
            id: existingUser._id,
            name: existingUser.name,
            email: existingUser.email,
            phone: existingUser.phone,
            avatarUrl: existingUser.avatarUrl,
            role: existingUser.role,
            isPhoneVerified: existingUser.isPhoneVerified
          },
          accessToken,
          refreshToken,
          isNewUser: false
        }
      });
    } else {
      // New user, return temporary token for profile completion
      const tempToken = jwt.sign(
        { phone, temp: true },
        process.env.JWT_SECRET!,
        { expiresIn: '10m' }
      );
      
      return res.json({
        success: true,
        data: {
          tempToken,
          isNewUser: true
        }
      });
    }
  } catch (error) {
    logger.error('Verify OTP error:', error);
    res.status(400).json({
      success: false,
      error: error instanceof z.ZodError ? 'Invalid OTP format' : 'OTP verification failed'
    });
  }
};

// Complete user profile for new users
export const completeProfile = async (req: Request, res: Response) => {
  try {
    const { name, email, city } = completeProfileSchema.parse(req.body);
    
    // Verify temp token
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Authorization token required'
      });
    }
    
    const tempToken = authHeader.substring(7);
    const decoded = jwt.verify(tempToken, process.env.JWT_SECRET!) as any;
    
    if (!decoded.temp || !decoded.phone) {
      return res.status(401).json({
        success: false,
        error: 'Invalid temporary token'
      });
    }
    
    // Create new user
    const user = await User.create({
      name,
      email,
      phone: decoded.phone,
      isPhoneVerified: true,
      addresses: []
    });
    
    const { accessToken, refreshToken } = generateTokens(user._id.toString());
    
    res.status(201).json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          avatarUrl: user.avatarUrl,
          role: user.role,
          isPhoneVerified: user.isPhoneVerified
        },
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    logger.error('Complete profile error:', error);
    res.status(400).json({
      success: false,
      error: error instanceof z.ZodError ? 'Validation error' : 'Profile completion failed'
    });
  }
};

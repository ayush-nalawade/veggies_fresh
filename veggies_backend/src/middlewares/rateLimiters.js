const rateLimit = require('express-rate-limit');
const { logger } = require('../utils/logger');

/**
 * Rate limiting configurations for different endpoint types
 */

/**
 * General rate limiter for authentication endpoints
 * Prevents brute force attacks on login/signup
 */
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10, // Limit each IP to 10 requests per windowMs
    message: {
        success: false,
        error: 'Too many authentication attempts from this IP, please try again after 15 minutes.'
    },
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    handler: (req, res) => {
        logger.warn(`Rate limit exceeded for auth endpoint: ${req.ip} - ${req.originalUrl}`);
        res.status(429).json({
            success: false,
            error: 'Too many authentication attempts from this IP, please try again after 15 minutes.'
        });
    }
});

/**
 * Strict rate limiter for OTP/verification endpoints
 * Prevents OTP spam and abuse
 */
const otpLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5, // Limit each IP to 5 OTP requests per hour
    message: {
        success: false,
        error: 'Too many OTP requests from this IP, please try again after an hour.'
    },
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: false, // Count all requests
    handler: (req, res) => {
        logger.warn(`OTP rate limit exceeded: ${req.ip} - ${req.originalUrl}`);
        res.status(429).json({
            success: false,
            error: 'Too many OTP requests from this IP, please try again after an hour.'
        });
    }
});

/**
 * Rate limiter for checkout endpoints
 * Prevents checkout spam and potential fraud
 */
const checkoutLimiter = rateLimit({
    windowMs: 10 * 60 * 1000, // 10 minutes
    max: 20, // Limit each IP to 20 checkout requests per 10 minutes
    message: {
        success: false,
        error: 'Too many checkout attempts from this IP, please try again later.'
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        logger.warn(`Checkout rate limit exceeded: ${req.ip} - ${req.originalUrl}`);
        res.status(429).json({
            success: false,
            error: 'Too many checkout attempts from this IP, please try again later.'
        });
    }
});

/**
 * Rate limiter for cart operations
 * Prevents cart manipulation abuse
 */
const cartLimiter = rateLimit({
    windowMs: 5 * 60 * 1000, // 5 minutes
    max: 50, // Limit each IP to 50 cart operations per 5 minutes
    message: {
        success: false,
        error: 'Too many cart operations from this IP, please slow down.'
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        logger.warn(`Cart rate limit exceeded: ${req.ip} - ${req.originalUrl}`);
        res.status(429).json({
            success: false,
            error: 'Too many cart operations from this IP, please slow down.'
        });
    }
});

/**
 * Rate limiter for order operations
 * Prevents order spam
 */
const orderLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 30, // Limit each IP to 30 order operations per 15 minutes
    message: {
        success: false,
        error: 'Too many order requests from this IP, please try again later.'
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        logger.warn(`Order rate limit exceeded: ${req.ip} - ${req.originalUrl}`);
        res.status(429).json({
            success: false,
            error: 'Too many order requests from this IP, please try again later.'
        });
    }
});

/**
 * General API rate limiter
 * Prevents general API abuse and DDoS
 */
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: {
        success: false,
        error: 'Too many requests from this IP, please try again later.'
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        logger.warn(`API rate limit exceeded: ${req.ip} - ${req.originalUrl}`);
        res.status(429).json({
            success: false,
            error: 'Too many requests from this IP, please try again later.'
        });
    }
});

/**
 * Strict rate limiter for password reset
 * Prevents password reset abuse
 */
const passwordResetLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 3, // Limit each IP to 3 password reset requests per hour
    message: {
        success: false,
        error: 'Too many password reset attempts from this IP, please try again after an hour.'
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        logger.warn(`Password reset rate limit exceeded: ${req.ip} - ${req.originalUrl}`);
        res.status(429).json({
            success: false,
            error: 'Too many password reset attempts from this IP, please try again after an hour.'
        });
    }
});

/**
 * Create a custom rate limiter with specified options
 * @param {Object} options - Rate limiter options
 * @returns {Function} Rate limiter middleware
 */
function createRateLimiter(options = {}) {
    const defaultOptions = {
        windowMs: 15 * 60 * 1000,
        max: 100,
        standardHeaders: true,
        legacyHeaders: false,
        handler: (req, res) => {
            logger.warn(`Custom rate limit exceeded: ${req.ip} - ${req.originalUrl}`);
            res.status(429).json({
                success: false,
                error: options.message || 'Too many requests, please try again later.'
            });
        }
    };

    return rateLimit({ ...defaultOptions, ...options });
}

module.exports = {
    authLimiter,
    otpLimiter,
    checkoutLimiter,
    cartLimiter,
    orderLimiter,
    apiLimiter,
    passwordResetLimiter,
    createRateLimiter
};

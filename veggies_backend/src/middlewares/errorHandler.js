const { logger } = require('../utils/logger');

const errorHandler = (error, req, res, next) => {
    logger.error('Error:', error);

    // Mongoose validation error
    if (error.name === 'ValidationError') {
        const errors = Object.values(error.errors).map((err) => err.message);
        return res.status(400).json({
            success: false,
            error: 'Validation Error',
            details: errors
        });
    }

    // Mongoose duplicate key error
    if (error.code === 11000) {
        const field = Object.keys(error.keyValue)[0];
        return res.status(400).json({
            success: false,
            error: `${field} already exists`
        });
    }

    // JWT errors
    if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({
            success: false,
            error: 'Invalid token'
        });
    }

    if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
            success: false,
            error: 'Token expired'
        });
    }

    // Default error
    res.status(error.status || 500).json({
        success: false,
        error: error.message || 'Internal server error'
    });
};

module.exports = { errorHandler };

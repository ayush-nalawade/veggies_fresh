const { v4: uuidv4 } = require('crypto');
const { logger } = require('../utils/logger');

/**
 * Request ID middleware
 * Generates a unique ID for each request to enable request tracing through logs
 */

/**
 * Generate a unique request ID
 * @returns {string} Unique request ID
 */
function generateRequestId() {
    // Use timestamp + random string for uniqueness
    const timestamp = Date.now().toString(36);
    const randomStr = Math.random().toString(36).substring(2, 9);
    return `req_${timestamp}_${randomStr}`;
}

/**
 * Request ID middleware
 * Adds a unique request ID to each request and response
 */
function requestIdMiddleware(req, res, next) {
    // Check if request ID is provided in headers (for request chaining)
    const requestId = req.headers['x-request-id'] || generateRequestId();

    // Attach request ID to request object
    req.requestId = requestId;

    // Add request ID to response headers
    res.setHeader('X-Request-ID', requestId);

    // Store original end function
    const originalEnd = res.end;

    // Override end function to log request completion
    res.end = function (...args) {
        // Log request completion
        const duration = Date.now() - req.startTime;

        logger.info({
            requestId: requestId,
            method: req.method,
            url: req.originalUrl || req.url,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            userAgent: req.headers['user-agent'],
            ip: req.ip || req.connection.remoteAddress
        }, `Request completed: ${req.method} ${req.originalUrl || req.url} - ${res.statusCode} (${duration}ms)`);

        // Call original end function
        originalEnd.apply(res, args);
    };

    // Store request start time
    req.startTime = Date.now();

    // Log incoming request
    logger.info({
        requestId: requestId,
        method: req.method,
        url: req.originalUrl || req.url,
        userAgent: req.headers['user-agent'],
        ip: req.ip || req.connection.remoteAddress
    }, `Incoming request: ${req.method} ${req.originalUrl || req.url}`);

    next();
}

/**
 * Get request ID from request object
 * @param {Object} req - Express request object
 * @returns {string} Request ID
 */
function getRequestId(req) {
    return req.requestId || 'unknown';
}

/**
 * Create a logger with request context
 * @param {Object} req - Express request object
 * @returns {Object} Logger with request context
 */
function createRequestLogger(req) {
    const requestId = getRequestId(req);

    return {
        info: (message, meta = {}) => {
            logger.info({ ...meta, requestId }, message);
        },
        warn: (message, meta = {}) => {
            logger.warn({ ...meta, requestId }, message);
        },
        error: (message, meta = {}) => {
            logger.error({ ...meta, requestId }, message);
        },
        debug: (message, meta = {}) => {
            logger.debug({ ...meta, requestId }, message);
        }
    };
}

module.exports = {
    requestIdMiddleware,
    generateRequestId,
    getRequestId,
    createRequestLogger
};

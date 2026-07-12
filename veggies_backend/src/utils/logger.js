const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const path = require('path');

/**
 * Logger configuration with log rotation
 * Prevents logs from growing indefinitely by rotating daily and archiving old logs
 */

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../../logs');

// Custom format for better readability
const customFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.metadata({ fillExcept: ['message', 'level', 'timestamp', 'service'] }),
    winston.format.json()
);

// Console format for development
const consoleFormat = winston.format.combine(
    winston.format.colorize(),
    winston.format.timestamp({ format: 'HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
        let metaStr = '';
        if (Object.keys(meta).length > 0) {
            metaStr = ` ${JSON.stringify(meta)}`;
        }
        return `${timestamp} [${level}]: ${message}${metaStr}`;
    })
);

// Daily rotate file transport for error logs
const errorRotateTransport = new DailyRotateFile({
    filename: path.join(logsDir, 'error-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    level: 'error',
    maxSize: '20m', // Rotate when file reaches 20MB
    maxFiles: '30d', // Keep logs for 30 days
    zippedArchive: true, // Compress archived logs
    format: customFormat
});

// Daily rotate file transport for combined logs
const combinedRotateTransport = new DailyRotateFile({
    filename: path.join(logsDir, 'combined-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    maxSize: '20m', // Rotate when file reaches 20MB
    maxFiles: '14d', // Keep logs for 14 days
    zippedArchive: true, // Compress archived logs
    format: customFormat
});

// Daily rotate file transport for info logs
const infoRotateTransport = new DailyRotateFile({
    filename: path.join(logsDir, 'info-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    level: 'info',
    maxSize: '20m',
    maxFiles: '14d',
    zippedArchive: true,
    format: customFormat
});

// Daily rotate file transport for debug logs (development only)
const debugRotateTransport = new DailyRotateFile({
    filename: path.join(logsDir, 'debug-%DATE%.log'),
    datePattern: 'YYYY-MM-DD',
    level: 'debug',
    maxSize: '10m',
    maxFiles: '7d', // Keep debug logs for 7 days only
    zippedArchive: true,
    format: customFormat
});

// Create logger instance
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug'),
    format: customFormat,
    defaultMeta: { service: 'veggiefresh-api' },
    transports: [
        errorRotateTransport,
        combinedRotateTransport,
        infoRotateTransport
    ],
    // Handle exceptions and rejections
    exceptionHandlers: [
        new DailyRotateFile({
            filename: path.join(logsDir, 'exceptions-%DATE%.log'),
            datePattern: 'YYYY-MM-DD',
            maxSize: '20m',
            maxFiles: '30d',
            zippedArchive: true
        })
    ],
    rejectionHandlers: [
        new DailyRotateFile({
            filename: path.join(logsDir, 'rejections-%DATE%.log'),
            datePattern: 'YYYY-MM-DD',
            maxSize: '20m',
            maxFiles: '30d',
            zippedArchive: true
        })
    ]
});

// Add debug transport in development
if (process.env.NODE_ENV !== 'production') {
    logger.add(debugRotateTransport);
}

// Add console transport for development
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: consoleFormat
    }));
}

// Log rotation events
errorRotateTransport.on('rotate', (oldFilename, newFilename) => {
    logger.info(`Error log rotated: ${oldFilename} -> ${newFilename}`);
});

combinedRotateTransport.on('rotate', (oldFilename, newFilename) => {
    logger.info(`Combined log rotated: ${oldFilename} -> ${newFilename}`);
});

// Log when old files are deleted
errorRotateTransport.on('logRemoved', (removedFilename) => {
    logger.info(`Old error log removed: ${removedFilename}`);
});

combinedRotateTransport.on('logRemoved', (removedFilename) => {
    logger.info(`Old combined log removed: ${removedFilename}`);
});

// Export logger and log directory path
module.exports = {
    logger,
    logsDir
};


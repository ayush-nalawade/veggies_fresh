const { logger } = require('./logger');

/**
 * Environment variable validator
 * Validates that all required environment variables are present at startup
 */

const REQUIRED_ENV_VARS = {
    // Database
    MONGO_URI: {
        required: true,
        description: 'MongoDB connection URI',
        example: 'mongodb://localhost:27017/veggiefresh'
    },

    // JWT
    JWT_SECRET: {
        required: true,
        description: 'Secret key for JWT token generation',
        example: 'your-super-secret-jwt-key'
    },
    JWT_EXPIRES_IN: {
        required: false,
        default: '7d',
        description: 'JWT token expiration time'
    },

    // Server
    PORT: {
        required: false,
        default: '3000',
        description: 'Server port number'
    },
    NODE_ENV: {
        required: false,
        default: 'development',
        description: 'Node environment (development/production/test)'
    },

    // Twilio (required for OTP functionality)
    TWILIO_ACCOUNT_SID: {
        required: true,
        description: 'Twilio account SID',
        example: 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    },
    TWILIO_AUTH_TOKEN: {
        required: true,
        description: 'Twilio authentication token',
        example: 'your-twilio-auth-token'
    },
    TWILIO_PHONE_NUMBER: {
        required: true,
        description: 'Twilio phone number',
        example: '+1234567890'
    },

    // Razorpay (required for payments)
    RAZORPAY_KEY_ID: {
        required: true,
        description: 'Razorpay key ID',
        example: 'rzp_test_xxxxxxxxxxxxx'
    },
    RAZORPAY_KEY_SECRET: {
        required: true,
        description: 'Razorpay key secret',
        example: 'your-razorpay-key-secret'
    },

    // CORS
    FRONTEND_URL: {
        required: false,
        default: 'http://localhost:8080',
        description: 'Frontend application URL'
    },

    // Google OAuth (optional)
    GOOGLE_CLIENT_ID: {
        required: false,
        description: 'Google OAuth client ID'
    },
    GOOGLE_CLIENT_SECRET: {
        required: false,
        description: 'Google OAuth client secret'
    }
};

/**
 * Validates all required environment variables
 * @throws {Error} If any required environment variable is missing
 */
function validateEnvVars() {
    const missingVars = [];
    const warnings = [];

    logger.info('🔍 Validating environment variables...');

    // Check each required variable
    for (const [varName, config] of Object.entries(REQUIRED_ENV_VARS)) {
        const value = process.env[varName];

        if (!value || value.trim() === '') {
            if (config.required) {
                missingVars.push({
                    name: varName,
                    description: config.description,
                    example: config.example
                });
            } else if (config.default) {
                // Set default value
                process.env[varName] = config.default;
                warnings.push(`${varName} not set, using default: ${config.default}`);
            } else {
                warnings.push(`${varName} not set (optional)`);
            }
        } else {
            // Validate format for specific variables
            if (varName === 'MONGO_URI' && !value.startsWith('mongodb://') && !value.startsWith('mongodb+srv://')) {
                missingVars.push({
                    name: varName,
                    description: 'Invalid MongoDB URI format',
                    example: config.example
                });
            }

            if (varName === 'PORT' && isNaN(parseInt(value))) {
                missingVars.push({
                    name: varName,
                    description: 'PORT must be a valid number',
                    example: '3000'
                });
            }
        }
    }

    // Log warnings
    if (warnings.length > 0) {
        warnings.forEach(warning => logger.warn(`⚠️  ${warning}`));
    }

    // If there are missing required variables, throw error
    if (missingVars.length > 0) {
        logger.error('❌ Missing required environment variables:');
        missingVars.forEach(({ name, description, example }) => {
            logger.error(`  - ${name}: ${description}`);
            if (example) {
                logger.error(`    Example: ${example}`);
            }
        });

        logger.error('\n💡 Please create a .env file based on env.example and fill in the required values.');
        throw new Error('Missing required environment variables. Application cannot start.');
    }

    logger.info('✅ Environment variables validated successfully');

    // Log current environment
    logger.info(`📦 Environment: ${process.env.NODE_ENV}`);
    logger.info(`🚀 Port: ${process.env.PORT}`);
}

/**
 * Gets a required environment variable
 * @param {string} varName - Name of the environment variable
 * @returns {string} Value of the environment variable
 * @throws {Error} If the variable is not set
 */
function getRequiredEnvVar(varName) {
    const value = process.env[varName];
    if (!value) {
        throw new Error(`Required environment variable ${varName} is not set`);
    }
    return value;
}

/**
 * Gets an optional environment variable with a default value
 * @param {string} varName - Name of the environment variable
 * @param {string} defaultValue - Default value if not set
 * @returns {string} Value of the environment variable or default
 */
function getEnvVar(varName, defaultValue = '') {
    return process.env[varName] || defaultValue;
}

module.exports = {
    validateEnvVars,
    getRequiredEnvVar,
    getEnvVar,
    REQUIRED_ENV_VARS
};

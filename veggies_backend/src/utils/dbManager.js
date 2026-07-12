const mongoose = require('mongoose');
const { logger } = require('./logger');

/**
 * Database connection manager with retry logic and health monitoring
 */

class DatabaseManager {
    constructor(uri, options = {}) {
        this.uri = uri;
        this.options = {
            maxRetries: options.maxRetries || 5,
            retryDelay: options.retryDelay || 5000, // 5 seconds
            connectionTimeout: options.connectionTimeout || 30000, // 30 seconds
            ...options
        };
        this.retryCount = 0;
        this.isConnecting = false;
        this.reconnectTimer = null;
    }

    /**
     * Connect to MongoDB with retry logic
     * @returns {Promise<void>}
     */
    async connect() {
        if (this.isConnecting) {
            logger.warn('Connection attempt already in progress');
            return;
        }

        this.isConnecting = true;

        const mongooseOptions = {
            serverSelectionTimeoutMS: this.options.connectionTimeout,
            socketTimeoutMS: 45000,
            family: 4, // Use IPv4, skip trying IPv6
        };

        try {
            logger.info(`🔌 Attempting to connect to MongoDB... (Attempt ${this.retryCount + 1}/${this.options.maxRetries})`);

            await mongoose.connect(this.uri, mongooseOptions);

            logger.info('✅ Successfully connected to MongoDB');
            this.retryCount = 0;
            this.isConnecting = false;

            // Set up event listeners
            this.setupEventListeners();

        } catch (error) {
            this.isConnecting = false;
            logger.error(`❌ MongoDB connection error: ${error.message}`);

            if (this.retryCount < this.options.maxRetries) {
                this.retryCount++;
                const delay = this.options.retryDelay * this.retryCount; // Exponential backoff

                logger.warn(`⏳ Retrying connection in ${delay / 1000} seconds... (${this.retryCount}/${this.options.maxRetries})`);

                this.reconnectTimer = setTimeout(() => {
                    this.connect();
                }, delay);
            } else {
                logger.error(`💥 Failed to connect to MongoDB after ${this.options.maxRetries} attempts`);
                throw new Error('Database connection failed after maximum retry attempts');
            }
        }
    }

    /**
     * Set up MongoDB event listeners for connection monitoring
     */
    setupEventListeners() {
        // Connection events
        mongoose.connection.on('connected', () => {
            logger.info('📡 Mongoose connected to MongoDB');
        });

        mongoose.connection.on('disconnected', () => {
            logger.warn('⚠️  Mongoose disconnected from MongoDB');

            // Attempt to reconnect
            if (!this.isConnecting && this.retryCount < this.options.maxRetries) {
                logger.info('🔄 Attempting to reconnect...');
                this.connect();
            }
        });

        mongoose.connection.on('error', (error) => {
            logger.error(`❌ Mongoose connection error: ${error.message}`);
        });

        mongoose.connection.on('reconnected', () => {
            logger.info('✅ Mongoose reconnected to MongoDB');
            this.retryCount = 0;
        });

        // Handle process termination
        process.on('SIGINT', async () => {
            await this.disconnect();
            process.exit(0);
        });

        process.on('SIGTERM', async () => {
            await this.disconnect();
            process.exit(0);
        });
    }

    /**
     * Disconnect from MongoDB gracefully
     * @returns {Promise<void>}
     */
    async disconnect() {
        try {
            // Clear any pending reconnection timers
            if (this.reconnectTimer) {
                clearTimeout(this.reconnectTimer);
                this.reconnectTimer = null;
            }

            if (mongoose.connection.readyState !== 0) {
                logger.info('🔌 Closing MongoDB connection...');
                await mongoose.connection.close();
                logger.info('✅ MongoDB connection closed successfully');
            }
        } catch (error) {
            logger.error(`❌ Error closing MongoDB connection: ${error.message}`);
            throw error;
        }
    }

    /**
     * Check if database is connected
     * @returns {boolean}
     */
    isConnected() {
        return mongoose.connection.readyState === 1;
    }

    /**
     * Get connection status
     * @returns {string}
     */
    getConnectionStatus() {
        const states = {
            0: 'disconnected',
            1: 'connected',
            2: 'connecting',
            3: 'disconnecting'
        };
        return states[mongoose.connection.readyState] || 'unknown';
    }

    /**
     * Get database health information
     * @returns {Object}
     */
    getHealthInfo() {
        return {
            status: this.getConnectionStatus(),
            isConnected: this.isConnected(),
            host: mongoose.connection.host,
            name: mongoose.connection.name,
            retryCount: this.retryCount,
            maxRetries: this.options.maxRetries
        };
    }
}

/**
 * Create and export a singleton instance
 */
let dbManager = null;

/**
 * Initialize database manager
 * @param {string} uri - MongoDB connection URI
 * @param {Object} options - Connection options
 * @returns {DatabaseManager}
 */
function initializeDatabaseManager(uri, options = {}) {
    if (!dbManager) {
        dbManager = new DatabaseManager(uri, options);
    }
    return dbManager;
}

/**
 * Get the database manager instance
 * @returns {DatabaseManager}
 */
function getDatabaseManager() {
    if (!dbManager) {
        throw new Error('Database manager not initialized. Call initializeDatabaseManager first.');
    }
    return dbManager;
}

module.exports = {
    DatabaseManager,
    initializeDatabaseManager,
    getDatabaseManager
};

const { logger } = require('./logger');

/**
 * Graceful shutdown handler
 * Ensures proper cleanup of resources when the application is terminated
 */

class GracefulShutdown {
    constructor() {
        this.shutdownHandlers = [];
        this.isShuttingDown = false;
        this.shutdownTimeout = 30000; // 30 seconds
    }

    /**
     * Register a shutdown handler
     * @param {string} name - Name of the handler
     * @param {Function} handler - Async function to execute on shutdown
     */
    registerHandler(name, handler) {
        this.shutdownHandlers.push({ name, handler });
        logger.info(`📝 Registered shutdown handler: ${name}`);
    }

    /**
     * Execute all shutdown handlers
     * @param {string} signal - Signal that triggered shutdown
     */
    async executeShutdown(signal) {
        if (this.isShuttingDown) {
            logger.warn('⚠️  Shutdown already in progress...');
            return;
        }

        this.isShuttingDown = true;
        logger.info(`\n🛑 Received ${signal}. Starting graceful shutdown...`);

        // Set a timeout to force exit if shutdown takes too long
        const forceExitTimer = setTimeout(() => {
            logger.error(`❌ Graceful shutdown timeout exceeded (${this.shutdownTimeout}ms). Forcing exit...`);
            process.exit(1);
        }, this.shutdownTimeout);

        try {
            // Execute all shutdown handlers
            for (const { name, handler } of this.shutdownHandlers) {
                try {
                    logger.info(`🔄 Executing shutdown handler: ${name}`);
                    await handler();
                    logger.info(`✅ Completed shutdown handler: ${name}`);
                } catch (error) {
                    logger.error(`❌ Error in shutdown handler ${name}: ${error.message}`);
                }
            }

            logger.info('✅ Graceful shutdown completed successfully');
            clearTimeout(forceExitTimer);
            process.exit(0);
        } catch (error) {
            logger.error(`❌ Error during graceful shutdown: ${error.message}`);
            clearTimeout(forceExitTimer);
            process.exit(1);
        }
    }

    /**
     * Set up signal handlers for graceful shutdown
     * @param {Object} server - HTTP server instance
     * @param {Object} dbManager - Database manager instance
     */
    setupSignalHandlers(server, dbManager) {
        // Register database shutdown handler
        if (dbManager) {
            this.registerHandler('Database Connection', async () => {
                await dbManager.disconnect();
            });
        }

        // Register HTTP server shutdown handler
        if (server) {
            this.registerHandler('HTTP Server', async () => {
                return new Promise((resolve, reject) => {
                    logger.info('🔌 Closing HTTP server...');

                    server.close((error) => {
                        if (error) {
                            logger.error(`❌ Error closing HTTP server: ${error.message}`);
                            reject(error);
                        } else {
                            logger.info('✅ HTTP server closed successfully');
                            resolve();
                        }
                    });

                    // Close all active connections
                    const connections = server._connections || 0;
                    if (connections > 0) {
                        logger.info(`⏳ Waiting for ${connections} active connections to close...`);
                    }
                });
            });
        }

        // Handle different termination signals
        const signals = ['SIGTERM', 'SIGINT', 'SIGUSR2'];

        signals.forEach(signal => {
            process.on(signal, () => {
                this.executeShutdown(signal);
            });
        });

        // Handle uncaught exceptions
        process.on('uncaughtException', (error) => {
            logger.error(`❌ Uncaught Exception: ${error.message}`);
            logger.error(error.stack);
            this.executeShutdown('uncaughtException');
        });

        // Handle unhandled promise rejections
        process.on('unhandledRejection', (reason, promise) => {
            logger.error('❌ Unhandled Rejection at:', promise);
            logger.error('Reason:', reason);
            this.executeShutdown('unhandledRejection');
        });

        logger.info('✅ Graceful shutdown handlers registered');
    }

    /**
     * Set shutdown timeout
     * @param {number} timeout - Timeout in milliseconds
     */
    setShutdownTimeout(timeout) {
        this.shutdownTimeout = timeout;
    }
}

// Create and export singleton instance
const gracefulShutdown = new GracefulShutdown();

module.exports = gracefulShutdown;

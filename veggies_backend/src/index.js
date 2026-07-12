const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');

// Load environment variables first
dotenv.config();

// Import utilities and middlewares
const { validateEnvVars } = require('./utils/envValidator');
const { initializeDatabaseManager } = require('./utils/dbManager');
const { requestIdMiddleware } = require('./middlewares/requestId');
const gracefulShutdown = require('./utils/gracefulShutdown');
const { logger } = require('./utils/logger');
const { errorHandler } = require('./middlewares/errorHandler');
const { setupSwagger } = require('./config/swagger');

// Import rate limiters
const {
    authLimiter,
    checkoutLimiter,
    cartLimiter,
    orderLimiter,
    apiLimiter
} = require('./middlewares/rateLimiters');

// Import routes
const authRoutes = require('./routes/auth');
const categoryRoutes = require('./routes/categories');
const productRoutes = require('./routes/products');
const cartRoutes = require('./routes/cart');
const checkoutRoutes = require('./routes/checkout');
const orderRoutes = require('./routes/orders');
const profileRoutes = require('./routes/profile');
const dealsRoutes = require('./routes/deals');

/**
 * Main application initialization
 */
async function startServer() {
    try {
        // ============================================
        // 1. VALIDATE ENVIRONMENT VARIABLES (CRITICAL)
        // ============================================
        logger.info('🚀 Starting VeggieFresh API Server...');
        validateEnvVars();

        // ============================================
        // 2. INITIALIZE EXPRESS APP
        // ============================================
        const app = express();
        const PORT = process.env.PORT || 3000;

        // ============================================
        // 3. SECURITY MIDDLEWARE
        // ============================================
        app.use(helmet());

        // Trust proxy (important for rate limiting behind reverse proxy)
        app.set('trust proxy', 1);

        // ============================================
        // 4. REQUEST ID TRACKING MIDDLEWARE
        // ============================================
        app.use(requestIdMiddleware);

        // ============================================
        // 5. CORS CONFIGURATION
        // ============================================
        const corsOptions = {
            origin: function (origin, callback) {
                // Allow requests with no origin (like mobile apps or curl requests)
                if (!origin) return callback(null, true);

                // List of allowed origins
                const allowedOrigins = [
                    'http://localhost:3000',
                    'http://localhost:3001',
                    'http://localhost:8080',
                    'http://localhost:8081',
                    'http://127.0.0.1:3000',
                    'http://127.0.0.1:3001',
                    'http://127.0.0.1:8080',
                    'http://127.0.0.1:8081',
                    'http://192.168.0.7:3000', // Android emulator
                    'http://10.0.2.2:3000', // Android emulator alternative
                    process.env.FRONTEND_URL
                ].filter(Boolean); // Remove undefined values

                if (allowedOrigins.includes(origin)) {
                    callback(null, true);
                } else {
                    // For development, allow any localhost origin and common development IPs
                    if (origin.includes('localhost') ||
                        origin.includes('127.0.0.1') ||
                        origin.includes('192.168.') ||
                        origin.includes('10.0.2.2')) {
                        callback(null, true);
                    } else {
                        callback(new Error('Not allowed by CORS'));
                    }
                }
            },
            credentials: true,
            methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
            allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'X-Request-ID'],
            exposedHeaders: ['X-Request-ID'],
            optionsSuccessStatus: 200
        };

        app.use(cors(corsOptions));

        // ============================================
        // 6. BODY PARSING MIDDLEWARE
        // ============================================
        app.use(express.json({ limit: '10mb' }));
        app.use(express.urlencoded({ extended: true }));

        // ============================================
        // 7. LOGGING MIDDLEWARE
        // ============================================
        app.use(morgan('combined', {
            stream: { write: (message) => logger.info(message.trim()) },
            skip: (req) => req.url === '/health' || req.url.startsWith('/api-docs') // Skip health check and docs logs
        }));

        // ============================================
        // 8. API DOCUMENTATION (SWAGGER)
        // ============================================
        setupSwagger(app);

        // ============================================
        // 9. GENERAL API RATE LIMITING
        // ============================================
        app.use(apiLimiter);

        // ============================================
        // 10. ROUTES WITH SPECIFIC RATE LIMITING
        // ============================================
        app.use('/auth', authLimiter, authRoutes);
        app.use('/categories', categoryRoutes);
        app.use('/products', productRoutes);
        app.use('/deals', dealsRoutes);
        app.use('/cart', cartLimiter, cartRoutes);
        app.use('/checkout', checkoutLimiter, checkoutRoutes);
        app.use('/orders', orderLimiter, orderRoutes);
        app.use('/profile', profileRoutes);

        // ============================================
        // 10. HEALTH CHECK ENDPOINT
        // ============================================
        app.get('/health', (req, res) => {
            const dbManager = require('./utils/dbManager').getDatabaseManager();
            const dbHealth = dbManager.getHealthInfo();

            res.json({
                success: true,
                message: 'VeggieFresh API is running!',
                timestamp: new Date().toISOString(),
                uptime: process.uptime(),
                environment: process.env.NODE_ENV,
                database: {
                    status: dbHealth.status,
                    connected: dbHealth.isConnected
                }
            });
        });

        // ============================================
        // 11. ERROR HANDLING MIDDLEWARE
        // ============================================
        app.use(errorHandler);

        // ============================================
        // 12. 404 HANDLER
        // ============================================
        app.use('*', (req, res) => {
            res.status(404).json({
                success: false,
                error: 'Route not found',
                path: req.originalUrl
            });
        });

        // ============================================
        // 13. DATABASE CONNECTION WITH RETRY LOGIC
        // ============================================
        const dbManager = initializeDatabaseManager(
            process.env.MONGO_URI || 'mongodb://localhost:27017/veggiefresh',
            {
                maxRetries: 5,
                retryDelay: 5000,
                connectionTimeout: 30000
            }
        );

        await dbManager.connect();

        // ============================================
        // 14. START HTTP SERVER
        // ============================================
        const server = app.listen(PORT, () => {
            logger.info(`✅ Server running on port ${PORT}`);
            logger.info(`📡 Environment: ${process.env.NODE_ENV}`);
            logger.info(`🌐 API URL: http://localhost:${PORT}`);
            logger.info(`💚 VeggieFresh API is ready to accept requests!`);
        });

        // ============================================
        // 15. GRACEFUL SHUTDOWN HANDLERS
        // ============================================
        gracefulShutdown.setupSignalHandlers(server, dbManager);

        return { app, server, dbManager };

    } catch (error) {
        logger.error(`❌ Failed to start server: ${error.message}`);
        logger.error(error.stack);
        process.exit(1);
    }
}

// Start the server
if (require.main === module) {
    startServer();
}

module.exports = { startServer };

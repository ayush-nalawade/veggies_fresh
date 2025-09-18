"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const mongoose_1 = __importDefault(require("mongoose"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const morgan_1 = __importDefault(require("morgan"));
const dotenv_1 = __importDefault(require("dotenv"));
const auth_1 = __importDefault(require("./routes/auth"));
const categories_1 = __importDefault(require("./routes/categories"));
const products_1 = __importDefault(require("./routes/products"));
const cart_1 = __importDefault(require("./routes/cart"));
const checkout_1 = __importDefault(require("./routes/checkout"));
const orders_1 = __importDefault(require("./routes/orders"));
const errorHandler_1 = require("./middlewares/errorHandler");
const logger_1 = require("./utils/logger");
// Load environment variables
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Security middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    credentials: true
}));
// Rate limiting
const limiter = (0, express_rate_limit_1.default)({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/auth', limiter);
// Body parsing middleware
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true }));
// Logging
app.use((0, morgan_1.default)('combined', { stream: { write: (message) => logger_1.logger.info(message.trim()) } }));
// Routes
app.use('/auth', auth_1.default);
app.use('/categories', categories_1.default);
app.use('/products', products_1.default);
app.use('/cart', cart_1.default);
app.use('/checkout', checkout_1.default);
app.use('/orders', orders_1.default);
// Health check
app.get('/health', (req, res) => {
    res.json({ success: true, message: 'VeggieFresh API is running!' });
});
// Error handling middleware
app.use(errorHandler_1.errorHandler);
// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ success: false, error: 'Route not found' });
});
// Connect to MongoDB
mongoose_1.default.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/veggiefresh')
    .then(() => {
    logger_1.logger.info('Connected to MongoDB');
    app.listen(PORT, () => {
        logger_1.logger.info(`Server running on port ${PORT}`);
    });
})
    .catch((error) => {
    logger_1.logger.error('MongoDB connection error:', error);
    process.exit(1);
});
exports.default = app;
//# sourceMappingURL=index.js.map
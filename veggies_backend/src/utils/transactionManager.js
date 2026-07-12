const mongoose = require('mongoose');
const { logger } = require('./logger');

/**
 * Transaction Manager
 * Provides utilities for managing MongoDB transactions
 */

/**
 * Execute a function within a MongoDB transaction
 * @param {Function} callback - Async function to execute within transaction
 * @param {Object} options - Transaction options
 * @returns {Promise<any>} Result of the callback function
 */
async function withTransaction(callback, options = {}) {
    const session = await mongoose.startSession();

    const transactionOptions = {
        readPreference: 'primary',
        readConcern: { level: 'local' },
        writeConcern: { w: 'majority' },
        ...options
    };

    try {
        logger.debug('Starting MongoDB transaction');

        // Start transaction
        session.startTransaction(transactionOptions);

        // Execute callback with session
        const result = await callback(session);

        // Commit transaction
        await session.commitTransaction();
        logger.debug('Transaction committed successfully');

        return result;
    } catch (error) {
        // Abort transaction on error
        logger.error('Transaction error, aborting:', error.message);
        await session.abortTransaction();
        throw error;
    } finally {
        // End session
        session.endSession();
    }
}

/**
 * Execute multiple operations atomically
 * @param {Array} operations - Array of operation objects
 * @returns {Promise<Array>} Results of all operations
 */
async function executeAtomically(operations) {
    return withTransaction(async (session) => {
        const results = [];

        for (const operation of operations) {
            const { model, method, args } = operation;

            // Add session to operation options
            const opArgs = [...args];
            if (method === 'create') {
                // For create, session is passed as second argument
                const result = await model[method](opArgs[0], { session });
                results.push(result);
            } else {
                // For other methods, add session to options
                const lastArg = opArgs[opArgs.length - 1];
                if (typeof lastArg === 'object' && !Array.isArray(lastArg)) {
                    lastArg.session = session;
                } else {
                    opArgs.push({ session });
                }
                const result = await model[method](...opArgs);
                results.push(result);
            }
        }

        return results;
    });
}

/**
 * Retry a transaction if it fails due to transient errors
 * @param {Function} callback - Transaction callback
 * @param {number} maxRetries - Maximum number of retries
 * @returns {Promise<any>}
 */
async function retryTransaction(callback, maxRetries = 3) {
    let lastError;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await withTransaction(callback);
        } catch (error) {
            lastError = error;

            // Check if error is transient and retryable
            if (
                error.hasErrorLabel &&
                error.hasErrorLabel('TransientTransactionError') &&
                attempt < maxRetries
            ) {
                logger.warn(`Transaction failed with transient error, retrying (${attempt}/${maxRetries})`);
                // Wait before retrying (exponential backoff)
                await new Promise(resolve => setTimeout(resolve, 100 * Math.pow(2, attempt)));
                continue;
            }

            // Non-retryable error or max retries reached
            throw error;
        }
    }

    throw lastError;
}

/**
 * Create an order with transaction support
 * Ensures atomicity of order creation, cart clearing, and stock updates
 */
class OrderTransaction {
    constructor(session) {
        this.session = session;
        this.operations = [];
    }

    /**
     * Add operation to transaction
     * @param {string} name - Operation name
     * @param {Function} operation - Async operation function
     */
    addOperation(name, operation) {
        this.operations.push({ name, operation });
    }

    /**
     * Execute all operations in transaction
     * @returns {Promise<Object>} Results of all operations
     */
    async execute() {
        const results = {};

        try {
            for (const { name, operation } of this.operations) {
                logger.debug(`Executing transaction operation: ${name}`);
                results[name] = await operation(this.session);
            }
            return results;
        } catch (error) {
            logger.error(`Transaction operation failed: ${error.message}`);
            throw error;
        }
    }
}

/**
 * Create order transaction helper
 * @param {Object} orderData - Order data
 * @param {Object} userId - User ID
 * @param {Object} models - Database models
 * @returns {Promise<Object>} Created order and results
 */
async function createOrderWithTransaction(orderData, userId, models) {
    const { Order, Cart, Product } = models;

    return withTransaction(async (session) => {
        logger.info(`Creating order with transaction for user: ${userId}`);

        // 1. Get user's cart
        const cart = await Cart.findOne({ userId }).session(session);
        if (!cart || cart.items.length === 0) {
            throw new Error('Cart is empty');
        }

        // 2. Verify product availability and stock
        for (const item of cart.items) {
            const product = await Product.findById(item.productId).session(session);
            if (!product) {
                throw new Error(`Product ${item.productId} not found`);
            }

            // Check stock if product has stock tracking
            if (product.stock !== undefined && product.stock < item.quantity) {
                throw new Error(`Insufficient stock for product: ${product.name}`);
            }
        }

        // 3. Create order
        const [order] = await Order.create([orderData], { session });
        logger.info(`Order created: ${order._id}`);

        // 4. Update product stock (if applicable)
        for (const item of cart.items) {
            const product = await Product.findById(item.productId).session(session);
            if (product && product.stock !== undefined) {
                await Product.findByIdAndUpdate(
                    item.productId,
                    { $inc: { stock: -item.quantity } },
                    { session }
                );
                logger.debug(`Updated stock for product ${item.productId}: -${item.quantity}`);
            }
        }

        // 5. Clear cart
        await Cart.findOneAndUpdate(
            { userId },
            { items: [], subtotal: 0 },
            { session }
        );
        logger.info(`Cart cleared for user: ${userId}`);

        return {
            order,
            itemsProcessed: cart.items.length,
            cartCleared: true
        };
    });
}

module.exports = {
    withTransaction,
    executeAtomically,
    retryTransaction,
    OrderTransaction,
    createOrderWithTransaction
};

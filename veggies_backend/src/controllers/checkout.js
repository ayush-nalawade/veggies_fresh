const { z } = require('zod');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const { Cart } = require('../models/Cart');
const { Order } = require('../models/Order');
const { logger } = require('../utils/logger');

// Validation schemas
const addressSchema = z.object({
    line1: z.string().min(1, 'Flat no/ Building name is required'),
    line2: z.string().optional().nullable(), // Sector/ Locality
    landmark: z.string().optional().nullable(), // Landmark
    area: z.string().optional(), // Delivery area (Kandivali W, Malad W)
    city: z.string().min(1, 'City is required'),
    state: z.string().min(1, 'State is required'),
    pincode: z.string().min(6, 'Pincode must be at least 6 characters'),
    phone: z.string().optional().default('0000000000')
});

const createOrderSchema = z.object({
    address: addressSchema,
    paymentMethod: z.enum(['razorpay', 'cod']),
    timeSlot: z.object({
        date: z.string().min(1, 'Delivery date is required'),
        startTime: z.string().min(1, 'Start time is required'),
        endTime: z.string().min(1, 'End time is required')
    })
});

const verifyPaymentSchema = z.object({
    razorpayOrderId: z.string().min(1, 'Razorpay order ID is required'),
    paymentId: z.string().min(1, 'Payment ID is required'),
    signature: z.string().min(1, 'Signature is required'),
    orderId: z.string().min(1, 'Order ID is required')
});

// Delivery charges configuration
const DELIVERY_FEE = 40;
const FREE_DELIVERY_THRESHOLD = 200;

// Initialize Razorpay (only if keys are provided)
let razorpay = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET
    });
}

const saveAddress = async (req, res) => {
    try {
        const address = addressSchema.parse(req.body);

        // Update user's address (you might want to add this to User model)
        // For now, we'll just validate and return success
        res.json({
            success: true,
            data: { address }
        });
    } catch (error) {
        logger.error('Save address error:', error);
        res.status(400).json({
            success: false,
            error: error instanceof z.ZodError ? 'Validation error' : 'Failed to save address'
        });
    }
};

const createOrder = async (req, res) => {
    try {
        const { address, paymentMethod, timeSlot } = createOrderSchema.parse(req.body);
        const userId = req.user._id;

        // Get user's cart (outside transaction for validation)
        const cart = await Cart.findOne({ userId });
        if (!cart || cart.items.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Cart is empty'
            });
        }

        // Calculate delivery fee
        const deliveryFee = cart.subtotal < FREE_DELIVERY_THRESHOLD ? DELIVERY_FEE : 0;
        const total = cart.subtotal + deliveryFee;

        let order, razorpayOrder;

        // Try to use transactions (requires MongoDB replica set)
        // Falls back to non-transactional mode if replica set not configured
        try {
            const { withTransaction } = require('../utils/transactionManager');

            const result = await withTransaction(async (session) => {
                logger.info(`Creating order with transaction for user: ${userId}`);

                // 1. Create order in database
                const [order] = await Order.create([{
                    userId,
                    items: cart.items,
                    address,
                    timeSlot,
                    subtotal: cart.subtotal,
                    deliveryFee,
                    total,
                    payment: {
                        provider: paymentMethod,
                        status: paymentMethod === 'cod' ? 'pending' : 'created',
                        orderId: paymentMethod === 'cod' ? `cod_${Date.now()}` : null
                    },
                    status: paymentMethod === 'cod' ? 'confirmed' : 'placed'
                }], { session });

                logger.info(`Order created with ID: ${order._id}`);

                // 2. For COD, clear cart within transaction
                if (paymentMethod === 'cod') {
                    await Cart.findOneAndUpdate(
                        { userId },
                        { items: [], subtotal: 0 },
                        { session }
                    );
                    logger.info(`Cart cleared for user: ${userId}`);
                }

                // 3. For Razorpay, create payment order (outside transaction)
                let razorpayOrder = null;
                if (paymentMethod === 'razorpay') {
                    const amount = Math.round(total * 100); // Convert to paise

                    if (razorpay) {
                        razorpayOrder = await razorpay.orders.create({
                            amount,
                            currency: 'INR',
                            receipt: `ord_${Date.now()}`,
                            notes: {
                                userId: userId.toString(),
                                orderId: order._id.toString()
                            }
                        });
                    } else {
                        // Mock order for development
                        razorpayOrder = {
                            id: `order_${Date.now()}`,
                            amount,
                            currency: 'INR'
                        };
                    }

                    // Update order with Razorpay order ID within transaction
                    await Order.findByIdAndUpdate(
                        order._id,
                        { 'payment.orderId': razorpayOrder.id },
                        { session }
                    );
                }

                return { order, razorpayOrder };
            });

            // Transaction completed successfully
            order = result.order;
            razorpayOrder = result.razorpayOrder;

        } catch (transactionError) {
            // Check if error is due to missing replica set
            if (transactionError.message && transactionError.message.includes('replica set')) {
                logger.warn('⚠️  MongoDB transactions require a replica set. Falling back to non-transactional mode.');
                logger.warn('⚠️  For production, please configure MongoDB as a replica set.');
                logger.warn('⚠️  See DETAILED_TECHNICAL_DOCUMENTATION_PART3.md for setup instructions.');

                // Fall back to non-transactional mode
                logger.info(`Creating order WITHOUT transaction for user: ${userId}`);

                // 1. Create order
                order = await Order.create({
                    userId,
                    items: cart.items,
                    address,
                    timeSlot,
                    subtotal: cart.subtotal,
                    deliveryFee,
                    total,
                    payment: {
                        provider: paymentMethod,
                        status: paymentMethod === 'cod' ? 'pending' : 'created',
                        orderId: paymentMethod === 'cod' ? `cod_${Date.now()}` : null
                    },
                    status: paymentMethod === 'cod' ? 'confirmed' : 'placed'
                });

                logger.info(`Order created with ID: ${order._id}`);

                // 2. For COD, clear cart
                if (paymentMethod === 'cod') {
                    await Cart.findOneAndUpdate(
                        { userId },
                        { items: [], subtotal: 0 }
                    );
                    logger.info(`Cart cleared for user: ${userId}`);
                }

                // 3. For Razorpay, create payment order
                if (paymentMethod === 'razorpay') {
                    const amount = Math.round(total * 100);

                    if (razorpay) {
                        razorpayOrder = await razorpay.orders.create({
                            amount,
                            currency: 'INR',
                            receipt: `ord_${Date.now()}`,
                            notes: {
                                userId: userId.toString(),
                                orderId: order._id.toString()
                            }
                        });
                    } else {
                        razorpayOrder = {
                            id: `order_${Date.now()}`,
                            amount,
                            currency: 'INR'
                        };
                    }

                    await Order.findByIdAndUpdate(
                        order._id,
                        { 'payment.orderId': razorpayOrder.id }
                    );
                }
            } else {
                // Other transaction errors - rethrow
                throw transactionError;
            }
        }

        // Send response (works for both transactional and non-transactional modes)
        if (paymentMethod === 'razorpay') {
            res.json({
                success: true,
                data: {
                    orderId: order._id,
                    razorpayOrderId: razorpayOrder.id,
                    amount: Math.round(total * 100),
                    paymentMethod,
                    deliveryFee,
                    total
                }
            });
        } else {
            // COD order
            res.json({
                success: true,
                data: {
                    orderId: order._id,
                    paymentMethod,
                    deliveryFee,
                    total,
                    message: 'Order placed successfully! You will pay on delivery.'
                }
            });
        }
    } catch (error) {
        logger.error('Create order error:', error);
        res.status(500).json({
            success: false,
            error: error instanceof z.ZodError ? 'Validation error' : error.message || 'Failed to create order'
        });
    }
};

const getTimeSlots = async (req, res) => {
    try {
        const today = new Date();
        const timeSlots = [];

        // Generate time slots for next 2 days only
        for (let i = 0; i < 2; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() + i);

            const daySlots = [];

            // Generate 2-hour slots from 8 AM to 8 PM
            for (let hour = 8; hour < 20; hour += 2) {
                const startTime = `${hour.toString().padStart(2, '0')}:00`;
                const endTime = `${(hour + 2).toString().padStart(2, '0')}:00`;

                daySlots.push({
                    startTime,
                    endTime,
                    display: `${startTime} - ${endTime}`
                });
            }

            timeSlots.push({
                date: date.toISOString().split('T')[0],
                display: date.toLocaleDateString('en-IN', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                }),
                slots: daySlots
            });
        }

        res.json({
            success: true,
            data: { timeSlots }
        });
    } catch (error) {
        logger.error('Get time slots error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get time slots'
        });
    }
};

const verifyPayment = async (req, res) => {
    try {
        const { razorpayOrderId, paymentId, signature, orderId } = verifyPaymentSchema.parse(req.body);

        // Verify signature (if Razorpay is configured)
        if (razorpay && process.env.RAZORPAY_KEY_SECRET) {
            const expectedSignature = crypto
                .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
                .update(`${razorpayOrderId}|${paymentId}`)
                .digest('hex');

            if (expectedSignature !== signature) {
                return res.status(400).json({
                    success: false,
                    error: 'Invalid payment signature'
                });
            }
        }

        // Use transaction for atomic payment verification and cart clearing
        const { withTransaction } = require('../utils/transactionManager');

        const order = await withTransaction(async (session) => {
            // Update order with payment details
            const updatedOrder = await Order.findByIdAndUpdate(
                orderId,
                {
                    $set: {
                        payment: {
                            provider: 'razorpay',
                            status: 'paid',
                            orderId: razorpayOrderId,
                            paymentId,
                            signature
                        },
                        status: 'confirmed'
                    }
                },
                { new: true, session }
            );

            if (!updatedOrder) {
                throw new Error('Order not found');
            }

            // Clear user's cart
            await Cart.findOneAndUpdate(
                { userId: req.user._id },
                { items: [], subtotal: 0 },
                { session }
            );

            logger.info(`Payment verified and cart cleared for order: ${orderId}`);
            return updatedOrder;
        });

        res.json({
            success: true,
            data: { order }
        });
    } catch (error) {
        logger.error('Verify payment error:', error);
        res.status(400).json({
            success: false,
            error: error instanceof z.ZodError ? 'Validation error' : error.message || 'Payment verification failed'
        });
    }
};

module.exports = { saveAddress, createOrder, getTimeSlots, verifyPayment };

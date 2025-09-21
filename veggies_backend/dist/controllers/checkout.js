"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPayment = exports.getTimeSlots = exports.createOrder = exports.saveAddress = void 0;
const zod_1 = require("zod");
const razorpay_1 = __importDefault(require("razorpay"));
const crypto_1 = __importDefault(require("crypto"));
const Cart_1 = require("../models/Cart");
const Order_1 = require("../models/Order");
const logger_1 = require("../utils/logger");
// Validation schemas
const addressSchema = zod_1.z.object({
    line1: zod_1.z.string().min(1, 'Address line 1 is required'),
    line2: zod_1.z.string().optional().nullable(),
    city: zod_1.z.string().min(1, 'City is required'),
    state: zod_1.z.string().min(1, 'State is required'),
    pincode: zod_1.z.string().min(6, 'Pincode must be at least 6 characters'),
    phone: zod_1.z.string().optional().default('0000000000')
});
const createOrderSchema = zod_1.z.object({
    address: addressSchema,
    paymentMethod: zod_1.z.enum(['razorpay', 'cod']),
    timeSlot: zod_1.z.object({
        date: zod_1.z.string().min(1, 'Delivery date is required'),
        startTime: zod_1.z.string().min(1, 'Start time is required'),
        endTime: zod_1.z.string().min(1, 'End time is required')
    })
});
const verifyPaymentSchema = zod_1.z.object({
    razorpayOrderId: zod_1.z.string().min(1, 'Razorpay order ID is required'),
    paymentId: zod_1.z.string().min(1, 'Payment ID is required'),
    signature: zod_1.z.string().min(1, 'Signature is required'),
    orderId: zod_1.z.string().min(1, 'Order ID is required')
});
// Delivery charges configuration
const DELIVERY_FEE = 40;
const FREE_DELIVERY_THRESHOLD = 200;
// Initialize Razorpay (only if keys are provided)
let razorpay = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new razorpay_1.default({
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
    }
    catch (error) {
        logger_1.logger.error('Save address error:', error);
        res.status(400).json({
            success: false,
            error: error instanceof zod_1.z.ZodError ? 'Validation error' : 'Failed to save address'
        });
    }
};
exports.saveAddress = saveAddress;
const createOrder = async (req, res) => {
    try {
        const { address, paymentMethod, timeSlot } = createOrderSchema.parse(req.body);
        const userId = req.user._id;
        // Get user's cart
        const cart = await Cart_1.Cart.findOne({ userId });
        if (!cart || cart.items.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Cart is empty'
            });
        }
        // Calculate delivery fee
        const deliveryFee = cart.subtotal < FREE_DELIVERY_THRESHOLD ? DELIVERY_FEE : 0;
        const total = cart.subtotal + deliveryFee;
        // Create order in database
        const order = await Order_1.Order.create({
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
        // If COD, clear cart immediately
        if (paymentMethod === 'cod') {
            await Cart_1.Cart.findOneAndUpdate({ userId }, { items: [], subtotal: 0 });
        }
        // For Razorpay, create payment order
        if (paymentMethod === 'razorpay') {
            const amount = Math.round(total * 100); // Convert to paise
            let razorpayOrder;
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
            }
            else {
                // Mock order for development
                razorpayOrder = {
                    id: `order_${Date.now()}`,
                    amount,
                    currency: 'INR'
                };
            }
            // Update order with Razorpay order ID
            await Order_1.Order.findByIdAndUpdate(order._id, {
                'payment.orderId': razorpayOrder.id
            });
            res.json({
                success: true,
                data: {
                    orderId: order._id,
                    razorpayOrderId: razorpayOrder.id,
                    amount,
                    paymentMethod,
                    deliveryFee,
                    total
                }
            });
        }
        else {
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
    }
    catch (error) {
        logger_1.logger.error('Create order error:', error);
        res.status(500).json({
            success: false,
            error: error instanceof zod_1.z.ZodError ? 'Validation error' : 'Failed to create order'
        });
    }
};
exports.createOrder = createOrder;
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
    }
    catch (error) {
        logger_1.logger.error('Get time slots error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to get time slots'
        });
    }
};
exports.getTimeSlots = getTimeSlots;
const verifyPayment = async (req, res) => {
    try {
        const { razorpayOrderId, paymentId, signature, orderId } = verifyPaymentSchema.parse(req.body);
        // Verify signature (if Razorpay is configured)
        if (razorpay && process.env.RAZORPAY_KEY_SECRET) {
            const expectedSignature = crypto_1.default
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
        // Update order with payment details
        const order = await Order_1.Order.findByIdAndUpdate(orderId, {
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
        }, { new: true });
        if (!order) {
            return res.status(404).json({
                success: false,
                error: 'Order not found'
            });
        }
        // Clear user's cart
        await Cart_1.Cart.findOneAndUpdate({ userId: req.user._id }, { items: [], subtotal: 0 });
        res.json({
            success: true,
            data: { order }
        });
    }
    catch (error) {
        logger_1.logger.error('Verify payment error:', error);
        res.status(400).json({
            success: false,
            error: error instanceof zod_1.z.ZodError ? 'Validation error' : 'Payment verification failed'
        });
    }
};
exports.verifyPayment = verifyPayment;
//# sourceMappingURL=checkout.js.map
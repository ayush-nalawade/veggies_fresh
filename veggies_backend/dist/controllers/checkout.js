"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPayment = exports.createOrder = exports.saveAddress = void 0;
const zod_1 = require("zod");
const razorpay_1 = __importDefault(require("razorpay"));
const crypto_1 = __importDefault(require("crypto"));
const Cart_1 = require("../models/Cart");
const Order_1 = require("../models/Order");
const logger_1 = require("../utils/logger");
// Validation schemas
const addressSchema = zod_1.z.object({
    line1: zod_1.z.string().min(1, 'Address line 1 is required'),
    line2: zod_1.z.string().optional(),
    city: zod_1.z.string().min(1, 'City is required'),
    state: zod_1.z.string().min(1, 'State is required'),
    pincode: zod_1.z.string().min(6, 'Pincode must be at least 6 characters'),
    phone: zod_1.z.string().min(10, 'Phone number must be at least 10 characters')
});
const verifyPaymentSchema = zod_1.z.object({
    razorpayOrderId: zod_1.z.string().min(1, 'Razorpay order ID is required'),
    paymentId: zod_1.z.string().min(1, 'Payment ID is required'),
    signature: zod_1.z.string().min(1, 'Signature is required'),
    orderId: zod_1.z.string().min(1, 'Order ID is required')
});
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
        const userId = req.user._id;
        // Get user's cart
        const cart = await Cart_1.Cart.findOne({ userId });
        if (!cart || cart.items.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Cart is empty'
            });
        }
        // Calculate total amount (in paise for Razorpay)
        const amount = Math.round(cart.subtotal * 100);
        // Create Razorpay order (if Razorpay is configured)
        let razorpayOrder;
        if (razorpay) {
            razorpayOrder = await razorpay.orders.create({
                amount,
                currency: 'INR',
                receipt: `ord_${Date.now()}`,
                notes: {
                    userId: userId.toString()
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
        // Create order in database
        const order = await Order_1.Order.create({
            userId,
            items: cart.items,
            address: req.body.address || {}, // Address should be provided
            subtotal: cart.subtotal,
            deliveryFee: 0, // Free delivery for now
            total: cart.subtotal,
            payment: {
                provider: 'razorpay',
                status: 'created',
                orderId: razorpayOrder.id
            },
            status: 'placed'
        });
        res.json({
            success: true,
            data: {
                razorpayOrderId: razorpayOrder.id,
                amount,
                orderId: order._id
            }
        });
    }
    catch (error) {
        logger_1.logger.error('Create order error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create order'
        });
    }
};
exports.createOrder = createOrder;
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
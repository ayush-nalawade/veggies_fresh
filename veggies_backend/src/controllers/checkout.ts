import { Response } from 'express';
import { z } from 'zod';
import Razorpay from 'razorpay';
import crypto from 'crypto';
import { Cart } from '../models/Cart';
import { Order } from '../models/Order';
import { AuthRequest } from '../middlewares/auth';
import { logger } from '../utils/logger';

// Validation schemas
const addressSchema = z.object({
  line1: z.string().min(1, 'Address line 1 is required'),
  line2: z.string().optional(),
  city: z.string().min(1, 'City is required'),
  state: z.string().min(1, 'State is required'),
  pincode: z.string().min(6, 'Pincode must be at least 6 characters'),
  phone: z.string().min(10, 'Phone number must be at least 10 characters')
});

const verifyPaymentSchema = z.object({
  razorpayOrderId: z.string().min(1, 'Razorpay order ID is required'),
  paymentId: z.string().min(1, 'Payment ID is required'),
  signature: z.string().min(1, 'Signature is required'),
  orderId: z.string().min(1, 'Order ID is required')
});

// Initialize Razorpay (only if keys are provided)
let razorpay: Razorpay | null = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
  razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
  });
}

export const saveAddress = async (req: AuthRequest, res: Response) => {
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

export const createOrder = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user!._id;
    
    // Get user's cart
    const cart = await Cart.findOne({ userId });
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
    } else {
      // Mock order for development
      razorpayOrder = {
        id: `order_${Date.now()}`,
        amount,
        currency: 'INR'
      };
    }

    // Create order in database
    const order = await Order.create({
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
  } catch (error) {
    logger.error('Create order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create order'
    });
  }
};

export const verifyPayment = async (req: AuthRequest, res: Response) => {
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

    // Update order with payment details
    const order = await Order.findByIdAndUpdate(
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
      { new: true }
    );

    if (!order) {
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    // Clear user's cart
    await Cart.findOneAndUpdate(
      { userId: req.user!._id },
      { items: [], subtotal: 0 }
    );

    res.json({
      success: true,
      data: { order }
    });
  } catch (error) {
    logger.error('Verify payment error:', error);
    res.status(400).json({
      success: false,
      error: error instanceof z.ZodError ? 'Validation error' : 'Payment verification failed'
    });
  }
};

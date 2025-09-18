import mongoose, { Document, Schema } from 'mongoose';
import { IAddress } from './User';
import { ICartItem } from './Cart';

export interface IPayment {
  provider: 'razorpay' | 'stripe';
  status: 'created' | 'paid' | 'failed';
  orderId?: string;
  paymentId?: string;
  signature?: string;
}

export interface IOrder extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  items: ICartItem[];
  address: IAddress;
  subtotal: number;
  deliveryFee: number;
  total: number;
  payment: IPayment;
  status: 'placed' | 'confirmed' | 'preparing' | 'out_for_delivery' | 'delivered' | 'cancelled';
  createdAt: Date;
  updatedAt: Date;
}

const paymentSchema = new Schema<IPayment>({
  provider: { type: String, enum: ['razorpay', 'stripe'], required: true },
  status: { type: String, enum: ['created', 'paid', 'failed'], required: true },
  orderId: { type: String },
  paymentId: { type: String },
  signature: { type: String }
});

const orderSchema = new Schema<IOrder>({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  items: [{ type: Schema.Types.Mixed }], // Using ICartItem structure
  address: { type: Schema.Types.Mixed, required: true }, // Using IAddress structure
  subtotal: { type: Number, required: true },
  deliveryFee: { type: Number, default: 0 },
  total: { type: Number, required: true },
  payment: { type: paymentSchema, required: true },
  status: { 
    type: String, 
    enum: ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'],
    default: 'placed'
  }
}, {
  timestamps: true
});

// Indexes for faster queries
orderSchema.index({ userId: 1, createdAt: -1 });
orderSchema.index({ status: 1 });

export const Order = mongoose.model<IOrder>('Order', orderSchema);

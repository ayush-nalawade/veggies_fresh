import mongoose, { Document } from 'mongoose';
import { IAddress } from './User';
import { ICartItem } from './Cart';
export interface ITimeSlot {
    date: string;
    startTime: string;
    endTime: string;
}
export interface IPayment {
    provider: 'razorpay' | 'stripe' | 'cod';
    status: 'created' | 'paid' | 'failed' | 'pending';
    orderId?: string;
    paymentId?: string;
    signature?: string;
}
export interface IOrder extends Document {
    _id: mongoose.Types.ObjectId;
    userId: mongoose.Types.ObjectId;
    items: ICartItem[];
    address: IAddress;
    timeSlot: ITimeSlot;
    subtotal: number;
    deliveryFee: number;
    total: number;
    payment: IPayment;
    status: 'placed' | 'confirmed' | 'preparing' | 'out_for_delivery' | 'delivered' | 'cancelled';
    createdAt: Date;
    updatedAt: Date;
}
export declare const Order: mongoose.Model<IOrder, {}, {}, {}, mongoose.Document<unknown, {}, IOrder> & IOrder & Required<{
    _id: mongoose.Types.ObjectId;
}>, any>;
//# sourceMappingURL=Order.d.ts.map
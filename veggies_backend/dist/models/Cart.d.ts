import mongoose, { Document } from 'mongoose';
export interface ICartItem {
    productId: mongoose.Types.ObjectId;
    name: string;
    image: string;
    unit: 'kg' | 'g' | 'pcs' | 'bundle';
    qty: number;
    unitPrice: number;
    price: number;
}
export interface ICart extends Document {
    _id: mongoose.Types.ObjectId;
    userId: mongoose.Types.ObjectId;
    items: ICartItem[];
    subtotal: number;
    createdAt: Date;
    updatedAt: Date;
}
export declare const Cart: mongoose.Model<ICart, {}, {}, {}, mongoose.Document<unknown, {}, ICart> & ICart & Required<{
    _id: mongoose.Types.ObjectId;
}>, any>;
//# sourceMappingURL=Cart.d.ts.map
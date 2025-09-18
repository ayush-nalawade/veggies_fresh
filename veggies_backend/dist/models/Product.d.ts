import mongoose, { Document } from 'mongoose';
export interface IUnitPrice {
    unit: 'kg' | 'g' | 'pcs' | 'bundle';
    step: number;
    baseQty: number;
    price: number;
    compareAt?: number;
    stock: number;
}
export interface IProduct extends Document {
    _id: mongoose.Types.ObjectId;
    name: string;
    slug: string;
    categoryId: mongoose.Types.ObjectId;
    images: string[];
    description?: string;
    unitPrices: IUnitPrice[];
    rating?: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
export declare const Product: mongoose.Model<IProduct, {}, {}, {}, mongoose.Document<unknown, {}, IProduct> & IProduct & Required<{
    _id: mongoose.Types.ObjectId;
}>, any>;
//# sourceMappingURL=Product.d.ts.map
import mongoose, { Document } from 'mongoose';
export interface ICategory extends Document {
    _id: mongoose.Types.ObjectId;
    name: string;
    iconUrl?: string;
    sort: number;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
}
export declare const Category: mongoose.Model<ICategory, {}, {}, {}, mongoose.Document<unknown, {}, ICategory> & ICategory & Required<{
    _id: mongoose.Types.ObjectId;
}>, any>;
//# sourceMappingURL=Category.d.ts.map
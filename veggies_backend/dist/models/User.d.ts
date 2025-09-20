import mongoose, { Document } from 'mongoose';
export interface IAddress {
    _id?: mongoose.Types.ObjectId;
    type: 'home' | 'work' | 'other';
    name: string;
    line1: string;
    line2?: string;
    city: string;
    state: string;
    pincode: string;
    country: string;
    isDefault: boolean;
}
export interface IUser extends Document {
    _id: mongoose.Types.ObjectId;
    name: string;
    email: string;
    phone?: string;
    googleId?: string;
    passwordHash?: string;
    avatarUrl?: string;
    addresses: IAddress[];
    role: 'user' | 'admin';
    createdAt: Date;
    updatedAt: Date;
}
export declare const User: mongoose.Model<IUser, {}, {}, {}, mongoose.Document<unknown, {}, IUser> & IUser & Required<{
    _id: mongoose.Types.ObjectId;
}>, any>;
//# sourceMappingURL=User.d.ts.map
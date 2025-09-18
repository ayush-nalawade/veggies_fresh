import mongoose, { Document, Schema } from 'mongoose';

export interface IAddress {
  line1: string;
  line2?: string;
  city: string;
  state: string;
  pincode: string;
  phone: string;
}

export interface IUser extends Document {
  _id: mongoose.Types.ObjectId;
  name: string;
  email: string;
  googleId?: string;
  passwordHash?: string;
  avatarUrl?: string;
  addresses: IAddress[];
  role: 'user' | 'admin';
  createdAt: Date;
  updatedAt: Date;
}

const addressSchema = new Schema<IAddress>({
  line1: { type: String, required: true },
  line2: { type: String },
  city: { type: String, required: true },
  state: { type: String, required: true },
  pincode: { type: String, required: true },
  phone: { type: String, required: true }
});

const userSchema = new Schema<IUser>({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  googleId: { type: String, sparse: true },
  passwordHash: { type: String },
  avatarUrl: { type: String },
  addresses: [addressSchema],
  role: { type: String, enum: ['user', 'admin'], default: 'user' }
}, {
  timestamps: true
});

// Index for faster queries
userSchema.index({ email: 1 });
userSchema.index({ googleId: 1 });

export const User = mongoose.model<IUser>('User', userSchema);

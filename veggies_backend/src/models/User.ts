import mongoose, { Document, Schema } from 'mongoose';

export interface IAddress {
  _id?: mongoose.Types.ObjectId;
  type: 'home' | 'work' | 'other';
  line1: string; // Flat no/ Building name
  line2?: string; // Sector/ Locality
  landmark?: string; // Landmark (optional)
  area?: string; // Delivery area (e.g., "Kandivali (W)", "Malad (W)")
  city: string;
  state: string;
  pincode: string;
  country: string;
  isDefault: boolean;
}

export interface IUser extends Document {
  _id: mongoose.Types.ObjectId;
  name: string;
  email?: string;
  phone?: string;
  googleId?: string;
  passwordHash?: string;
  avatarUrl?: string;
  addresses: IAddress[];
  role: 'user' | 'admin';
  isPhoneVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const addressSchema = new Schema<IAddress>({
  type: { type: String, enum: ['home', 'work', 'other'], required: true, default: 'home' },
  line1: { type: String, required: true }, // Flat no/ Building name
  line2: { type: String }, // Sector/ Locality
  landmark: { type: String }, // Landmark (optional)
  area: { type: String }, // Delivery area
  city: { type: String, required: true },
  state: { type: String, required: true },
  pincode: { type: String, required: true },
  country: { type: String, required: true, default: 'India' },
  isDefault: { type: Boolean, default: false }
});

const userSchema = new Schema<IUser>({
  name: { type: String, required: true, trim: true },
  email: { type: String, unique: true, sparse: true, lowercase: true },
  phone: { type: String, unique: true, sparse: true },
  googleId: { type: String, sparse: true },
  passwordHash: { type: String },
  avatarUrl: { type: String },
  addresses: [addressSchema],
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
  isPhoneVerified: { type: Boolean, default: false }
}, {
  timestamps: true
});

// Index for faster queries
userSchema.index({ email: 1 });
userSchema.index({ phone: 1 });
userSchema.index({ googleId: 1 });

export const User = mongoose.model<IUser>('User', userSchema);
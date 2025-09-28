import mongoose, { Document, Schema } from 'mongoose';

export interface IOTP extends Document {
  _id: mongoose.Types.ObjectId;
  phone: string;
  otp: string;
  expiresAt: Date;
  isUsed: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const otpSchema = new Schema<IOTP>({
  phone: { 
    type: String, 
    required: true,
    index: true 
  },
  otp: { 
    type: String, 
    required: true 
  },
  expiresAt: { 
    type: Date, 
    required: true,
    index: { expireAfterSeconds: 0 } // TTL index
  },
  isUsed: { 
    type: Boolean, 
    default: false 
  }
}, {
  timestamps: true
});

// Index for faster queries
otpSchema.index({ phone: 1, isUsed: 1 });

export const OTP = mongoose.model<IOTP>('OTP', otpSchema);

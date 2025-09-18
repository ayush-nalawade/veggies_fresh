import mongoose, { Document, Schema } from 'mongoose';

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

const cartItemSchema = new Schema<ICartItem>({
  productId: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
  name: { type: String, required: true },
  image: { type: String, required: true },
  unit: { type: String, enum: ['kg', 'g', 'pcs', 'bundle'], required: true },
  qty: { type: Number, required: true, min: 0 },
  unitPrice: { type: Number, required: true },
  price: { type: Number, required: true }
});

const cartSchema = new Schema<ICart>({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  items: [cartItemSchema],
  subtotal: { type: Number, default: 0 }
}, {
  timestamps: true
});

// Index for faster queries
cartSchema.index({ userId: 1 });

// Calculate subtotal before saving
cartSchema.pre('save', function(next) {
  this.subtotal = this.items.reduce((sum, item) => sum + item.price, 0);
  next();
});

export const Cart = mongoose.model<ICart>('Cart', cartSchema);

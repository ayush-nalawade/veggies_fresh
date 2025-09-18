import mongoose, { Document, Schema } from 'mongoose';

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

const unitPriceSchema = new Schema<IUnitPrice>({
  unit: { type: String, enum: ['kg', 'g', 'pcs', 'bundle'], required: true },
  step: { type: Number, required: true },
  baseQty: { type: Number, required: true },
  price: { type: Number, required: true },
  compareAt: { type: Number },
  stock: { type: Number, required: true, min: 0 }
});

const productSchema = new Schema<IProduct>({
  name: { type: String, required: true, trim: true },
  slug: { type: String, required: true, unique: true },
  categoryId: { type: Schema.Types.ObjectId, ref: 'Category', required: true },
  images: [{ type: String }],
  description: { type: String },
  unitPrices: [unitPriceSchema],
  rating: { type: Number, min: 0, max: 5 },
  isActive: { type: Boolean, default: true }
}, {
  timestamps: true
});

// Indexes for faster queries
productSchema.index({ categoryId: 1, isActive: 1 });
productSchema.index({ slug: 1 });
productSchema.index({ name: 'text', description: 'text' });

// Generate slug from name
productSchema.pre('save', function(next) {
  if (this.isModified('name') || !this.slug) {
    this.slug = this.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  }
  next();
});

export const Product = mongoose.model<IProduct>('Product', productSchema);

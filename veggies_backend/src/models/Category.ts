import mongoose, { Document, Schema } from 'mongoose';

export interface ICategory extends Document {
  _id: mongoose.Types.ObjectId;
  name: string;
  iconUrl?: string;
  sort: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const categorySchema = new Schema<ICategory>({
  name: { type: String, required: true, trim: true },
  iconUrl: { type: String },
  sort: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true }
}, {
  timestamps: true
});

// Index for faster queries
categorySchema.index({ isActive: 1, sort: 1 });

export const Category = mongoose.model<ICategory>('Category', categorySchema);

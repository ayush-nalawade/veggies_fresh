const mongoose = require('mongoose');
const { Schema } = mongoose;

const cartItemSchema = new Schema({
    productId: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
    name: { type: String, required: true },
    image: { type: String, required: true },
    unit: { type: String, enum: ['kg', 'g', 'pcs', 'bundle'], required: true },
    qty: { type: Number, required: true, min: 0 },
    unitPrice: { type: Number, required: true },
    price: { type: Number, required: true }
});

const cartSchema = new Schema({
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    items: [cartItemSchema],
    subtotal: { type: Number, default: 0 }
}, {
    timestamps: true
});

// Index for faster queries
cartSchema.index({ userId: 1 });

// Calculate subtotal before saving
cartSchema.pre('save', function (next) {
    this.subtotal = this.items.reduce((sum, item) => sum + item.price, 0);
    next();
});

const Cart = mongoose.model('Cart', cartSchema);

module.exports = { Cart };

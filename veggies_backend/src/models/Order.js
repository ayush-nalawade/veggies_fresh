const mongoose = require('mongoose');
const { Schema } = mongoose;

const timeSlotSchema = new Schema({
    date: { type: String, required: true },
    startTime: { type: String, required: true },
    endTime: { type: String, required: true }
});

const paymentSchema = new Schema({
    provider: { type: String, enum: ['razorpay', 'stripe', 'cod'], required: true },
    status: { type: String, enum: ['created', 'paid', 'failed', 'pending'], required: true },
    orderId: { type: String },
    paymentId: { type: String },
    signature: { type: String }
});

const orderSchema = new Schema({
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    items: [{ type: Schema.Types.Mixed }], // Using ICartItem structure
    address: { type: Schema.Types.Mixed, required: true }, // Using IAddress structure
    timeSlot: { type: timeSlotSchema, required: true },
    subtotal: { type: Number, required: true },
    deliveryFee: { type: Number, default: 0 },
    total: { type: Number, required: true },
    payment: { type: paymentSchema, required: true },
    status: {
        type: String,
        enum: ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'],
        default: 'placed'
    }
}, {
    timestamps: true
});

// Indexes for faster queries
orderSchema.index({ userId: 1, createdAt: -1 });
orderSchema.index({ status: 1 });

const Order = mongoose.model('Order', orderSchema);

module.exports = { Order };

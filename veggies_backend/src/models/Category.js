const mongoose = require('mongoose');
const { Schema } = mongoose;

const categorySchema = new Schema({
    name: { type: String, required: true, trim: true },
    iconUrl: { type: String },
    sort: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true }
}, {
    timestamps: true
});

// Index for faster queries
categorySchema.index({ isActive: 1, sort: 1 });

const Category = mongoose.model('Category', categorySchema);

module.exports = { Category };

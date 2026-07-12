const mongoose = require('mongoose');
const { Schema } = mongoose;

const addressSchema = new Schema({
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

const userSchema = new Schema({
    name: { type: String, required: true, trim: true },
    email: { type: String, unique: true, sparse: true, lowercase: true },
    phone: { type: String, unique: true, sparse: true },
    googleId: { type: String, sparse: true },
    passwordHash: { type: String },
    avatarUrl: { type: String },
    addresses: [addressSchema],
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    isPhoneVerified: { type: Boolean, default: false },
    // Incremented on logout to invalidate all existing JWTs for this user
    tokenVersion: { type: Number, default: 0 }
}, {
    timestamps: true
});

// Index for faster queries
userSchema.index({ email: 1 });
userSchema.index({ phone: 1 });
userSchema.index({ googleId: 1 });

const User = mongoose.model('User', userSchema);

module.exports = { User };

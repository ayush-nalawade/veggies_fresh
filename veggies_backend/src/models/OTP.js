const mongoose = require('mongoose');
const { Schema } = mongoose;

const otpSchema = new Schema({
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

const OTP = mongoose.model('OTP', otpSchema);

module.exports = { OTP };

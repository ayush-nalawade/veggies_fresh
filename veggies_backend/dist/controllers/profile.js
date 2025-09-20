"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setDefaultAddress = exports.deleteAddress = exports.updateAddress = exports.addAddress = exports.getAddresses = exports.updateProfile = exports.getProfile = void 0;
const zod_1 = require("zod");
const User_1 = require("../models/User");
const logger_1 = require("../utils/logger");
// Validation schemas
const updateProfileSchema = zod_1.z.object({
    name: zod_1.z.string().min(2, 'Name must be at least 2 characters').optional(),
    email: zod_1.z.string().email('Invalid email format').optional(),
    phone: zod_1.z.string().min(10, 'Phone number must be at least 10 digits').optional(),
});
const addressSchema = zod_1.z.object({
    type: zod_1.z.enum(['home', 'work', 'other']),
    name: zod_1.z.string().min(2, 'Address name is required'),
    line1: zod_1.z.string().min(5, 'Address line 1 is required'),
    line2: zod_1.z.string().optional(),
    city: zod_1.z.string().min(2, 'City is required'),
    state: zod_1.z.string().min(2, 'State is required'),
    pincode: zod_1.z.string().min(6, 'Pincode must be at least 6 digits'),
    country: zod_1.z.string().min(2, 'Country is required').default('India'),
    isDefault: zod_1.z.boolean().optional().default(false),
});
// Get user profile
const getProfile = async (req, res) => {
    try {
        const user = await User_1.User.findById(req.user._id).select('-password');
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        res.json({
            success: true,
            data: user
        });
    }
    catch (error) {
        logger_1.logger.error('Get profile error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch profile'
        });
    }
};
exports.getProfile = getProfile;
// Update user profile
const updateProfile = async (req, res) => {
    try {
        const updateData = updateProfileSchema.parse(req.body);
        // Check if email is being updated and if it's already taken
        if (updateData.email) {
            const existingUser = await User_1.User.findOne({
                email: updateData.email,
                _id: { $ne: req.user._id }
            });
            if (existingUser) {
                return res.status(400).json({
                    success: false,
                    error: 'Email already exists'
                });
            }
        }
        const user = await User_1.User.findByIdAndUpdate(req.user._id, { $set: updateData }, { new: true, select: '-password' });
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        res.json({
            success: true,
            data: user,
            message: 'Profile updated successfully'
        });
    }
    catch (error) {
        logger_1.logger.error('Update profile error:', error);
        if (error instanceof zod_1.z.ZodError) {
            return res.status(400).json({
                success: false,
                error: 'Validation error',
                details: error.errors
            });
        }
        res.status(500).json({
            success: false,
            error: 'Failed to update profile'
        });
    }
};
exports.updateProfile = updateProfile;
// Get user addresses
const getAddresses = async (req, res) => {
    try {
        const user = await User_1.User.findById(req.user._id).select('addresses');
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        res.json({
            success: true,
            data: user.addresses || []
        });
    }
    catch (error) {
        logger_1.logger.error('Get addresses error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch addresses'
        });
    }
};
exports.getAddresses = getAddresses;
// Add new address
const addAddress = async (req, res) => {
    try {
        const addressData = addressSchema.parse(req.body);
        const user = await User_1.User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        // If this is set as default, unset other default addresses
        if (addressData.isDefault) {
            user.addresses = user.addresses.map(addr => ({
                ...addr,
                isDefault: false
            }));
        }
        // Add the new address
        user.addresses.push({
            ...addressData,
            _id: undefined // Let MongoDB generate the ID
        });
        await user.save();
        res.json({
            success: true,
            data: user.addresses,
            message: 'Address added successfully'
        });
    }
    catch (error) {
        logger_1.logger.error('Add address error:', error);
        if (error instanceof zod_1.z.ZodError) {
            return res.status(400).json({
                success: false,
                error: 'Validation error',
                details: error.errors
            });
        }
        res.status(500).json({
            success: false,
            error: 'Failed to add address'
        });
    }
};
exports.addAddress = addAddress;
// Update address
const updateAddress = async (req, res) => {
    try {
        const { addressId } = req.params;
        const addressData = addressSchema.parse(req.body);
        const user = await User_1.User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        const addressIndex = user.addresses.findIndex(addr => addr._id?.toString() === addressId);
        if (addressIndex === -1) {
            return res.status(404).json({
                success: false,
                error: 'Address not found'
            });
        }
        // If this is set as default, unset other default addresses
        if (addressData.isDefault) {
            user.addresses = user.addresses.map((addr, index) => ({
                ...addr,
                isDefault: index === addressIndex ? true : false
            }));
        }
        else {
            user.addresses[addressIndex] = {
                ...user.addresses[addressIndex],
                ...addressData
            };
        }
        await user.save();
        res.json({
            success: true,
            data: user.addresses,
            message: 'Address updated successfully'
        });
    }
    catch (error) {
        logger_1.logger.error('Update address error:', error);
        if (error instanceof zod_1.z.ZodError) {
            return res.status(400).json({
                success: false,
                error: 'Validation error',
                details: error.errors
            });
        }
        res.status(500).json({
            success: false,
            error: 'Failed to update address'
        });
    }
};
exports.updateAddress = updateAddress;
// Delete address
const deleteAddress = async (req, res) => {
    try {
        const { addressId } = req.params;
        const user = await User_1.User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        const addressIndex = user.addresses.findIndex(addr => addr._id?.toString() === addressId);
        if (addressIndex === -1) {
            return res.status(404).json({
                success: false,
                error: 'Address not found'
            });
        }
        user.addresses.splice(addressIndex, 1);
        await user.save();
        res.json({
            success: true,
            data: user.addresses,
            message: 'Address deleted successfully'
        });
    }
    catch (error) {
        logger_1.logger.error('Delete address error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete address'
        });
    }
};
exports.deleteAddress = deleteAddress;
// Set default address
const setDefaultAddress = async (req, res) => {
    try {
        const { addressId } = req.params;
        const user = await User_1.User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }
        const addressIndex = user.addresses.findIndex(addr => addr._id?.toString() === addressId);
        if (addressIndex === -1) {
            return res.status(404).json({
                success: false,
                error: 'Address not found'
            });
        }
        // Unset all default addresses
        user.addresses = user.addresses.map(addr => ({
            ...addr,
            isDefault: false
        }));
        // Set the selected address as default
        user.addresses[addressIndex].isDefault = true;
        await user.save();
        res.json({
            success: true,
            data: user.addresses,
            message: 'Default address updated successfully'
        });
    }
    catch (error) {
        logger_1.logger.error('Set default address error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to set default address'
        });
    }
};
exports.setDefaultAddress = setDefaultAddress;
//# sourceMappingURL=profile.js.map
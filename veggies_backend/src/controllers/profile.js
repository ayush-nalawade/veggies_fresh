const { z } = require('zod');
const { User } = require('../models/User');
const { logger } = require('../utils/logger');

// Validation schemas
const updateProfileSchema = z.object({
    name: z.string().min(2, 'Name must be at least 2 characters').optional(),
    email: z.union([
        z.string().email('Invalid email format'),
        z.null(),
        z.literal('')
    ]).optional(),
    phone: z.string().min(10, 'Phone number must be at least 10 digits').optional(),
});

const addressSchema = z.object({
    type: z.enum(['home', 'work', 'other']),
    line1: z.string().min(3, 'Flat no/ Building name is required'),
    line2: z.string().optional(), // Sector/ Locality
    landmark: z.string().optional(), // Landmark
    area: z.string().optional(), // Delivery area (Kandivali W, Malad W)
    city: z.string().min(2, 'City is required'),
    state: z.string().min(2, 'State is required'),
    pincode: z.string().min(6, 'Pincode must be at least 6 digits'),
    country: z.string().min(2, 'Country is required').default('India'),
    isDefault: z.boolean().optional().default(false),
});

// Get user profile
const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).select('-password');

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
    } catch (error) {
        logger.error('Get profile error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch profile'
        });
    }
};

// Update user profile
const updateProfile = async (req, res) => {
    try {
        const updateData = updateProfileSchema.parse(req.body);

        // Build update object
        const setData = {};
        const unsetData = {};

        // Handle name
        if (updateData.name !== undefined) {
            if (updateData.name !== null && updateData.name.trim() !== '') {
                setData.name = updateData.name.trim();
            }
        }

        // Handle email
        if (updateData.email !== undefined) {
            if (updateData.email !== null && updateData.email.trim() !== '') {
                // Check if email is already taken
                const existingUser = await User.findOne({
                    email: updateData.email.trim(),
                    _id: { $ne: req.user._id }
                });

                if (existingUser) {
                    return res.status(400).json({
                        success: false,
                        error: 'Email already exists'
                    });
                }
                setData.email = updateData.email.trim();
            } else {
                // Remove email if it's null or empty
                unsetData.email = '';
            }
        }

        // Handle phone
        if (updateData.phone !== undefined) {
            if (updateData.phone !== null && updateData.phone.trim() !== '') {
                setData.phone = updateData.phone.trim();
            }
        }

        // Build the update query
        const updateQuery = {};
        if (Object.keys(setData).length > 0) {
            updateQuery.$set = setData;
        }
        if (Object.keys(unsetData).length > 0) {
            updateQuery.$unset = unsetData;
        }

        // Only update if there's something to update
        if (Object.keys(updateQuery).length === 0) {
            // Just return the current user
            const user = await User.findById(req.user._id).select('-password');
            if (!user) {
                return res.status(404).json({
                    success: false,
                    error: 'User not found'
                });
            }
            return res.json({
                success: true,
                data: user,
                message: 'Profile updated successfully'
            });
        }

        const user = await User.findByIdAndUpdate(
            req.user._id,
            updateQuery,
            { new: true, select: '-password' }
        );

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
    } catch (error) {
        logger.error('Update profile error:', error);
        if (error instanceof z.ZodError) {
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

// Get user addresses
const getAddresses = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).select('addresses');

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
    } catch (error) {
        logger.error('Get addresses error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch addresses'
        });
    }
};

// Add new address
const addAddress = async (req, res) => {
    try {
        const addressData = addressSchema.parse(req.body);

        const user = await User.findById(req.user._id);
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
    } catch (error) {
        logger.error('Add address error:', error);
        if (error instanceof z.ZodError) {
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

// Update address
const updateAddress = async (req, res) => {
    try {
        const { addressId } = req.params;
        const addressData = addressSchema.parse(req.body);

        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        const addressIndex = user.addresses.findIndex(
            addr => addr._id?.toString() === addressId
        );

        if (addressIndex === -1) {
            return res.status(404).json({
                success: false,
                error: 'Address not found'
            });
        }

        // Update the address with new data
        user.addresses[addressIndex] = {
            ...user.addresses[addressIndex],
            ...addressData
        };

        // If this is set as default, unset other default addresses
        if (addressData.isDefault) {
            user.addresses = user.addresses.map((addr, index) => ({
                ...addr,
                isDefault: index === addressIndex ? true : false
            }));
        }

        await user.save();

        res.json({
            success: true,
            data: user.addresses,
            message: 'Address updated successfully'
        });
    } catch (error) {
        logger.error('Update address error:', error);
        if (error instanceof z.ZodError) {
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

// Delete address
const deleteAddress = async (req, res) => {
    try {
        const { addressId } = req.params;

        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        const addressIndex = user.addresses.findIndex(
            addr => addr._id?.toString() === addressId
        );

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
    } catch (error) {
        logger.error('Delete address error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete address'
        });
    }
};

// Set default address
const setDefaultAddress = async (req, res) => {
    try {
        const { addressId } = req.params;

        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        const addressIndex = user.addresses.findIndex(
            addr => addr._id?.toString() === addressId
        );

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
    } catch (error) {
        logger.error('Set default address error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to set default address'
        });
    }
};

module.exports = { getProfile, updateProfile, getAddresses, addAddress, updateAddress, deleteAddress, setDefaultAddress };

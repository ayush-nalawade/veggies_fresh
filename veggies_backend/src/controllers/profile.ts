import { Response } from 'express';
import { z } from 'zod';
import { User } from '../models/User';
import { AuthRequest } from '../middlewares/auth';
import { logger } from '../utils/logger';

// Validation schemas
const updateProfileSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').optional(),
  email: z.string().email('Invalid email format').optional(),
  phone: z.string().min(10, 'Phone number must be at least 10 digits').optional(),
});

const addressSchema = z.object({
  type: z.enum(['home', 'work', 'other']),
  name: z.string().min(2, 'Address name is required'),
  line1: z.string().min(5, 'Address line 1 is required'),
  line2: z.string().optional(),
  city: z.string().min(2, 'City is required'),
  state: z.string().min(2, 'State is required'),
  pincode: z.string().min(6, 'Pincode must be at least 6 digits'),
  country: z.string().min(2, 'Country is required').default('India'),
  isDefault: z.boolean().optional().default(false),
});

// Get user profile
export const getProfile = async (req: AuthRequest, res: Response) => {
  try {
    const user = await User.findById(req.user!._id).select('-password');
    
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
export const updateProfile = async (req: AuthRequest, res: Response) => {
  try {
    const updateData = updateProfileSchema.parse(req.body);
    
    // Check if email is being updated and if it's already taken
    if (updateData.email) {
      const existingUser = await User.findOne({ 
        email: updateData.email, 
        _id: { $ne: req.user!._id } 
      });
      
      if (existingUser) {
        return res.status(400).json({
          success: false,
          error: 'Email already exists'
        });
      }
    }

    const user = await User.findByIdAndUpdate(
      req.user!._id,
      { $set: updateData },
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
export const getAddresses = async (req: AuthRequest, res: Response) => {
  try {
    const user = await User.findById(req.user!._id).select('addresses');
    
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
export const addAddress = async (req: AuthRequest, res: Response) => {
  try {
    const addressData = addressSchema.parse(req.body);
    
    const user = await User.findById(req.user!._id);
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
export const updateAddress = async (req: AuthRequest, res: Response) => {
  try {
    const { addressId } = req.params;
    const addressData = addressSchema.parse(req.body);
    
    const user = await User.findById(req.user!._id);
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

    // If this is set as default, unset other default addresses
    if (addressData.isDefault) {
      user.addresses = user.addresses.map((addr, index) => ({
        ...addr,
        isDefault: index === addressIndex ? true : false
      }));
    } else {
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
export const deleteAddress = async (req: AuthRequest, res: Response) => {
  try {
    const { addressId } = req.params;
    
    const user = await User.findById(req.user!._id);
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
export const setDefaultAddress = async (req: AuthRequest, res: Response) => {
  try {
    const { addressId } = req.params;
    
    const user = await User.findById(req.user!._id);
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

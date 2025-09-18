import { Response } from 'express';
import { z } from 'zod';
import { Cart } from '../models/Cart';
import { Product } from '../models/Product';
import { AuthRequest } from '../middlewares/auth';
import { calculatePrice, validateStock } from '../utils/pricing';
import { logger } from '../utils/logger';

// Validation schemas
const addItemSchema = z.object({
  productId: z.string().min(1, 'Product ID is required'),
  unit: z.enum(['kg', 'g', 'pcs', 'bundle']),
  qty: z.number().min(0.01, 'Quantity must be greater than 0')
});

const updateItemSchema = z.object({
  unit: z.enum(['kg', 'g', 'pcs', 'bundle']).optional(),
  qty: z.number().min(0.01, 'Quantity must be greater than 0').optional()
});

export const getCart = async (req: AuthRequest, res: Response) => {
  try {
    const cart = await Cart.findOne({ userId: req.user!._id })
      .populate('items.productId', 'name images unitPrices');

    if (!cart) {
      return res.json({
        success: true,
        data: { items: [], subtotal: 0 }
      });
    }

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    logger.error('Get cart error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch cart'
    });
  }
};

export const addToCart = async (req: AuthRequest, res: Response) => {
  try {
    const { productId, unit, qty } = addItemSchema.parse(req.body);

    // Get product details
    const product = await Product.findById(productId);
    if (!product || !product.isActive) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    // Validate stock
    if (!validateStock(qty, unit, product.unitPrices)) {
      return res.status(400).json({
        success: false,
        error: 'Insufficient stock'
      });
    }

    // Calculate price
    const unitPrice = product.unitPrices.find(up => up.unit === unit);
    if (!unitPrice) {
      return res.status(400).json({
        success: false,
        error: 'Invalid unit for this product'
      });
    }

    const price = calculatePrice(qty, unit, product.unitPrices);

    // Find or create cart
    let cart = await Cart.findOne({ userId: req.user!._id });
    
    if (!cart) {
      cart = await Cart.create({
        userId: req.user!._id,
        items: [],
        subtotal: 0
      });
    }

    // Check if item already exists
    const existingItemIndex = cart.items.findIndex(
      item => item.productId.toString() === productId && item.unit === unit
    );

    if (existingItemIndex >= 0) {
      // Update existing item
      const existingItem = cart.items[existingItemIndex];
      const newQty = existingItem.qty + qty;
      
      // Validate stock for new quantity
      if (!validateStock(newQty, unit, product.unitPrices)) {
        return res.status(400).json({
          success: false,
          error: 'Insufficient stock for requested quantity'
        });
      }

      const newPrice = calculatePrice(newQty, unit, product.unitPrices);
      
      cart.items[existingItemIndex] = {
        ...existingItem,
        qty: newQty,
        price: newPrice
      };
    } else {
      // Add new item
      cart.items.push({
        productId: product._id,
        name: product.name,
        image: product.images[0] || '',
        unit,
        qty,
        unitPrice: unitPrice.price,
        price
      });
    }

    await cart.save();

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    logger.error('Add to cart error:', error);
    res.status(400).json({
      success: false,
      error: error instanceof z.ZodError ? 'Validation error' : 'Failed to add item to cart'
    });
  }
};

export const updateCartItem = async (req: AuthRequest, res: Response) => {
  try {
    const { productId } = req.params;
    const updateData = updateItemSchema.parse(req.body);

    const cart = await Cart.findOne({ userId: req.user!._id });
    if (!cart) {
      return res.status(404).json({
        success: false,
        error: 'Cart not found'
      });
    }

    const itemIndex = cart.items.findIndex(
      item => item.productId.toString() === productId
    );

    if (itemIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'Item not found in cart'
      });
    }

    const item = cart.items[itemIndex];
    const product = await Product.findById(productId);
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    // Update item
    if (updateData.unit) {
      item.unit = updateData.unit;
    }
    if (updateData.qty !== undefined) {
      item.qty = updateData.qty;
    }

    // Validate stock and recalculate price
    if (!validateStock(item.qty, item.unit, product.unitPrices)) {
      return res.status(400).json({
        success: false,
        error: 'Insufficient stock'
      });
    }

    item.price = calculatePrice(item.qty, item.unit, product.unitPrices);
    cart.items[itemIndex] = item;

    await cart.save();

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    logger.error('Update cart item error:', error);
    res.status(400).json({
      success: false,
      error: error instanceof z.ZodError ? 'Validation error' : 'Failed to update cart item'
    });
  }
};

export const removeFromCart = async (req: AuthRequest, res: Response) => {
  try {
    const { productId } = req.params;

    const cart = await Cart.findOne({ userId: req.user!._id });
    if (!cart) {
      return res.status(404).json({
        success: false,
        error: 'Cart not found'
      });
    }

    cart.items = cart.items.filter(
      item => item.productId.toString() !== productId
    );

    await cart.save();

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    logger.error('Remove from cart error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to remove item from cart'
    });
  }
};

export const clearCart = async (req: AuthRequest, res: Response) => {
  try {
    const cart = await Cart.findOne({ userId: req.user!._id });
    if (!cart) {
      return res.status(404).json({
        success: false,
        error: 'Cart not found'
      });
    }

    cart.items = [];
    cart.subtotal = 0;
    await cart.save();

    res.json({
      success: true,
      data: cart
    });
  } catch (error) {
    logger.error('Clear cart error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to clear cart'
    });
  }
};

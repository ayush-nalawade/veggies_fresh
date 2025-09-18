"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.clearCart = exports.removeFromCart = exports.updateCartItem = exports.addToCart = exports.getCart = void 0;
const zod_1 = require("zod");
const Cart_1 = require("../models/Cart");
const Product_1 = require("../models/Product");
const pricing_1 = require("../utils/pricing");
const logger_1 = require("../utils/logger");
// Validation schemas
const addItemSchema = zod_1.z.object({
    productId: zod_1.z.string().min(1, 'Product ID is required'),
    unit: zod_1.z.enum(['kg', 'g', 'pcs', 'bundle']),
    qty: zod_1.z.number().min(0.01, 'Quantity must be greater than 0')
});
const updateItemSchema = zod_1.z.object({
    unit: zod_1.z.enum(['kg', 'g', 'pcs', 'bundle']).optional(),
    qty: zod_1.z.number().min(0.01, 'Quantity must be greater than 0').optional()
});
const getCart = async (req, res) => {
    try {
        const cart = await Cart_1.Cart.findOne({ userId: req.user._id })
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
    }
    catch (error) {
        logger_1.logger.error('Get cart error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch cart'
        });
    }
};
exports.getCart = getCart;
const addToCart = async (req, res) => {
    try {
        const { productId, unit, qty } = addItemSchema.parse(req.body);
        // Get product details
        const product = await Product_1.Product.findById(productId);
        if (!product || !product.isActive) {
            return res.status(404).json({
                success: false,
                error: 'Product not found'
            });
        }
        // Validate stock
        if (!(0, pricing_1.validateStock)(qty, unit, product.unitPrices)) {
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
        const price = (0, pricing_1.calculatePrice)(qty, unit, product.unitPrices);
        // Find or create cart
        let cart = await Cart_1.Cart.findOne({ userId: req.user._id });
        if (!cart) {
            cart = await Cart_1.Cart.create({
                userId: req.user._id,
                items: [],
                subtotal: 0
            });
        }
        // Check if item already exists
        const existingItemIndex = cart.items.findIndex(item => item.productId.toString() === productId && item.unit === unit);
        if (existingItemIndex >= 0) {
            // Update existing item
            const existingItem = cart.items[existingItemIndex];
            const newQty = existingItem.qty + qty;
            // Validate stock for new quantity
            if (!(0, pricing_1.validateStock)(newQty, unit, product.unitPrices)) {
                return res.status(400).json({
                    success: false,
                    error: 'Insufficient stock for requested quantity'
                });
            }
            const newPrice = (0, pricing_1.calculatePrice)(newQty, unit, product.unitPrices);
            cart.items[existingItemIndex] = {
                ...existingItem,
                qty: newQty,
                price: newPrice
            };
        }
        else {
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
    }
    catch (error) {
        logger_1.logger.error('Add to cart error:', error);
        res.status(400).json({
            success: false,
            error: error instanceof zod_1.z.ZodError ? 'Validation error' : 'Failed to add item to cart'
        });
    }
};
exports.addToCart = addToCart;
const updateCartItem = async (req, res) => {
    try {
        const { productId } = req.params;
        const updateData = updateItemSchema.parse(req.body);
        const cart = await Cart_1.Cart.findOne({ userId: req.user._id });
        if (!cart) {
            return res.status(404).json({
                success: false,
                error: 'Cart not found'
            });
        }
        const itemIndex = cart.items.findIndex(item => item.productId.toString() === productId);
        if (itemIndex === -1) {
            return res.status(404).json({
                success: false,
                error: 'Item not found in cart'
            });
        }
        const item = cart.items[itemIndex];
        const product = await Product_1.Product.findById(productId);
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
        if (!(0, pricing_1.validateStock)(item.qty, item.unit, product.unitPrices)) {
            return res.status(400).json({
                success: false,
                error: 'Insufficient stock'
            });
        }
        item.price = (0, pricing_1.calculatePrice)(item.qty, item.unit, product.unitPrices);
        cart.items[itemIndex] = item;
        await cart.save();
        res.json({
            success: true,
            data: cart
        });
    }
    catch (error) {
        logger_1.logger.error('Update cart item error:', error);
        res.status(400).json({
            success: false,
            error: error instanceof zod_1.z.ZodError ? 'Validation error' : 'Failed to update cart item'
        });
    }
};
exports.updateCartItem = updateCartItem;
const removeFromCart = async (req, res) => {
    try {
        const { productId } = req.params;
        const cart = await Cart_1.Cart.findOne({ userId: req.user._id });
        if (!cart) {
            return res.status(404).json({
                success: false,
                error: 'Cart not found'
            });
        }
        cart.items = cart.items.filter(item => item.productId.toString() !== productId);
        await cart.save();
        res.json({
            success: true,
            data: cart
        });
    }
    catch (error) {
        logger_1.logger.error('Remove from cart error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to remove item from cart'
        });
    }
};
exports.removeFromCart = removeFromCart;
const clearCart = async (req, res) => {
    try {
        const cart = await Cart_1.Cart.findOne({ userId: req.user._id });
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
    }
    catch (error) {
        logger_1.logger.error('Clear cart error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to clear cart'
        });
    }
};
exports.clearCart = clearCart;
//# sourceMappingURL=cart.js.map
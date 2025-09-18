"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getProductById = exports.getProducts = void 0;
const Product_1 = require("../models/Product");
const logger_1 = require("../utils/logger");
const getProducts = async (req, res) => {
    try {
        const { category, q, limit = '20', page = '1' } = req.query;
        const query = { isActive: true };
        if (category) {
            query.categoryId = category;
        }
        if (q) {
            query.$text = { $search: q };
        }
        const limitNum = parseInt(limit);
        const pageNum = parseInt(page);
        const skip = (pageNum - 1) * limitNum;
        const products = await Product_1.Product.find(query)
            .populate('categoryId', 'name')
            .select('name slug images unitPrices rating')
            .sort({ createdAt: -1 })
            .limit(limitNum)
            .skip(skip);
        const total = await Product_1.Product.countDocuments(query);
        res.json({
            success: true,
            data: products,
            meta: {
                total,
                page: pageNum,
                limit: limitNum,
                pages: Math.ceil(total / limitNum)
            }
        });
    }
    catch (error) {
        logger_1.logger.error('Get products error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch products'
        });
    }
};
exports.getProducts = getProducts;
const getProductById = async (req, res) => {
    try {
        const { id } = req.params;
        const product = await Product_1.Product.findOne({ _id: id, isActive: true })
            .populate('categoryId', 'name');
        if (!product) {
            return res.status(404).json({
                success: false,
                error: 'Product not found'
            });
        }
        res.json({
            success: true,
            data: product
        });
    }
    catch (error) {
        logger_1.logger.error('Get product by ID error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch product'
        });
    }
};
exports.getProductById = getProductById;
//# sourceMappingURL=products.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getOrderById = exports.getOrders = void 0;
const Order_1 = require("../models/Order");
const logger_1 = require("../utils/logger");
const getOrders = async (req, res) => {
    try {
        const { page = '1', limit = '10' } = req.query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const skip = (pageNum - 1) * limitNum;
        const orders = await Order_1.Order.find({ userId: req.user._id })
            .sort({ createdAt: -1 })
            .limit(limitNum)
            .skip(skip);
        const total = await Order_1.Order.countDocuments({ userId: req.user._id });
        res.json({
            success: true,
            data: orders,
            meta: {
                total,
                page: pageNum,
                limit: limitNum,
                pages: Math.ceil(total / limitNum)
            }
        });
    }
    catch (error) {
        logger_1.logger.error('Get orders error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch orders'
        });
    }
};
exports.getOrders = getOrders;
const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;
        const order = await Order_1.Order.findOne({
            _id: id,
            userId: req.user._id
        });
        if (!order) {
            return res.status(404).json({
                success: false,
                error: 'Order not found'
            });
        }
        res.json({
            success: true,
            data: order
        });
    }
    catch (error) {
        logger_1.logger.error('Get order by ID error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch order'
        });
    }
};
exports.getOrderById = getOrderById;
//# sourceMappingURL=orders.js.map
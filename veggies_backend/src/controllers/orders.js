const { Order } = require('../models/Order');
const { logger } = require('../utils/logger');

const getOrders = async (req, res) => {
    try {
        const { page = '1', limit = '10' } = req.query;

        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const skip = (pageNum - 1) * limitNum;

        logger.info(`Fetching orders for user: ${req.user._id}`);

        const orders = await Order.find({ userId: req.user._id })
            .sort({ createdAt: -1 })
            .limit(limitNum)
            .skip(skip);

        const total = await Order.countDocuments({ userId: req.user._id });

        logger.info(`Found ${orders.length} orders for user ${req.user._id}`);

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
    } catch (error) {
        logger.error('Get orders error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch orders'
        });
    }
};

const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;

        const order = await Order.findOne({
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
    } catch (error) {
        logger.error('Get order by ID error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch order'
        });
    }
};

module.exports = { getOrders, getOrderById };

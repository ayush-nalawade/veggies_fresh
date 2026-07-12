const { Category } = require('../models/Category');
const { logger } = require('../utils/logger');

const getCategories = async (req, res) => {
    try {
        const categories = await Category.find({ isActive: true })
            .sort({ sort: 1, name: 1 })
            .select('name iconUrl');

        res.json({
            success: true,
            data: categories
        });
    } catch (error) {
        logger.error('Get categories error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch categories'
        });
    }
};

module.exports = { getCategories };

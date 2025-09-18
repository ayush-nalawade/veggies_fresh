"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCategories = void 0;
const Category_1 = require("../models/Category");
const logger_1 = require("../utils/logger");
const getCategories = async (req, res) => {
    try {
        const categories = await Category_1.Category.find({ isActive: true })
            .sort({ sort: 1, name: 1 })
            .select('name iconUrl');
        res.json({
            success: true,
            data: categories
        });
    }
    catch (error) {
        logger_1.logger.error('Get categories error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch categories'
        });
    }
};
exports.getCategories = getCategories;
//# sourceMappingURL=categories.js.map
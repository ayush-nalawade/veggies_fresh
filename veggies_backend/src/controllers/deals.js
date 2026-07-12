const { Product } = require('../models/Product');
const { logger } = require('../utils/logger');

/**
 * GET /deals/today
 * Returns products flagged as today's deals with discount % computed server-side.
 * dealEndsAt defaults to midnight of the current day (IST) if not set on the product.
 */
const getTodaysDeals = async (req, res) => {
    try {
        // Compute midnight of today (end of day) as the default deal expiry
        const now = new Date();
        const midnight = new Date(now);
        midnight.setHours(23, 59, 59, 999);

        // Fetch active deal products
        const products = await Product.find({
            isActive: true,
            isDeal: true
        })
            .populate('categoryId', 'name')
            .select('name slug images unitPrices rating description isDeal dealEndsAt categoryId')
            .limit(10)
            .sort({ updatedAt: -1 });

        // Compute discount percent for each product (use the best unit price deal)
        const deals = products
            .map(product => {
                const productObj = product.toObject();

                // Find the unit price with the biggest discount
                let bestDiscount = 0;
                let dealPrice = null;
                let originalPrice = null;

                for (const up of productObj.unitPrices) {
                    if (up.compareAt && up.compareAt > up.price) {
                        const discount = Math.round(
                            ((up.compareAt - up.price) / up.compareAt) * 100
                        );
                        if (discount > bestDiscount) {
                            bestDiscount = discount;
                            dealPrice = up.price;
                            originalPrice = up.compareAt;
                        }
                    }
                }

                // Skip products with no actual discount
                if (bestDiscount === 0) return null;

                return {
                    ...productObj,
                    discountPercent: bestDiscount,
                    dealPrice,
                    originalPrice,
                    dealEndsAt: productObj.dealEndsAt || midnight
                };
            })
            .filter(Boolean); // remove nulls

        res.json({
            success: true,
            data: deals,
            dealEndsAt: midnight,
            meta: {
                total: deals.length
            }
        });
    } catch (error) {
        logger.error('Get today\'s deals error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch today\'s deals'
        });
    }
};

module.exports = { getTodaysDeals };

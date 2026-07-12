const computeLine = (qty, unitPrice, baseQty = 1) => {
    return +(qty / baseQty * unitPrice).toFixed(2);
};

// Tiered pricing for weight-based products
// Calculates optimal price using different weight tiers (250gm, 500gm, 1kg)
const calculateTieredPrice = (qtyInGrams, unitPrices) => {
    // Filter weight-based unit prices and sort by baseQty descending
    const weightPrices = unitPrices
        .filter(up => up.unit === 'g' || up.unit === 'kg')
        .map(up => ({
            baseQty: up.unit === 'kg' ? up.baseQty * 1000 : up.baseQty,
            price: up.price
        }))
        .sort((a, b) => b.baseQty - a.baseQty);

    if (weightPrices.length === 0) {
        throw new Error('No weight-based pricing found');
    }

    let remainingQty = qtyInGrams;
    let totalPrice = 0;

    // Calculate price using largest denominations first
    for (const tier of weightPrices) {
        const count = Math.floor(remainingQty / tier.baseQty);
        if (count > 0) {
            totalPrice += count * tier.price;
            remainingQty -= count * tier.baseQty;
        }
    }

    return +totalPrice.toFixed(2);
};

const calculatePrice = (qty, unit, unitPrices) => {
    const unitPrice = unitPrices.find(up => up.unit === unit);
    if (!unitPrice) {
        throw new Error(`Unit ${unit} not found for this product`);
    }

    // Check if this is a weight-based product with multiple tiers
    const weightTiers = unitPrices.filter(up => up.unit === 'g' || up.unit === 'kg');
    if (weightTiers.length > 1 && (unit === 'g' || unit === 'kg')) {
        // Convert quantity to grams
        const qtyInGrams = unit === 'kg' ? qty * 1000 : qty;
        return calculateTieredPrice(qtyInGrams, unitPrices);
    }

    // For non-tiered products, use simple calculation
    return computeLine(qty, unitPrice.price, unitPrice.baseQty);
};

const validateStock = (qty, unit, unitPrices) => {
    const unitPrice = unitPrices.find(up => up.unit === unit);
    if (!unitPrice) {
        return false;
    }

    // Convert qty to base units for stock check
    const baseQty = (qty / unitPrice.baseQty);
    return baseQty <= unitPrice.stock;
};

module.exports = { computeLine, calculateTieredPrice, calculatePrice, validateStock };

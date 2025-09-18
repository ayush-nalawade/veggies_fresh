"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateStock = exports.calculatePrice = exports.computeLine = void 0;
const computeLine = (qty, unitPrice, baseQty = 1) => {
    return +(qty / baseQty * unitPrice).toFixed(2);
};
exports.computeLine = computeLine;
const calculatePrice = (qty, unit, unitPrices) => {
    const unitPrice = unitPrices.find(up => up.unit === unit);
    if (!unitPrice) {
        throw new Error(`Unit ${unit} not found for this product`);
    }
    return (0, exports.computeLine)(qty, unitPrice.price, unitPrice.baseQty);
};
exports.calculatePrice = calculatePrice;
const validateStock = (qty, unit, unitPrices) => {
    const unitPrice = unitPrices.find(up => up.unit === unit);
    if (!unitPrice) {
        return false;
    }
    // Convert qty to base units for stock check
    const baseQty = (qty / unitPrice.baseQty);
    return baseQty <= unitPrice.stock;
};
exports.validateStock = validateStock;
//# sourceMappingURL=pricing.js.map
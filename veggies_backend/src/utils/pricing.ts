export const computeLine = (qty: number, unitPrice: number, baseQty = 1): number => {
  return +(qty / baseQty * unitPrice).toFixed(2);
};

export const calculatePrice = (qty: number, unit: string, unitPrices: any[]): number => {
  const unitPrice = unitPrices.find(up => up.unit === unit);
  if (!unitPrice) {
    throw new Error(`Unit ${unit} not found for this product`);
  }
  
  return computeLine(qty, unitPrice.price, unitPrice.baseQty);
};

export const validateStock = (qty: number, unit: string, unitPrices: any[]): boolean => {
  const unitPrice = unitPrices.find(up => up.unit === unit);
  if (!unitPrice) {
    return false;
  }
  
  // Convert qty to base units for stock check
  const baseQty = (qty / unitPrice.baseQty);
  return baseQty <= unitPrice.stock;
};

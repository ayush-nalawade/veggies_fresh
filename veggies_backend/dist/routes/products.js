"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const products_1 = require("../controllers/products");
const router = express_1.default.Router();
router.get('/', products_1.getProducts);
router.get('/:id', products_1.getProductById);
exports.default = router;
//# sourceMappingURL=products.js.map
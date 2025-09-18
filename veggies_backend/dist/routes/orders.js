"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const auth_1 = require("../middlewares/auth");
const orders_1 = require("../controllers/orders");
const router = express_1.default.Router();
// All order routes require authentication
router.use(auth_1.authenticateToken);
router.get('/', (req, res) => (0, orders_1.getOrders)(req, res));
router.get('/:id', (req, res) => (0, orders_1.getOrderById)(req, res));
exports.default = router;
//# sourceMappingURL=orders.js.map
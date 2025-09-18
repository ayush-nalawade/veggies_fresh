"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const auth_1 = require("../middlewares/auth");
const cart_1 = require("../controllers/cart");
const router = express_1.default.Router();
// All cart routes require authentication
router.use(auth_1.authenticateToken);
router.get('/', (req, res) => (0, cart_1.getCart)(req, res));
router.post('/items', (req, res) => (0, cart_1.addToCart)(req, res));
router.patch('/items/:productId', (req, res) => (0, cart_1.updateCartItem)(req, res));
router.delete('/items/:productId', (req, res) => (0, cart_1.removeFromCart)(req, res));
router.delete('/', (req, res) => (0, cart_1.clearCart)(req, res));
exports.default = router;
//# sourceMappingURL=cart.js.map
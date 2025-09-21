"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const auth_1 = require("../middlewares/auth");
const checkout_1 = require("../controllers/checkout");
const router = express_1.default.Router();
// All checkout routes require authentication
router.use(auth_1.authenticateToken);
router.get('/time-slots', (req, res) => (0, checkout_1.getTimeSlots)(req, res));
router.post('/address', (req, res) => (0, checkout_1.saveAddress)(req, res));
router.post('/create-order', (req, res) => (0, checkout_1.createOrder)(req, res));
router.post('/verify-payment', (req, res) => (0, checkout_1.verifyPayment)(req, res));
exports.default = router;
//# sourceMappingURL=checkout.js.map
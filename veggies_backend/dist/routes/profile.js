"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const auth_1 = require("../middlewares/auth");
const profile_1 = require("../controllers/profile");
const router = express_1.default.Router();
// All profile routes require authentication
router.use(auth_1.authenticateToken);
// Profile management
router.get('/', (req, res) => (0, profile_1.getProfile)(req, res));
router.put('/', (req, res) => (0, profile_1.updateProfile)(req, res));
// Address management
router.get('/addresses', (req, res) => (0, profile_1.getAddresses)(req, res));
router.post('/addresses', (req, res) => (0, profile_1.addAddress)(req, res));
router.put('/addresses/:addressId', (req, res) => (0, profile_1.updateAddress)(req, res));
router.delete('/addresses/:addressId', (req, res) => (0, profile_1.deleteAddress)(req, res));
router.patch('/addresses/:addressId/default', (req, res) => (0, profile_1.setDefaultAddress)(req, res));
exports.default = router;
//# sourceMappingURL=profile.js.map
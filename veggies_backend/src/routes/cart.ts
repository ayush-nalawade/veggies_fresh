import express from 'express';
import { authenticateToken } from '../middlewares/auth';
import { getCart, addToCart, updateCartItem, removeFromCart, clearCart } from '../controllers/cart';

const router = express.Router();

// All cart routes require authentication
router.use(authenticateToken);

router.get('/', (req, res) => getCart(req as any, res));
router.post('/items', (req, res) => addToCart(req as any, res));
router.patch('/items/:productId', (req, res) => updateCartItem(req as any, res));
router.delete('/items/:productId', (req, res) => removeFromCart(req as any, res));
router.delete('/', (req, res) => clearCart(req as any, res));

export default router;

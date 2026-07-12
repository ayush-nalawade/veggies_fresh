const express = require('express');
const { authenticateToken } = require('../middlewares/auth');
const { getCart, addToCart, updateCartItem, removeFromCart, clearCart } = require('../controllers/cart');

const router = express.Router();

// All cart routes require authentication
router.use(authenticateToken);

router.get('/', getCart);
router.post('/items', addToCart);
router.patch('/items/:productId', updateCartItem);
router.delete('/items/:productId', removeFromCart);
router.delete('/', clearCart);

module.exports = router;

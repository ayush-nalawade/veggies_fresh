const express = require('express');
const { authenticateToken } = require('../middlewares/auth');
const { getOrders, getOrderById } = require('../controllers/orders');

const router = express.Router();

// All order routes require authentication
router.use(authenticateToken);

router.get('/', getOrders);
router.get('/:id', getOrderById);

module.exports = router;

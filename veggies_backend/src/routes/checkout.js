const express = require('express');
const { authenticateToken } = require('../middlewares/auth');
const { saveAddress, createOrder, verifyPayment, getTimeSlots } = require('../controllers/checkout');

const router = express.Router();

// All checkout routes require authentication
router.use(authenticateToken);

router.get('/time-slots', getTimeSlots);
router.post('/address', saveAddress);
router.post('/create-order', createOrder);
router.post('/verify-payment', verifyPayment);

module.exports = router;

import express from 'express';
import { authenticateToken } from '../middlewares/auth';
import { saveAddress, createOrder, verifyPayment } from '../controllers/checkout';

const router = express.Router();

// All checkout routes require authentication
router.use(authenticateToken);

router.post('/address', (req, res) => saveAddress(req as any, res));
router.post('/create-order', (req, res) => createOrder(req as any, res));
router.post('/verify-payment', (req, res) => verifyPayment(req as any, res));

export default router;

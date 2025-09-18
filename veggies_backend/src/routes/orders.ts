import express from 'express';
import { authenticateToken } from '../middlewares/auth';
import { getOrders, getOrderById } from '../controllers/orders';

const router = express.Router();

// All order routes require authentication
router.use(authenticateToken);

router.get('/', (req, res) => getOrders(req as any, res));
router.get('/:id', (req, res) => getOrderById(req as any, res));

export default router;

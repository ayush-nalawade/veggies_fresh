import express from 'express';
import { authenticateToken } from '../middlewares/auth';
import { 
  getProfile, 
  updateProfile, 
  getAddresses, 
  addAddress, 
  updateAddress, 
  deleteAddress, 
  setDefaultAddress 
} from '../controllers/profile';

const router = express.Router();

// All profile routes require authentication
router.use(authenticateToken);

// Profile management
router.get('/', (req, res) => getProfile(req as any, res));
router.put('/', (req, res) => updateProfile(req as any, res));

// Address management
router.get('/addresses', (req, res) => getAddresses(req as any, res));
router.post('/addresses', (req, res) => addAddress(req as any, res));
router.put('/addresses/:addressId', (req, res) => updateAddress(req as any, res));
router.delete('/addresses/:addressId', (req, res) => deleteAddress(req as any, res));
router.patch('/addresses/:addressId/default', (req, res) => setDefaultAddress(req as any, res));

export default router;

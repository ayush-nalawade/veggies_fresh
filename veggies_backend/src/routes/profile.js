const express = require('express');
const { authenticateToken } = require('../middlewares/auth');
const {
    getProfile,
    updateProfile,
    getAddresses,
    addAddress,
    updateAddress,
    deleteAddress,
    setDefaultAddress
} = require('../controllers/profile');

const router = express.Router();

// All profile routes require authentication
router.use(authenticateToken);

// Profile management
router.get('/', getProfile);
router.put('/', updateProfile);

// Address management
router.get('/addresses', getAddresses);
router.post('/addresses', addAddress);
router.put('/addresses/:addressId', updateAddress);
router.delete('/addresses/:addressId', deleteAddress);
router.patch('/addresses/:addressId/default', setDefaultAddress);

module.exports = router;

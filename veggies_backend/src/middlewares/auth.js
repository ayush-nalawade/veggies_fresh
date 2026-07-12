const jwt = require('jsonwebtoken');
const { User } = require('../models/User');

const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({ success: false, error: 'Access token required' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.userId).select('-passwordHash');

        if (!user) {
            return res.status(401).json({ success: false, error: 'User not found' });
        }

        req.user = user;
        next();
    } catch (error) {
        return res.status(403).json({ success: false, error: 'Invalid token' });
    }
};

const requireAdmin = (req, res, next) => {
    if (req.user?.role !== 'admin') {
        return res.status(403).json({ success: false, error: 'Admin access required' });
    }
    next();
};

module.exports = { authenticateToken, requireAdmin };

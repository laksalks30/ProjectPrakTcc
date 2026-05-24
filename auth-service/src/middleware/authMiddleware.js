// ============ FILE: auth-service/src/middleware/authMiddleware.js ============
const jwtService = require('../services/jwtService');
const { User, TokenBlacklist } = require('../models/User');

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.',
        data: null,
        meta: null
      });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. Invalid token format.',
        data: null,
        meta: null
      });
    }

    // Check if token is blacklisted
    const blacklisted = await TokenBlacklist.findOne({ where: { token } });
    if (blacklisted) {
      return res.status(401).json({
        success: false,
        message: 'Token has been revoked. Please login again.',
        data: null,
        meta: null
      });
    }

    const decoded = jwtService.verifyToken(token);

    const user = await User.findByPk(decoded.id, {
      attributes: { exclude: ['password_hash'] }
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'User associated with this token no longer exists.',
        data: null,
        meta: null
      });
    }

    req.user = user;
    req.token = token;
    next();
  } catch (error) {
    if (error.message === 'Token has expired') {
      return res.status(401).json({
        success: false,
        message: 'Token has expired. Please login again.',
        data: null,
        meta: null
      });
    }
    if (error.message === 'Invalid token') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token. Please login again.',
        data: null,
        meta: null
      });
    }
    console.error('Auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication error.',
      data: null,
      meta: null
    });
  }
};

const adminOnly = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    return next();
  }
  return res.status(403).json({
    success: false,
    message: 'Access denied. Admin role required.',
    data: null,
    meta: null
  });
};

module.exports = { authMiddleware, adminOnly };

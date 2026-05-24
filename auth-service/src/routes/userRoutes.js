// ============ FILE: auth-service/src/routes/userRoutes.js ============
const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authMiddleware, adminOnly } = require('../middleware/authMiddleware');

// All routes require authentication + admin role
router.get('/', authMiddleware, adminOnly, userController.getAllUsers);
router.delete('/:id', authMiddleware, adminOnly, userController.deleteUser);

module.exports = router;

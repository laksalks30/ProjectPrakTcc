// ============ FILE: auth-service/src/controllers/authController.js ============
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const { User, TokenBlacklist } = require('../models/User');
const jwtService = require('../services/jwtService');
const gcsService = require('../services/gcsService');

const authController = {
  // Validation rules
  registerValidation: [
    body('name').trim().notEmpty().withMessage('Name is required')
      .isLength({ min: 2, max: 100 }).withMessage('Name must be 2-100 characters'),
    body('email').trim().isEmail().withMessage('Valid email is required')
      .normalizeEmail(),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('role').optional().isIn(['admin', 'user']).withMessage('Invalid role'),
    body('phone').optional().trim().isLength({ max: 20 }).withMessage('Phone max 20 characters')
  ],

  loginValidation: [
    body('email').trim().isEmail().withMessage('Valid email is required').normalizeEmail(),
    body('password').notEmpty().withMessage('Password is required')
  ],

  // POST /api/auth/register
  async register(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          data: null,
          meta: { errors: errors.array() }
        });
      }

      const { name, email, password, role, phone } = req.body;

      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'Email already registered',
          data: null,
          meta: null
        });
      }

      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(password, salt);

      const user = await User.create({
        name,
        email,
        password_hash,
        role: role || 'user',
        phone: phone || null
      });

      const token = jwtService.generateToken({
        id: user.id,
        email: user.email,
        role: user.role
      });

      const userData = {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        avatar_url: user.avatar_url,
        created_at: user.created_at
      };

      return res.status(201).json({
        success: true,
        message: 'Registration successful',
        data: { user: userData, token },
        meta: null
      });
    } catch (error) {
      console.error('Register error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to register user',
        data: null,
        meta: null
      });
    }
  },

  // POST /api/auth/login
  async login(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          data: null,
          meta: { errors: errors.array() }
        });
      }

      const { email, password } = req.body;

      const user = await User.findOne({ where: { email } });
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password',
          data: null,
          meta: null
        });
      }

      const isPasswordValid = await bcrypt.compare(password, user.password_hash);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password',
          data: null,
          meta: null
        });
      }

      const token = jwtService.generateToken({
        id: user.id,
        email: user.email,
        role: user.role
      });

      const userData = {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        avatar_url: user.avatar_url,
        created_at: user.created_at
      };

      return res.status(200).json({
        success: true,
        message: 'Login successful',
        data: { user: userData, token },
        meta: null
      });
    } catch (error) {
      console.error('Login error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to login',
        data: null,
        meta: null
      });
    }
  },

  // POST /api/auth/logout
  async logout(req, res) {
    try {
      const token = req.token;
      const expiresAt = jwtService.getExpirationDate(token);

      await TokenBlacklist.create({
        token,
        expires_at: expiresAt || new Date(Date.now() + 24 * 60 * 60 * 1000)
      });

      return res.status(200).json({
        success: true,
        message: 'Logout successful',
        data: null,
        meta: null
      });
    } catch (error) {
      console.error('Logout error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to logout',
        data: null,
        meta: null
      });
    }
  },

  // GET /api/auth/profile
  async getProfile(req, res) {
    try {
      const user = await User.findByPk(req.user.id, {
        attributes: { exclude: ['password_hash'] }
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
          data: null,
          meta: null
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Profile retrieved successfully',
        data: { user },
        meta: null
      });
    } catch (error) {
      console.error('Get profile error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to get profile',
        data: null,
        meta: null
      });
    }
  },

  // PUT /api/auth/profile
  async updateProfile(req, res) {
    try {
      const user = await User.findByPk(req.user.id);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
          data: null,
          meta: null
        });
      }

      const { name, phone, password } = req.body;

      if (name) user.name = name;
      if (phone !== undefined) user.phone = phone;

      if (password) {
        if (password.length < 6) {
          return res.status(400).json({
            success: false,
            message: 'Password must be at least 6 characters',
            data: null,
            meta: null
          });
        }
        const salt = await bcrypt.genSalt(10);
        user.password_hash = await bcrypt.hash(password, salt);
      }

      // Handle avatar upload
      if (req.file) {
        // Delete old avatar from GCS if exists
        if (user.avatar_url) {
          await gcsService.deleteFile(user.avatar_url);
        }
        const avatarUrl = await gcsService.uploadFile(req.file, 'avatars');
        user.avatar_url = avatarUrl;
      }

      await user.save();

      const userData = {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        phone: user.phone,
        avatar_url: user.avatar_url,
        created_at: user.created_at,
        updated_at: user.updated_at
      };

      return res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: { user: userData },
        meta: null
      });
    } catch (error) {
      console.error('Update profile error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to update profile',
        data: null,
        meta: null
      });
    }
  }
};

module.exports = authController;

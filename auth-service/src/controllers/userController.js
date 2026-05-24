// ============ FILE: auth-service/src/controllers/userController.js ============
const { User } = require('../models/User');

const userController = {
  // GET /api/auth/users — Admin only
  async getAllUsers(req, res) {
    try {
      const page = parseInt(req.query.page, 10) || 1;
      const limit = parseInt(req.query.limit, 10) || 10;
      const offset = (page - 1) * limit;
      const search = req.query.search || '';

      const whereClause = {};
      if (search) {
        const { Op } = require('sequelize');
        whereClause[Op.or] = [
          { name: { [Op.like]: `%${search}%` } },
          { email: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows: users } = await User.findAndCountAll({
        where: whereClause,
        attributes: { exclude: ['password_hash'] },
        order: [['created_at', 'DESC']],
        limit,
        offset
      });

      return res.status(200).json({
        success: true,
        message: 'Users retrieved successfully',
        data: { users },
        meta: {
          total: count,
          page,
          limit,
          totalPages: Math.ceil(count / limit)
        }
      });
    } catch (error) {
      console.error('Get all users error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to retrieve users',
        data: null,
        meta: null
      });
    }
  },

  // DELETE /api/auth/users/:id — Admin only
  async deleteUser(req, res) {
    try {
      const { id } = req.params;

      if (parseInt(id, 10) === req.user.id) {
        return res.status(400).json({
          success: false,
          message: 'Cannot delete your own account',
          data: null,
          meta: null
        });
      }

      const user = await User.findByPk(id);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
          data: null,
          meta: null
        });
      }

      await user.destroy();

      return res.status(200).json({
        success: true,
        message: 'User deleted successfully',
        data: { id: parseInt(id, 10) },
        meta: null
      });
    } catch (error) {
      console.error('Delete user error:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete user',
        data: null,
        meta: null
      });
    }
  }
};

module.exports = userController;

// ============ FILE: auth-service/src/middleware/uploadMiddleware.js ============
const multer = require('multer');

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG, PNG, GIF, and WebP are allowed.'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB max
  }
});

const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'File size too large. Maximum 5MB allowed.',
        data: null,
        meta: null
      });
    }
    return res.status(400).json({
      success: false,
      message: `Upload error: ${err.message}`,
      data: null,
      meta: null
    });
  }
  if (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
      data: null,
      meta: null
    });
  }
  next();
};

module.exports = { upload, handleMulterError };

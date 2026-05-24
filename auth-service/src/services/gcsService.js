// ============ FILE: auth-service/src/services/gcsService.js ============
const { Storage } = require('@google-cloud/storage');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const dotenv = require('dotenv');

dotenv.config();

let storage;
if (process.env.NODE_ENV === 'production') {
  storage = new Storage({ projectId: process.env.GCP_PROJECT_ID });
} else {
  storage = new Storage({
    projectId: process.env.GCP_PROJECT_ID || 'local-dev-project',
    keyFilename: process.env.GCS_KEYFILE || undefined
  });
}

const bucketName = process.env.GCS_BUCKET_NAME || 'obat-lansia-bucket';

const gcsService = {
  async uploadFile(file, folder = 'avatars') {
    try {
      const bucket = storage.bucket(bucketName);
      const ext = path.extname(file.originalname).toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

      if (!allowedExtensions.includes(ext)) {
        throw new Error('Invalid file type. Allowed: jpg, jpeg, png, gif, webp');
      }

      if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && process.env.NODE_ENV !== 'production') {
        console.log('Using local storage for local development (no GCP credentials found).');
        const fs = require('fs');
        const uploadDir = path.join(__dirname, '../../static/uploads');
        if (!fs.existsSync(uploadDir)) {
          fs.mkdirSync(uploadDir, { recursive: true });
        }
        const localFilename = `${uuidv4()}${ext}`;
        const localFilepath = path.join(uploadDir, localFilename);
        fs.writeFileSync(localFilepath, file.buffer);
        return `http://localhost:8001/static/uploads/${localFilename}`;
      }

      const filename = `${folder}/${uuidv4()}${ext}`;
      const blob = bucket.file(filename);

      const blobStream = blob.createWriteStream({
        resumable: false,
        metadata: {
          contentType: file.mimetype,
          cacheControl: 'public, max-age=31536000'
        }
      });

      return new Promise((resolve, reject) => {
        blobStream.on('error', (err) => {
          console.error('GCS upload error:', err);
          reject(new Error('Failed to upload file to cloud storage'));
        });

        blobStream.on('finish', async () => {
          try {
            await blob.makePublic();
          } catch (e) {
            console.warn('Could not make file public (may need bucket-level permissions):', e.message);
          }
          const publicUrl = `https://storage.googleapis.com/${bucketName}/${filename}`;
          resolve(publicUrl);
        });

        blobStream.end(file.buffer);
      });
    } catch (error) {
      console.error('Upload service error:', error);
      throw error;
    }
  },

  async deleteFile(fileUrl) {
    try {
      if (!fileUrl || !fileUrl.includes(bucketName)) {
        return false;
      }
      const filename = fileUrl.split(`${bucketName}/`)[1];
      if (!filename) return false;

      const bucket = storage.bucket(bucketName);
      const file = bucket.file(filename);

      const [exists] = await file.exists();
      if (exists) {
        await file.delete();
        console.log(`Deleted file from GCS: ${filename}`);
        return true;
      }
      return false;
    } catch (error) {
      console.error('GCS delete error:', error);
      return false;
    }
  }
};

module.exports = gcsService;

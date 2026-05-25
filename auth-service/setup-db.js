require('dotenv').config();
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function setupDatabase() {
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 3310,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      multipleStatements: true
    });

    console.log('? Connected to MySQL');

    const authDbSql = fs.readFileSync(path.join(__dirname, '../database/auth_db.sql'), 'utf8');
    await connection.query(authDbSql);
    console.log('? auth_db created/updated');

    const medicationDbSql = fs.readFileSync(path.join(__dirname, '../database/medication_db.sql'), 'utf8');
    await connection.query(medicationDbSql);
    console.log('? medication_db created/updated');

    const adminInsert = `INSERT IGNORE INTO auth_db.users (name, email, password_hash, role, created_at, updated_at) VALUES ('Admin', 'admin@obatlansia.com', '$2a$10$El5ic36iSF329K2KEiveaeYuWCE.qRLM0.MiOCF5priO2OWQtv/PK', 'admin', NOW(), NOW());`;
    await connection.query(adminInsert);
    console.log('? Admin user created');

    await connection.end();
    console.log('? Database setup complete!');
    console.log('\nCredentials:');
    console.log('Email: admin@obatlansia.com');
    console.log('Password: password123');
  } catch (error) {
    console.error('? Error:', error.message);
    process.exit(1);
  }
}

setupDatabase();

const mysql = require('mysql2');
require('dotenv').config();

const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'smart_farming',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Hubinta xidhiidhka
pool.getConnection((err, conn) => {
    if (err) console.error('❌ Cilad DB:', err.message);
    else {
        console.log('✅ Database-ku waa diyaar (Pool Ready)');
        conn.release();
    }
});

module.exports = pool.promise();

const db = require('../config/db');

const User = {
    // Inaad raadiso qofka email-kiisa si loogu isticmaalo Login-ka
    findByEmail: async (email) => {
        const [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        return rows[0];
    },

    // Inaad diiwaangeliso qof cusub (Register)
    create: async (name, email, password, role) => {
        const [result] = await db.execute(
            'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
            [name, email, password, role || 'Farmer']
        );
        return result;
    }
};

module.exports = User;
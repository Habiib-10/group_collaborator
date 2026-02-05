
// halkaan soo dhig koodhkaaga JavaScript ee faylka nodejs_backend/controllers/authController.js
const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

exports.register = async (req, res) => {
    const { name, email, password, role } = req.body;
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        await db.execute(
            'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
            [name, email, hashedPassword, role || 'Farmer']
        );
        res.status(201).json({ success: true, message: "User registered successfully" });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
};

exports.login = async (req, res) => {
    const { email, password } = req.body;
    try {
        const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (users.length === 0) return res.status(404).json({ message: "User not found" });

        const isMatch = await bcrypt.compare(password, users[0].password);
        if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

        const token = jwt.sign(
            { id: users[0].id, role: users[0].role },
            process.env.JWT_SECRET || 'secret123',
            { expiresIn: '24h' }
        );

        res.json({
            token,
            user: { id: users[0].id, name: users[0].name, role: users[0].role }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// halkaan soo dhig koodhkaaga JavaScript ee faylka nodejs_backend/controllers/cropController.js

const db = require('../config/db');

// 1. Get All Crops (Read)
exports.getCrops = async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT * FROM crops');
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 2. Add New Crop (Create)
exports.addCrop = async (req, res) => {
    const { name, status } = req.body;
    try {
        await db.execute('INSERT INTO crops (name, status) VALUES (?, ?)', [name, status]);
        res.status(201).json({ message: 'Crop added successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// 3. Delete Crop (Delete)
exports.deleteCrop = async (req, res) => {
    try {
        await db.execute('DELETE FROM crops WHERE id = ?', [req.params.id]);
        res.json({ message: 'Crop deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};
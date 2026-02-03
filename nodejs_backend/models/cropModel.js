
const db = require('../config/db');

const Crop = {
    // 1. Read: Soo qaado dhamaan dalagyada
    getAll: async () => {
        const [rows] = await db.execute('SELECT * FROM crops');
        return rows;
    },

    // 2. Create: Ku dar dalag cusub
    create: async (name, status, userId) => {
        const [result] = await db.execute(
            'INSERT INTO crops (name, status, user_id) VALUES (?, ?, ?)',
            [name, status, userId]
        );
        return result;
    },

    // 3. Update: Wax ka beddel xogta dalagga
    update: async (id, name, status) => {
        const [result] = await db.execute(
            'UPDATE crops SET name = ?, status = ? WHERE id = ?',
            [name, status, id]
        );
        return result;
    },

    // 4. Delete: Tirtir dalagga
    delete: async (id) => {
        const [result] = await db.execute('DELETE FROM crops WHERE id = ?', [id]);
        return result;
    }
};

module.exports = Crop;
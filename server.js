// halkaan soo dhig koodhkaaga Dart ee faylka server.js
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
const PORT = 5000;

// Middleware
app.use(express.json());
app.use(cors());

// Database Connection
const db = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'smart_farming',
  waitForConnections: true,
  connectionLimit: 10
}).promise();

// --- 1. AUTH ROUTES ---

// Login
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0 || !(await bcrypt.compare(password, rows[0].password))) {
      return res.status(401).json({ success: false, message: "Invalid Email or Password" });
    }
    const token = jwt.sign({ id: rows[0].id, role: rows[0].role }, 'secret123', { expiresIn: '24h' });
    res.json({ 
      success: true, 
      token: token, 
      user: { id: rows[0].id, name: rows[0].name, email: rows[0].email, role: rows[0].role } 
    });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// Register
app.post('/api/auth/register', async (req, res) => {
  const { name, email, password, role } = req.body;
  try {
    const hashed = await bcrypt.hash(password, 10);
    await db.execute(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [name, email, hashed, role || 'Farmer']
    );
    res.status(201).json({ success: true, message: "User created" });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// Update Password (NEW)
app.put('/api/auth/change-password', async (req, res) => {
  const { user_id, newPassword } = req.body;

  if (!user_id || !newPassword) {
    return res.status(400).json({ success: false, message: "Missing required fields" });
  }

  try {
    const hashed = await bcrypt.hash(newPassword, 10);
    
    const [result] = await db.execute(
      'UPDATE users SET password = ? WHERE id = ?',
      [hashed, user_id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.json({ success: true, message: "Password updated successfully" });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// --- 2. USER MANAGEMENT ---

// Get All Farmers (For Dropdown)
app.get('/api/users/farmers', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT id, name, email FROM users WHERE role = "Farmer"');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// Get All Registered Users (For Admin View)
app.get('/api/users', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT id, name, email, role FROM users ORDER BY id DESC');
    res.json(rows);
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// --- 3. FIELD ROUTES ---

app.get('/api/fields', async (req, res) => {
  try {
    const { user_id, role } = req.query;
    let rows;
    if (role === 'Admin' || !user_id || user_id === 'undefined' || user_id === '0') {
      [rows] = await db.execute('SELECT * FROM fields');
    } else {
      [rows] = await db.execute('SELECT * FROM fields WHERE user_id = ?', [user_id]);
    }
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/fields', async (req, res) => {
  const { name, location, size, status, price, user_id } = req.body;
  try {
    await db.execute(
      'INSERT INTO fields (name, location, size, status, price, user_id) VALUES (?, ?, ?, ?, ?, ?)',
      [name, location, size, status || 'Active', price || 0.0, user_id || null]
    );
    res.status(201).json({ success: true, message: "Field added and assigned successfully" });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

app.post('/api/fields/purchase', async (req, res) => {
  const { field_id, user_id } = req.body;
  try {
    const [field] = await db.execute('SELECT user_id FROM fields WHERE id = ?', [field_id]);
    if (field.length === 0) return res.status(404).json({ success: false, message: "Field not found" });
    if (field[0].user_id !== null) return res.status(400).json({ success: false, message: "Field already owned" });

    await db.execute('UPDATE fields SET user_id = ?, status = "Occupied" WHERE id = ?', [user_id, field_id]);
    res.json({ success: true, message: "Field purchased successfully" });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

app.put('/api/fields/:id', async (req, res) => {
  const { name, location, size, status, price, user_id } = req.body;
  const { id } = req.params;
  try {
    await db.execute(
      'UPDATE fields SET name = ?, location = ?, size = ?, status = ?, price = ?, user_id = ? WHERE id = ?',
      [name, location, size, status, price, user_id, id]
    );
    res.json({ success: true, message: "Field updated successfully" });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

app.delete('/api/fields/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await db.execute('DELETE FROM fields WHERE id = ?', [id]);
    res.json({ success: true, message: "Field deleted successfully" });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// --- 4. CROP ROUTES ---

app.get('/api/crops', async (req, res) => {
  const { field_id } = req.query;
  try {
    let rows;
    if (field_id) {
      [rows] = await db.execute('SELECT * FROM crops WHERE field_id = ?', [field_id]);
    } else {
      [rows] = await db.execute('SELECT * FROM crops');
    }
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/crops', async (req, res) => {
  const { name, status, user_id, image, field_id } = req.body;
  try {
    await db.execute(
      'INSERT INTO crops (name, status, user_id, image, field_id) VALUES (?, ?, ?, ?, ?)',
      [name, status || 'Healthy', user_id, image || '', field_id]
    );
    res.status(201).json({ success: true, message: "Crop saved" });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// --- SERVER START ---
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server is running on http://localhost:${PORT}`);
});
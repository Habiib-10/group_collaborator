const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController'); // Hubi in kani jiro

router.post('/register', authController.register);
router.post('/login', authController.login);

module.exports = router;
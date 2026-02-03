
const express = require('express');
const router = express.Router();
const cropController = require('../controllers/cropController');
const auth = require('../middleware/authMiddleware');

router.get('/', cropController.getCrops);
router.post('/', auth, cropController.addCrop); 
router.delete('/:id', auth, cropController.deleteCrop);

module.exports = router;
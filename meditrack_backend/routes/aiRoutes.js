const express = require('express');
const router = express.Router();
const c = require('../controllers/aiController');
const auth = require('../middleware/auth');

// Assistant santé IA (token obligatoire)
router.post('/chat', auth, c.chat);

module.exports = router;

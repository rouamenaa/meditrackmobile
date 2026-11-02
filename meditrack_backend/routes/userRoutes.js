const express = require('express');
const router = express.Router();
const c = require('../controllers/userController');
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');

// Publiques
router.get('/', c.getUsers);
router.post('/', c.register);
router.post('/login', c.login);

// Protégées (token obligatoire)
router.get('/:id', auth, c.getUser);
router.put('/:id', auth, c.updateUser);
router.put('/:id/password', auth, c.changePassword);
router.delete('/:id', auth, c.deleteUser);
router.post('/:id/photo', auth, upload.single('image'), c.uploadPhoto);

router.get('/:id/medecins', auth, c.getMedecins);
router.post('/:id/medecins', auth, c.addMedecin);
router.delete('/:id/medecins/:medId', auth, c.deleteMedecin);

module.exports = router;
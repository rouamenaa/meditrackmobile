const express = require('express');
const router = express.Router();
const c = require('../controllers/appointmentController');
const auth = require('../middleware/auth');

// Toutes les routes de rendez-vous sont sécurisées par authentification JWT
router.use(auth);

router.get('/', c.getAppointments);
router.get('/:id', c.getAppointmentById);
router.post('/', c.createAppointment);
router.put('/:id', c.updateAppointment);
router.patch('/:id/status', c.updateStatus);
router.delete('/:id', c.deleteAppointment);

module.exports = router;

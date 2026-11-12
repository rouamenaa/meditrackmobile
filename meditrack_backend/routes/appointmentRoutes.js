const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/appointmentController');

router.use(auth);

// Routes unifiées
router.get('/', controller.listMine);
router.post('/', controller.create);
router.get('/:appointmentId', controller.getAppointmentById);
router.put('/:appointmentId', controller.update);
router.patch('/:appointmentId/status', controller.update);
router.delete('/:appointmentId', controller.remove);

module.exports = router;

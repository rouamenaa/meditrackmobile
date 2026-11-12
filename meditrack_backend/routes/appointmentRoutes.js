const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/appointmentController');

router.use(auth);
router.get('/', controller.listMine);
router.post('/', controller.create);
router.put('/:appointmentId', controller.update);
router.delete('/:appointmentId', controller.remove);

module.exports = router;

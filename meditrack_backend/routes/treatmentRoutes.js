const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/treatmentController');

router.use(auth);
router.get('/', controller.listMine);
router.get('/:id', controller.getById);
router.post('/', controller.create);
router.put('/:id', controller.update);
router.delete('/:id', controller.remove);

module.exports = router;
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/activityController');

router.use(auth);

// CRUD des activités physiques
router.get('/', controller.listMine);
router.post('/', controller.create);
router.post('/sync', controller.syncBatch);
router.get('/:id', controller.getById);
router.put('/:id', controller.update);
router.delete('/:id', controller.remove);

module.exports = router;

const express = require('express');
const router = express.Router();
const masterDataController = require('../controllers/masterDataController');

router.get('/warehouses', masterDataController.getWarehouses);
router.get('/categories', masterDataController.getCategories);
router.get('/brands', masterDataController.getBrands);

module.exports = router;

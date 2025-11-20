const express = require('express');
const router = express.Router();
const masterDataController = require('../controllers/masterDataController');

// Warehouses
router.get('/warehouses', masterDataController.getWarehouses);
router.post('/warehouses', masterDataController.createWarehouse);
router.put('/warehouses/:id', masterDataController.updateWarehouse);
router.delete('/warehouses/:id', masterDataController.deleteWarehouse);

// Categories
router.get('/categories', masterDataController.getCategories);
router.post('/categories', masterDataController.createCategory);
router.put('/categories/:id', masterDataController.updateCategory);
router.delete('/categories/:id', masterDataController.deleteCategory);

// Brands
router.get('/brands', masterDataController.getBrands);
router.post('/brands', masterDataController.createBrand);
router.put('/brands/:id', masterDataController.updateBrand);
router.delete('/brands/:id', masterDataController.deleteBrand);

module.exports = router;

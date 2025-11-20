const express = require('express');
const router = express.Router();
const uploadController = require('../controllers/uploadController');
const upload = require('../middleware/upload');
const { authenticate } = require('../middleware/auth');

// Upload product images (protected, max 5 files)
router.post(
    '/products/:productId/images',
    authenticate,
    upload.array('images', 5),
    uploadController.uploadProductImages
);

// Delete product image (protected)
router.delete(
    '/images/:imageId',
    authenticate,
    uploadController.deleteProductImage
);

module.exports = router;

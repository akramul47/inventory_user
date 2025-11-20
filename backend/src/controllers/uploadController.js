const db = require('../config/database');
const fs = require('fs');
const path = require('path');

// Upload product images
async function uploadProductImages(req, res) {
    try {
        const { productId } = req.params;

        if (!req.files || req.files.length === 0) {
            return res.status(400).json({
                status: false,
                message: 'No files uploaded'
            });
        }

        // Check if product exists
        const [products] = await db.query('SELECT * FROM products WHERE id = ?', [productId]);
        if (products.length === 0) {
            return res.status(404).json({
                status: false,
                message: 'Product not found'
            });
        }

        // Insert image records
        const imageRecords = [];
        for (const file of req.files) {
            const [result] = await db.query(
                'INSERT INTO product_images (product_id, image) VALUES (?, ?)',
                [productId, file.filename]
            );

            imageRecords.push({
                id: result.insertId,
                product_id: productId,
                image: file.filename,
                url: `/uploads/products/${file.filename}`
            });
        }

        res.status(201).json({
            status: true,
            message: 'Images uploaded successfully',
            images: imageRecords
        });
    } catch (error) {
        console.error('Upload images error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to upload images'
        });
    }
}

// Delete product image
async function deleteProductImage(req, res) {
    try {
        const { imageId } = req.params;

        // Get image record
        const [images] = await db.query('SELECT * FROM product_images WHERE id = ?', [imageId]);
        
        if (images.length === 0) {
            return res.status(404).json({
                status: false,
                message: 'Image not found'
            });
        }

        const image = images[0];
        
        // Delete file from disk
        const filePath = path.join(__dirname, '../../uploads/products', image.image);
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
        }

        // Delete from database
        await db.query('DELETE FROM product_images WHERE id = ?', [imageId]);

        res.json({
            status: true,
            message: 'Image deleted successfully'
        });
    } catch (error) {
        console.error('Delete image error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to delete image'
        });
    }
}

module.exports = {
    uploadProductImages,
    deleteProductImage
};

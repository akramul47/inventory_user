const db = require('../config/database');

// Get all products with pagination and filtering
// Get all products with pagination and filtering
async function getProducts(req, res) {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = 20;
        const offset = (page - 1) * limit;

        // Build WHERE clause for filtering
        const filters = [];
        const params = [];

        if (req.query.warehouse_id) {
            filters.push('p.warehouse_id = ?');
            params.push(req.query.warehouse_id);
        }

        if (req.query.category_id) {
            filters.push('p.category_id = ?');
            params.push(req.query.category_id);
        }

        if (req.query.brand_id) {
            filters.push('p.brand_id = ?');
            params.push(req.query.brand_id);
        }

        if (req.query.search) {
            filters.push('(p.product_name LIKE ? OR p.unique_code LIKE ? OR p.scan_code LIKE ?)');
            const searchTerm = `%${req.query.search}%`;
            params.push(searchTerm, searchTerm, searchTerm);
        }

        const whereClause = filters.length > 0 ? 'WHERE ' + filters.join(' AND ') : '';

        // Get total count
        const [countResult] = await db.query(
            `SELECT COUNT(*) as total FROM products p ${whereClause}`,
            params
        );
        const total = countResult[0].total;

        // Get products with relations
        const query = `
      SELECT 
        p.*,
        w.name as warehouse_name,
        c.category_name,
        b.brand_name
      FROM products p
      LEFT JOIN warehouses w ON p.warehouse_id = w.id
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN brands b ON p.brand_id = b.id
      ${whereClause}
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `;

        params.push(limit, offset);
        const [products] = await db.query(query, params);

        // Fetch images for these products
        if (products.length > 0) {
            const productIds = products.map(p => p.id);
            const [images] = await db.query(
                'SELECT * FROM product_images WHERE product_id IN (?)',
                [productIds]
            );

            // Map images to products
            products.forEach(product => {
                product.product_images = images.filter(img => img.product_id === product.id);

                // Add warehouse object
                product.warehouse = {
                    id: product.warehouse_id,
                    name: product.warehouse_name
                };
                delete product.warehouse_name;
            });
        } else {
            products.forEach(product => {
                product.product_images = [];
                product.warehouse = {
                    id: product.warehouse_id,
                    name: product.warehouse_name
                };
                delete product.warehouse_name;
            });
        }

        res.json({
            status: true,
            products: {
                data: products,
                total: total,
                page: page,
                per_page: limit,
                last_page: Math.ceil(total / limit),
                next_page_url: page < Math.ceil(total / limit) ? `/api/products?page=${page + 1}` : null
            }
        });
    } catch (error) {
        console.error('Get products error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to fetch products',
            error: error.message
        });
    }
}

// Get single product by ID
// Get single product by ID
async function getProductById(req, res) {
    try {
        const { id } = req.params;

        const query = `
      SELECT 
        p.*,
        w.name as warehouse_name,
        c.category_name,
        b.brand_name
      FROM products p
      LEFT JOIN warehouses w ON p.warehouse_id = w.id
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN brands b ON p.brand_id = b.id
      WHERE p.id = ?
    `;

        const [products] = await db.query(query, [id]);

        if (products.length === 0) {
            return res.status(404).json({
                status: false,
                message: 'Product not found'
            });
        }

        const product = products[0];

        // Fetch images
        const [images] = await db.query(
            'SELECT * FROM product_images WHERE product_id = ?',
            [id]
        );

        product.product_images = images;

        product.warehouse = {
            id: product.warehouse_id,
            name: product.warehouse_name
        };
        delete product.warehouse_name;

        res.json({
            status: true,
            product
        });
    } catch (error) {
        console.error('Get product error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to fetch product'
        });
    }
}

// Create new product
async function createProduct(req, res) {
    try {
        const {
            warehouse_id,
            category_id,
            brand_id,
            product_name,
            unique_code,
            scan_code,
            description,
            product_retail_price,
            product_sale_price,
            quantity
        } = req.body;

        // Validation
        if (!warehouse_id || !category_id || !brand_id || !product_name || !product_retail_price || !product_sale_price) {
            return res.status(400).json({
                status: false,
                message: 'Missing required fields'
            });
        }

        const [result] = await db.query(
            `INSERT INTO products 
       (warehouse_id, category_id, brand_id, product_name, unique_code, scan_code, 
        description, product_retail_price, product_sale_price, quantity, is_sold)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)`,
            [warehouse_id, category_id, brand_id, product_name, unique_code || null,
                scan_code || null, description || null, product_retail_price,
                product_sale_price, quantity || 1]
        );

        const productId = result.insertId;

        // Get created product
        const [products] = await db.query('SELECT * FROM products WHERE id = ?', [productId]);

        res.status(201).json({
            status: true,
            message: 'Product created successfully',
            product: products[0]
        });
    } catch (error) {
        console.error('Create product error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to create product'
        });
    }
}

// Update product
async function updateProduct(req, res) {
    try {
        const { id } = req.params;
        const updates = req.body;

        // Check if product exists
        const [existing] = await db.query('SELECT * FROM products WHERE id = ?', [id]);
        if (existing.length === 0) {
            return res.status(404).json({
                status: false,
                message: 'Product not found'
            });
        }

        // Build SET clause
        const allowedFields = [
            'warehouse_id', 'category_id', 'brand_id', 'product_name',
            'unique_code', 'scan_code', 'description', 'product_retail_price',
            'product_sale_price', 'quantity', 'is_sold'
        ];

        const setFields = [];
        const values = [];

        allowedFields.forEach(field => {
            if (updates[field] !== undefined) {
                setFields.push(`${field} = ?`);
                values.push(updates[field]);
            }
        });

        if (setFields.length === 0) {
            return res.status(400).json({
                status: false,
                message: 'No valid fields to update'
            });
        }

        values.push(id);

        await db.query(
            `UPDATE products SET ${setFields.join(', ')} WHERE id = ?`,
            values
        );

        // Get updated product
        const [products] = await db.query('SELECT * FROM products WHERE id = ?', [id]);

        res.json({
            status: true,
            message: 'Product updated successfully',
            product: products[0]
        });
    } catch (error) {
        console.error('Update product error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to update product'
        });
    }
}

// Delete product
async function deleteProduct(req, res) {
    try {
        const { id } = req.params;

        // Check if product exists
        const [existing] = await db.query('SELECT * FROM products WHERE id = ?', [id]);
        if (existing.length === 0) {
            return res.status(404).json({
                status: false,
                message: 'Product not found'
            });
        }

        // Delete product (images will be cascade deleted)
        await db.query('DELETE FROM products WHERE id = ?', [id]);

        res.json({
            status: true,
            message: 'Product deleted successfully'
        });
    } catch (error) {
        console.error('Delete product error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to delete product'
        });
    }
}

module.exports = {
    getProducts,
    getProductById,
    createProduct,
    updateProduct,
    deleteProduct
};

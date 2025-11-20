const db = require('../config/database');

// Get all warehouses
async function getWarehouses(req, res) {
    try {
        const [warehouses] = await db.query('SELECT * FROM warehouses ORDER BY name');

        res.json({
            status: true,
            warehouses
        });
    } catch (error) {
        console.error('Get warehouses error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to fetch warehouses'
        });
    }
}

// Get all categories
async function getCategories(req, res) {
    try {
        const [categories] = await db.query('SELECT * FROM categories ORDER BY category_name');

        res.json({
            status: true,
            categories
        });
    } catch (error) {
        console.error('Get categories error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to fetch categories'
        });
    }
}

// Get all brands
async function getBrands(req, res) {
    try {
        const [brands] = await db.query('SELECT * FROM brands ORDER BY brand_name');

        res.json({
            status: true,
            brands
        });
    } catch (error) {
        console.error('Get brands error:', error);
        res.status(500).json({
            status: false,
            message: 'Failed to fetch brands'
        });
    }
}

module.exports = {
    getWarehouses,
    createWarehouse,
    updateWarehouse,
    deleteWarehouse,
    getCategories,
    createCategory,
    updateCategory,
    deleteCategory,
    getBrands,
    createBrand,
    updateBrand,
    deleteBrand
};

// --- Warehouses ---

async function createWarehouse(req, res) {
    try {
        const { name } = req.body;
        if (!name) {
            return res.status(400).json({ status: false, message: 'Name is required' });
        }
        const [result] = await db.query('INSERT INTO warehouses (name) VALUES (?)', [name]);
        res.status(201).json({
            status: true,
            message: 'Warehouse created',
            warehouse: { id: result.insertId, name }
        });
    } catch (error) {
        console.error('Create warehouse error:', error);
        res.status(500).json({ status: false, message: 'Failed to create warehouse' });
    }
}

async function updateWarehouse(req, res) {
    try {
        const { id } = req.params;
        const { name } = req.body;
        if (!name) {
            return res.status(400).json({ status: false, message: 'Name is required' });
        }
        await db.query('UPDATE warehouses SET name = ? WHERE id = ?', [name, id]);
        res.json({ status: true, message: 'Warehouse updated' });
    } catch (error) {
        console.error('Update warehouse error:', error);
        res.status(500).json({ status: false, message: 'Failed to update warehouse' });
    }
}

async function deleteWarehouse(req, res) {
    try {
        const { id } = req.params;
        await db.query('DELETE FROM warehouses WHERE id = ?', [id]);
        res.json({ status: true, message: 'Warehouse deleted' });
    } catch (error) {
        console.error('Delete warehouse error:', error);
        res.status(500).json({ status: false, message: 'Failed to delete warehouse' });
    }
}

// --- Categories ---

async function createCategory(req, res) {
    try {
        const { category_name } = req.body;
        if (!category_name) {
            return res.status(400).json({ status: false, message: 'Category name is required' });
        }
        const [result] = await db.query('INSERT INTO categories (category_name) VALUES (?)', [category_name]);
        res.status(201).json({
            status: true,
            message: 'Category created',
            category: { id: result.insertId, category_name }
        });
    } catch (error) {
        console.error('Create category error:', error);
        res.status(500).json({ status: false, message: 'Failed to create category' });
    }
}

async function updateCategory(req, res) {
    try {
        const { id } = req.params;
        const { category_name } = req.body;
        if (!category_name) {
            return res.status(400).json({ status: false, message: 'Category name is required' });
        }
        await db.query('UPDATE categories SET category_name = ? WHERE id = ?', [category_name, id]);
        res.json({ status: true, message: 'Category updated' });
    } catch (error) {
        console.error('Update category error:', error);
        res.status(500).json({ status: false, message: 'Failed to update category' });
    }
}

async function deleteCategory(req, res) {
    try {
        const { id } = req.params;
        await db.query('DELETE FROM categories WHERE id = ?', [id]);
        res.json({ status: true, message: 'Category deleted' });
    } catch (error) {
        console.error('Delete category error:', error);
        res.status(500).json({ status: false, message: 'Failed to delete category' });
    }
}

// --- Brands ---

async function createBrand(req, res) {
    try {
        const { brand_name } = req.body;
        if (!brand_name) {
            return res.status(400).json({ status: false, message: 'Brand name is required' });
        }
        const [result] = await db.query('INSERT INTO brands (brand_name) VALUES (?)', [brand_name]);
        res.status(201).json({
            status: true,
            message: 'Brand created',
            brand: { id: result.insertId, brand_name }
        });
    } catch (error) {
        console.error('Create brand error:', error);
        res.status(500).json({ status: false, message: 'Failed to create brand' });
    }
}

async function updateBrand(req, res) {
    try {
        const { id } = req.params;
        const { brand_name } = req.body;
        if (!brand_name) {
            return res.status(400).json({ status: false, message: 'Brand name is required' });
        }
        await db.query('UPDATE brands SET brand_name = ? WHERE id = ?', [brand_name, id]);
        res.json({ status: true, message: 'Brand updated' });
    } catch (error) {
        console.error('Update brand error:', error);
        res.status(500).json({ status: false, message: 'Failed to update brand' });
    }
}

async function deleteBrand(req, res) {
    try {
        const { id } = req.params;
        await db.query('DELETE FROM brands WHERE id = ?', [id]);
        res.json({ status: true, message: 'Brand deleted' });
    } catch (error) {
        console.error('Delete brand error:', error);
        res.status(500).json({ status: false, message: 'Failed to delete brand' });
    }
}

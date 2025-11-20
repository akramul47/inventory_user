const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'inventory_db',
};

async function seedMasterData() {
    const connection = await mysql.createConnection(dbConfig);
    
    try {
        console.log('🌱 Seeding master data...\n');
        
        // Seed Warehouses
        console.log('📦 Seeding warehouses...');
        const [existingWarehouses] = await connection.query('SELECT COUNT(*) as count FROM warehouses');
        
        if (existingWarehouses[0].count === 0) {
            const warehouses = [
                ['Main Warehouse'],
                ['Secondary Warehouse'],
                ['Distribution Center'],
                ['Retail Store A'],
                ['Retail Store B']
            ];
            
            const warehouseResult = await connection.query(
                'INSERT INTO warehouses (name) VALUES ?',
                [warehouses]
            );
            console.log(`✅ ${warehouseResult[0].affectedRows} warehouses created\n`);
        } else {
            console.log(`ℹ️  Warehouses already exist (${existingWarehouses[0].count} records)\n`);
        }
        
        // Seed Categories
        console.log('📂 Seeding categories...');
        const [existingCategories] = await connection.query('SELECT COUNT(*) as count FROM categories');
        
        if (existingCategories[0].count === 0) {
            const categories = [
                ['Electronics'],
                ['Clothing'],
                ['Food & Beverages'],
                ['Home & Garden'],
                ['Sports & Outdoors'],
                ['Books & Media'],
                ['Toys & Games'],
                ['Health & Beauty']
            ];
            
            const categoryResult = await connection.query(
                'INSERT INTO categories (category_name) VALUES ?',
                [categories]
            );
            console.log(`✅ ${categoryResult[0].affectedRows} categories created\n`);
        } else {
            console.log(`ℹ️  Categories already exist (${existingCategories[0].count} records)\n`);
        }
        
        // Seed Brands
        console.log('🏷️  Seeding brands...');
        const [existingBrands] = await connection.query('SELECT COUNT(*) as count FROM brands');
        
        if (existingBrands[0].count === 0) {
            const brands = [
                ['Samsung'],
                ['Apple'],
                ['Nike'],
                ['Adidas'],
                ['Sony'],
                ['LG'],
                ['Coca-Cola'],
                ['Pepsi'],
                ['Generic Brand'],
                ['House Brand']
            ];
            
            const brandResult = await connection.query(
                'INSERT INTO brands (brand_name) VALUES ?',
                [brands]
            );
            console.log(`✅ ${brandResult[0].affectedRows} brands created\n`);
        } else {
            console.log(`ℹ️  Brands already exist (${existingBrands[0].count} records)\n`);
        }
        
        console.log('🎉 Master data seeding completed successfully!');
        
    } catch (error) {
        console.error('❌ Error seeding master data:', error);
        throw error;
    } finally {
        await connection.end();
    }
}

// Run the seed function
seedMasterData()
    .then(() => {
        console.log('\n✨ All done!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n💥 Seeding failed:', error);
        process.exit(1);
    });

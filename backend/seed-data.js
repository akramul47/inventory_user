const db = require('./src/config/database');

async function seedData() {
    console.log('🌱 Seeding Master Data...');

    try {
        // 1. Seed Warehouses
        console.log('Seeding Warehouses...');
        const warehouses = [
            ['Main Warehouse'],
            ['West Coast Hub'],
            ['East Coast Depot']
        ];

        for (const w of warehouses) {
            await db.query(
                'INSERT IGNORE INTO warehouses (name) VALUES (?)',
                w
            );
        }

        // 2. Seed Categories
        console.log('Seeding Categories...');
        const categories = [
            ['Electronics'],
            ['Clothing'],
            ['Home & Garden'],
            ['Toys'],
            ['Books']
        ];

        for (const c of categories) {
            await db.query(
                'INSERT IGNORE INTO categories (category_name) VALUES (?)',
                c
            );
        }

        // 3. Seed Brands
        console.log('Seeding Brands...');
        const brands = [
            ['Apple'],
            ['Samsung'],
            ['Nike'],
            ['Adidas'],
            ['Sony']
        ];

        for (const b of brands) {
            await db.query(
                'INSERT IGNORE INTO brands (brand_name) VALUES (?)',
                b
            );
        }

        console.log('✅ Seeding complete!');
        process.exit(0);

    } catch (error) {
        console.error('❌ Seeding failed:', error);
        process.exit(1);
    }
}

seedData();

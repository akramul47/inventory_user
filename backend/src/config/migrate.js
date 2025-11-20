const mysql = require('mysql2/promise');
require('dotenv').config();

async function createDatabase() {
    const connection = await mysql.createConnection({
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 3306,
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
    });

    try {
        // Create database if not exists
        await connection.query(`CREATE DATABASE IF NOT EXISTS ${process.env.DB_NAME || 'inventory_db'}`);
        console.log(`✅ Database '${process.env.DB_NAME || 'inventory_db'}' created or already exists`);

        // Use the database
        await connection.query(`USE ${process.env.DB_NAME || 'inventory_db'}`);

        // Create users table
        await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT PRIMARY KEY AUTO_INCREMENT,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255),
        google_id VARCHAR(255) UNIQUE,
        name VARCHAR(255),
        profile_image VARCHAR(500),
        role ENUM('admin', 'user') DEFAULT 'user',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
        console.log('✅ Users table created');

        // Create warehouses table
        await connection.query(`
      CREATE TABLE IF NOT EXISTS warehouses (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
        console.log('✅ Warehouses table created');

        // Create categories table
        await connection.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id INT PRIMARY KEY AUTO_INCREMENT,
        category_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
        console.log('✅ Categories table created');

        // Create brands table
        await connection.query(`
      CREATE TABLE IF NOT EXISTS brands (
        id INT PRIMARY KEY AUTO_INCREMENT,
        brand_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
        console.log('✅ Brands table created');

        // Create products table
        await connection.query(`
      CREATE TABLE IF NOT EXISTS products (
        id INT PRIMARY KEY AUTO_INCREMENT,
        warehouse_id INT NOT NULL,
        category_id INT NOT NULL,
        brand_id INT NOT NULL,
        product_name VARCHAR(255) NOT NULL,
        unique_code VARCHAR(255) UNIQUE,
        scan_code VARCHAR(255),
        description TEXT,
        product_retail_price DECIMAL(10, 2) NOT NULL,
        product_sale_price DECIMAL(10, 2) NOT NULL,
        quantity INT DEFAULT 1,
        is_sold TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (brand_id) REFERENCES brands(id)
      )
    `);
        console.log('✅ Products table created');

        // Create product_images table
        await connection.query(`
      CREATE TABLE IF NOT EXISTS product_images (
        id INT PRIMARY KEY AUTO_INCREMENT,
        product_id INT NOT NULL,
        image VARCHAR(500) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    `);
        console.log('✅ Product images table created');

        // Create sales table
        await connection.query(`
      CREATE TABLE IF NOT EXISTS sales (
        id INT PRIMARY KEY AUTO_INCREMENT,
        product_id INT NOT NULL,
        product_sold_price DECIMAL(10, 2) NOT NULL,
        sold_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    `);
        console.log('✅ Sales table created');

        // Create product_shifts table
        await connection.query(`
      CREATE TABLE IF NOT EXISTS product_shifts (
        id INT PRIMARY KEY AUTO_INCREMENT,
        product_id INT NOT NULL,
        from_warehouse_id INT NOT NULL,
        to_warehouse_id INT NOT NULL,
        shifted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id),
        FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(id),
        FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(id)
      )
    `);
        console.log('✅ Product shifts table created');

        console.log('\n🎉 Database migration completed successfully!');
    } catch (error) {
        console.error('❌ Error during migration:', error);
    } finally {
        await connection.end();
    }
}

// Run migration
createDatabase();

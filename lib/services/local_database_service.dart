import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:inventory_user/models/product_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Local Database Service for Offline Caching
/// 
/// Provides seamless offline access to:
/// - Products
/// - Warehouses
/// - Categories  
/// - Brands
/// 
/// NOTE: Database caching is disabled on Web platform (sqflite not supported)
class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'inventory_cache.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String _productsTable = 'products';
  static const String _warehousesTable = 'warehouses';
  static const String _categoriesTable = 'categories';
  static const String _brandsTable = 'brands';

  /// Get database instance (singleton)
  /// Returns null on web platform
  Future<Database?> get database async {
    // Disable database on web platform
    if (kIsWeb) {
      return null;
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE $_productsTable (
        id INTEGER PRIMARY KEY,
        warehouse_id TEXT,
        category_id INTEGER,
        brand_id INTEGER,
        name TEXT,
        unique_code TEXT,
        barcode TEXT,
        retail_price REAL,
        sale_price REAL,
        is_sold INTEGER,
        created_at TEXT,
        updated_at TEXT,
        description TEXT,
        quantity INTEGER,
        image_url TEXT,
        warehouse_tag TEXT,
        image_urls TEXT,
        product_images TEXT
      )
    ''');

    // Warehouses table
    await db.execute('''
      CREATE TABLE $_warehousesTable (
        id INTEGER PRIMARY KEY,
        name TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE $_categoriesTable (
        id INTEGER PRIMARY KEY,
        category_name TEXT,
        description TEXT
      )
    ''');

    // Brands table
    await db.execute('''
      CREATE TABLE $_brandsTable (
        id INTEGER PRIMARY KEY,
        brand_name TEXT,
        description TEXT
      )
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop and recreate tables with correct schema
      await db.execute('DROP TABLE IF EXISTS $_categoriesTable');
      await db.execute('DROP TABLE IF EXISTS $_brandsTable');
      await db.execute('DROP TABLE IF EXISTS $_warehousesTable');
      
      // Recreate with correct column names
      await db.execute('''
        CREATE TABLE $_warehousesTable (
          id INTEGER PRIMARY KEY,
          name TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE $_categoriesTable (
          id INTEGER PRIMARY KEY,
          category_name TEXT,
          description TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE $_brandsTable (
          id INTEGER PRIMARY KEY,
          brand_name TEXT,
          description TEXT
        )
      ''');
    }
  }

  // ============ PRODUCTS ============

  /// Save products to local cache
  /// Does nothing on web platform
  Future<void> saveProducts(List<Product> products) async {
    if (kIsWeb) return;
    
    final db = await database;
    if (db == null) return;
    
    final batch = db.batch();

    for (var product in products) {
      batch.insert(
        _productsTable,
        _productToMap(product),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached products
  /// Returns empty list on web platform
  Future<List<Product>> getCachedProducts() async {
    if (kIsWeb) return [];
    
    final db = await database;
    if (db == null) return [];
    
    final List<Map<String, dynamic>> maps = await db.query(_productsTable);
    return List.generate(maps.length, (i) => _productFromMap(maps[i]));
  }

  /// Clear all products
  /// Does nothing on web platform
  Future<void> clearProducts() async {
    if (kIsWeb) return;
    
    final db = await database;
    if (db == null) return;
    
    await db.delete(_productsTable);
  }

  // ============ WAREHOUSES ============

  /// Save warehouses to local cache
  /// Does nothing on web platform
  Future<void> saveWarehouses(List<Warehouse> warehouses) async {
    if (kIsWeb) return;
    
    final db = await database;
    if (db == null) return;
    
    final batch = db.batch();

    for (var warehouse in warehouses) {
      batch.insert(
        _warehousesTable,
        warehouse.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached warehouses
  /// Returns empty list on web platform
  Future<List<Warehouse>> getCachedWarehouses() async {
    if (kIsWeb) return [];
    
    final db = await database;
    if (db == null) return [];
    
    final List<Map<String, dynamic>> maps = await db.query(_warehousesTable);
    return List.generate(maps.length, (i) => Warehouse.fromJson(maps[i]));
  }

  // ============ CATEGORIES ============

  /// Save categories to local cache
  /// Does nothing on web platform
  Future<void> saveCategories(List<Category> categories) async {
    if (kIsWeb) return;
    
    final db = await database;
    if (db == null) return;
    
    final batch = db.batch();

    for (var category in categories) {
      batch.insert(
        _categoriesTable,
        category.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached categories
  /// Returns empty list on web platform
  Future<List<Category>> getCachedCategories() async {
    if (kIsWeb) return [];
    
    final db = await database;
    if (db == null) return [];
    
    final List<Map<String, dynamic>> maps = await db.query(_categoriesTable);
    return List.generate(maps.length, (i) => Category.fromJson(maps[i]));
  }

  // ============ BRANDS ============

  /// Save brands to local cache
  /// Does nothing on web platform
  Future<void> saveBrands(List<Brand> brands) async {
    if (kIsWeb) return;
    
    final db = await database;
    if (db == null) return;
    
    final batch = db.batch();

    for (var brand in brands) {
      batch.insert(
        _brandsTable,
        brand.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get cached brands
  /// Returns empty list on web platform
  Future<List<Brand>> getCachedBrands() async {
    if (kIsWeb) return [];
    
    final db = await database;
    if (db == null) return [];
    
    final List<Map<String, dynamic>> maps = await db.query(_brandsTable);
    return List.generate(maps.length, (i) => Brand.fromJson(maps[i]));
  }

  // ============ UTILITY METHODS ============

  /// Clear all cached data
  /// Does nothing on web platform
  Future<void> clearAllCache() async {
    if (kIsWeb) return;
    
    final db = await database;
    if (db == null) return;
    
    await db.delete(_productsTable);
    await db.delete(_warehousesTable);
    await db.delete(_categoriesTable);
    await db.delete(_brandsTable);
  }

  /// Convert Product to Map for SQLite
  Map<String, dynamic> _productToMap(Product product) {
    return {
      'id': product.id,
      'warehouse_id': product.warehouseId,
      'category_id': product.categoryId,
      'brand_id': product.brandId,
      'name': product.name,
      'unique_code': product.uniqueCode,
      'barcode': product.barcode,
      'retail_price': product.retailPrice,
      'sale_price': product.salePrice,
      'is_sold': product.isSold ? 1 : 0,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt?.toIso8601String(),
      'description': product.description,
      'quantity': product.quantity,
      'image_url': product.imageUrl,
      'warehouse_tag': product.warehouseTag,
      'image_urls': jsonEncode(product.imageUrls),
      'product_images': jsonEncode(product.images.map((img) => img.toJson()).toList()),
    };
  }

  /// Convert Map from SQLite to Product
  Product _productFromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      warehouseId: map['warehouse_id'],
      categoryId: map['category_id'],
      brandId: map['brand_id'],
      name: map['name'],
      uniqueCode: map['unique_code'],
      barcode: map['barcode'],
      retailPrice: map['retail_price'],
      salePrice: map['sale_price'],
      isSold: map['is_sold'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      description: map['description'],
      quantity: map['quantity'],
      imageUrl: map['image_url'],
      warehouseTag: map['warehouse_tag'],
      imageUrls: List<String>.from(jsonDecode(map['image_urls'])),
      images: (jsonDecode(map['product_images']) as List)
          .map((json) => ProductImage.fromJson(json))
          .toList(),
    );
  }
}

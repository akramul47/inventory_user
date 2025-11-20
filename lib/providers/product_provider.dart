import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inventory_user/main.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/services/product_api_service.dart';
import 'package:inventory_user/services/local_database_service.dart';
import 'package:provider/provider.dart';

class ProductProvider extends ChangeNotifier {
  final ProductApiService _productApiService = ProductApiService();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  final List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];
  int _currentPage = 0;
  int _totalProducts = 0;

  List<Product> get products => _products;
  List<Warehouse> get warehouses => _warehouses;
  List<Category> get categories => _categories;
  List<Brand> get brands => _brands;
  int get currentPage => _currentPage;
  int get totalProducts => _totalProducts;

  // ============ CLEAR DATA ============

  void clearProducts() {
    _products.clear();
  }

  void resetCurrentPage() {
    _currentPage = 0;
  }

  void clearAllData() {
    _products.clear();
    _warehouses.clear();
    _categories.clear();
    _brands.clear();
    _currentPage = 0;
    _totalProducts = 0;
  }

  // ============ PRODUCTS ============

  /// Fetch products by page with offline fallback
  Future<Map<String, dynamic>> fetchProductsByPage(int page) async {
    try {
      final response = await _productApiService.getProducts(page);

      if (response['products'] != null) {
        final productsData = response['products']['data'] as List;
        _totalProducts = response['products']['total'];

        final List<Product> nextPageProducts =
            productsData.map((data) => Product.fromJson(data)).toList();

        // Cache products offline
        await _localDb.saveProducts(nextPageProducts);

        final nextPageUrl = response['products']['next_page_url'];

        return {
          'products': nextPageProducts,
          'next_page_url': nextPageUrl,
        };
      }

      throw Exception('Invalid response format');
    } catch (e) {
      print('Error fetching products: $e - Loading from cache');

      // Load from cache on error
      final cachedProducts = await _localDb.getCachedProducts();
      return {
        'products': cachedProducts,
        'next_page_url': null,
      };
    }
  }

  /// Load more products
  Future<void> loadMoreProducts() async {
    try {
      final nextPage = _currentPage + 1;
      final nextPageData = await fetchProductsByPage(nextPage);
      final List<Product> nextPageProducts = nextPageData['products'];
      final nextPageUrl = nextPageData['next_page_url'];

      _products.addAll(nextPageProducts);
      _currentPage = nextPage;

      notifyListeners();

      if (nextPageUrl == null) {
        return;
      }
    } catch (e) {
      print('Error loading more products: $e');
    }
  }

  /// Update product
  Future<void> updateProduct({
    required int id,
    required Map<String, dynamic> updatedFields,
  }) async {
    try {
      await _productApiService.updateProduct(id, updatedFields);
    } catch (error) {
      print('Error updating product: $error');
      rethrow;
    }
  }

  // ============ WAREHOUSES ============

  /// Fetch warehouses with offline caching
  Future<List<Warehouse>> fetchWarehouses({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _warehouses.isNotEmpty) {
        return _warehouses;
      }

      // Try to fetch from API
      _warehouses = await _productApiService.getWarehouses();

      // Cache offline
      await _localDb.saveWarehouses(_warehouses);

      notifyListeners();
      return _warehouses;
    } catch (e) {
      print('Error fetching warehouses: $e - Loading from cache');

      // Load from cache on error
      _warehouses = await _localDb.getCachedWarehouses();
      notifyListeners();
      return _warehouses;
    }
  }

  // ============ CATEGORIES ============

  /// Fetch categories with offline caching
  Future<List<Category>> fetchCategories() async {
    try {
      _categories = await _productApiService.getCategories();

      // Cache offline
      await _localDb.saveCategories(_categories);

      notifyListeners();
      return _categories;
    } catch (e) {
      print('Error fetching categories: $e - Loading from cache');

      // Load from cache on error
      _categories = await _localDb.getCachedCategories();
      notifyListeners();
      return _categories;
    }
  }

  // ============ BRANDS ============

  /// Fetch brands with offline caching
  Future<List<Brand>> fetchBrands() async {
    try {
      _brands = await _productApiService.getBrands();

      // Cache offline
      await _localDb.saveBrands(_brands);

      notifyListeners();
      return _brands;
    } catch (e) {
      print('Error fetching brands: $e - Loading from cache');

      // Load from cache on error
      _brands = await _localDb.getCachedBrands();
      notifyListeners();
      return _brands;
    }
  }

  /// Fetch all master data (warehouses, categories, brands)
  Future<void> fetchWarehouseCategoryBrand() async {
    try {
      // Load from cache first for instant display
      _warehouses = await _localDb.getCachedWarehouses();
      _categories = await _localDb.getCachedCategories();
      _brands = await _localDb.getCachedBrands();
      notifyListeners();

      // Then fetch fresh data from API
      await Future.wait([
        fetchWarehouses(forceRefresh: true),
        fetchCategories(),
        fetchBrands(),
      ]);
    } catch (e) {
      print('Error fetching master data: $e');
      throw Exception('Failed to fetch master data');
    }
  }

  // ============ PRODUCT MANAGEMENT ============

  /// Add a new product
  Future<void> addProduct(
      Map<String, dynamic> productData, List<File> images) async {
    try {
      // Create product first
      final result = await _productApiService.createProduct(productData);
      
      // Upload images if product was created successfully and there are images
      if (result['status'] == true && images.isNotEmpty) {
        final productId = result['product']?['id'];
        if (productId != null) {
          await _productApiService.uploadProductImages(productId, images);
        }
      }
      
      // Refresh list
      resetCurrentPage();
      await fetchProductsByPage(1);
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  /// Delete a product by its ID
  Future<void> deleteProduct(int id) async {
    try {
      await _productApiService.deleteProduct(id);
      // Remove from local list
      _products.removeWhere((product) => product.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
}

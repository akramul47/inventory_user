import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_user/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_user/services/auth_servcie.dart';

const String baseUrl = 'https://warehouse.z8tech.one/Backend/public/api';
const String baseUrlWithoutApi = 'https://warehouse.z8tech.one/Backend/public';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];

  List<Product> get products => _products;
  List<Warehouse> get warehouses => _warehouses;
  List<Category> get categories => _categories;
  List<Brand> get brands => _brands;

  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _products.isNotEmpty) {
        // If forceRefresh is false and products are already loaded, return without fetching again
        return _products;
      }

      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
            jsonDecode(response.body)['products']['data'];
        _products = responseData.map((data) {
          final product = Product.fromJson(data);
          return product;
        }).toList();

        await saveProductsToLocal(_products);
        notifyListeners();
        return _products;
      } else {
        throw Exception('Failed to fetch products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to fetch products');
    }
  }

  Future<void> saveProductsToLocal(List<Product> products) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> productsJsonStrings =
          products.map((product) => jsonEncode(product.toJson())).toList();
      await prefs.setStringList('products', productsJsonStrings);
    } catch (e) {
      print('Error updating local storage: $e');
      throw Exception('Failed to update local storage');
    }
  }

  Future<void> loadProductsFromLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? productsJsonStrings = prefs.getStringList('products');
      if (productsJsonStrings != null) {
        _products = productsJsonStrings
            .map((jsonString) => Product.fromJson(
                jsonDecode(jsonString) as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading products from local storage: $e');
      throw Exception('Failed to load products from local storage');
    }
  }

  Future<List<Warehouse>> fetchWarehouses(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/warehouses'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> warehousesData = data['data'];
      final List<Warehouse> warehouses = warehousesData
          .map((warehouseJson) => Warehouse.fromJson(warehouseJson))
          .toList();
      return warehouses;
    } else {
      throw Exception('Failed to fetch warehouses');
    }
  }

  Future<List<Category>> fetchCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> categoriesData = data['data'];
      final List<Category> categories = categoriesData
          .map((categoryJson) => Category.fromJson(categoryJson))
          .toList();
      return categories;
    } else {
      throw Exception('Failed to fetch categories');
    }
  }

  Future<List<Brand>> fetchBrands(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/brands'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> brandsData = data['data'];
      final List<Brand> brands =
          brandsData.map((brandJson) => Brand.fromJson(brandJson)).toList();
      return brands;
    } else {
      throw Exception('Failed to fetch brands');
    }
  }

  Future<void> fetchWarehouseCategoryBrand(String token) async {
    try {
      // Fetch warehouses
      final List<Warehouse> warehouses = await fetchWarehouses(token);
      _warehouses = warehouses;

      // Fetch categories
      final List<Category> categories = await fetchCategories(token);
      _categories = categories;

      // Fetch brands
      final List<Brand> brands = await fetchBrands(token);
      _brands = brands;

      notifyListeners();
    } catch (e) {
      print('Error fetching warehouse, category, and brand: $e');
      throw Exception('Failed to fetch warehouse, category, and brand');
    }
  }

  // Method to add a new product
  void addProduct(Product newProduct) {
    _products.add(newProduct);
    notifyListeners();
  }

  // Method to remove a product by its ID
  void removeProductById(int id) {
    _products.removeWhere((product) => product.id == id);
    notifyListeners();
  }

  // Method to update an existing product
  void updateProduct(Product updatedProduct) {
    final index =
        _products.indexWhere((product) => product.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }
}

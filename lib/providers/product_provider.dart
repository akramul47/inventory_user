import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inventory_user/main.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_user/services/auth_servcie.dart';

const String baseUrl = 'https://warehouse.z8tech.one/Backend/public/api';
const String baseUrlWithoutApi = 'https://warehouse.z8tech.one/Backend/public';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];
  int _currentPage = 0; // Track the current page
  int _totalProducts = 0;

  List<Product> get products => _products;
  List<Warehouse> get warehouses => _warehouses;
  List<Category> get categories => _categories;
  List<Brand> get brands => _brands;
  int get currentPage => _currentPage;
  int get totalProducts => _totalProducts;
  

  // Setters or methods
  void clearProducts() {
    _products.clear();
  }

  void resetCurrentPage() {
    _currentPage = 0;
  }

  Future<void> logoutUser() async {
    try {
      // Remove the token from local storage
      // await AuthService.removeToken();

      // Notify the AuthProvider about the logout
      final authProvider = Provider.of<AuthProvider>(
          navigatorKey.currentContext!,
          listen: false);
      await authProvider.logout();

      // Clear all product-related data in memory
      _products.clear();
      _warehouses.clear();
      _categories.clear();
      _brands.clear();
      _currentPage = 0;
      _totalProducts = 0;

      // Clear data from SharedPreferences
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.clear();

      // Notify listeners about the data changes
      notifyListeners();
    } catch (e) {
      // print('Error during logout: $e');
    }
  }

  Future<Map<String, dynamic>> fetchProductsByPage(int page) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/products?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> productsData = responseData['products']['data'];
        print(productsData);
        
        // Update totalProducts with the total count from API response
        _totalProducts = responseData['products']['total'];

        final List<Product> nextPageProducts = productsData.map((data) {
          final product = Product.fromJson(data);
          return product;
        }).toList();

        final nextPageUrl = responseData['products']['next_page_url'];

        return {
          'products': nextPageProducts,
          'next_page_url': nextPageUrl,
        };
      } else {
        // Check if the response indicates an invalid token
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['message'] == 'Token has expired') {
          // Token has expired, log out the user and show a snackbar
          await logoutUser();
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('Logged out. Token expired!'),
            ),
          );
        } else {
          throw Exception('Failed to fetch products');
        }

        // Return a default value if an exception is not thrown above
        return {
          'products': [], // or any default value you prefer
          'next_page_url': null, // or any default value you prefer
        };
      }
    } catch (e) {
      // print('Error fetching products: $e');
      throw Exception('Failed to fetch products');
    }
  }

// Method to load more products
  Future<void> loadMoreProducts() async {
    try {
      final nextPage = _currentPage + 1;
      final nextPageData = await fetchProductsByPage(nextPage);
      final List<Product> nextPageProducts = nextPageData['products'];
      final nextPageUrl = nextPageData['next_page_url'];

      // Otherwise, continue loading
      _products.addAll(nextPageProducts);
      _currentPage = nextPage;

      notifyListeners();

      // Check if next_page_url is null
      if (nextPageUrl == null) {
        // Next page URL is null, so no more products to load
        return;
      }

      // You can choose to save to local storage here if needed

      
    } catch (e) {
      // print('Error loading more products: $e');
    }
  }

  // Future<void> saveProductsToLocal(List<Product> products) async {
  //   try {
  //     final SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final List<String> productsJsonStrings =
  //         products.map((product) => jsonEncode(product.toJson())).toList();
  //     await prefs.setStringList('products', productsJsonStrings);
  //   } catch (e) {
  //     // print('Error updating local storage: $e');
  //     throw Exception('Failed to update local storage');
  //   }
  // }

  // Future<void> loadProductsFromLocal() async {
  //   try {
  //     final SharedPreferences prefs = await SharedPreferences.getInstance();
  //     final List<String>? productsJsonStrings = prefs.getStringList('products');
  //     if (productsJsonStrings != null) {
  //       _products = productsJsonStrings
  //           .map((jsonString) => Product.fromJson(
  //               jsonDecode(jsonString) as Map<String, dynamic>))
  //           .toList();
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     // print('Error loading products from local storage: $e');
  //     throw Exception('Failed to load products from local storage');
  //   }
  // }

  Future<void> updateProduct({
    required int id,
    required Map<String, dynamic> updatedFields,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/update/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedFields),
      );

      if (response.statusCode == 200) {
        // Update local data
        // final Map<String, dynamic> responseData = jsonDecode(response.body);
        // final Product updatedProduct =
        //     Product.fromJson(responseData['product']);
        // updateProductLocally(updatedProduct);
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (error) {
      // print('Error updating product: $error');
      throw Exception('Failed to update product');
    }
  }

  // void updateProductLocally(Product updatedProduct) {
  //   final index =
  //       _products.indexWhere((product) => product.id == updatedProduct.id);
  //   if (index != -1) {
  //     _products[index] = updatedProduct;
  //     notifyListeners();
  //   }
  // }

  Future<List<Warehouse>> fetchWarehouses(
      {bool forceRefresh = false, String? token}) async {
    try {
      if (!forceRefresh && _warehouses.isNotEmpty) {
        // If forceRefresh is false and warehouses are already loaded, return without fetching again
        return _warehouses;
      }

      // Use the provided token or fetch internally if not provided
      final fetchToken = token ?? await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/warehouses'),
        headers: {
          'Authorization': 'Bearer $fetchToken',
        },
      );

      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body)['data'];
        _warehouses = responseData.map((data) {
          final warehouse = Warehouse.fromJson(data);
          return warehouse;
        }).toList();

        await saveWarehousesToLocal(_warehouses);
        notifyListeners();
        return _warehouses;
      } else {
        throw Exception('Failed to fetch warehouses');
      }
    } catch (e) {
      // print('Error fetching warehouses: $e');
      throw Exception('Failed to fetch warehouses');
    }
  }

  Future<void> saveWarehousesToLocal(List<Warehouse> warehouses) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> warehousesJsonStrings = warehouses
          .map((warehouse) => jsonEncode(warehouse.toJson()))
          .toList();
      await prefs.setStringList('warehouses', warehousesJsonStrings);
      // print('Warehouses: $_warehouses');
    } catch (e) {
      // print('Error updating local storage: $e');
      throw Exception('Failed to update local storage');
    }
  }

  Future<void> loadWarehousesFromLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? warehousesJsonStrings =
          prefs.getStringList('warehouses');
      if (warehousesJsonStrings != null) {
        _warehouses = warehousesJsonStrings
            .map((jsonString) => Warehouse.fromJson(jsonDecode(jsonString)))
            .toList();
        notifyListeners();
      } else {
        // If no warehouses are found in local storage, fetch from API
        await fetchWarehouses(forceRefresh: true);
      }
    } catch (e) {
      // print('Error loading warehouses from local storage: $e');
      throw Exception('Failed to load warehouses from local storage');
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

  Future<void> loadCategoriesFromLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? categoriesJsonStrings =
          prefs.getStringList('categories');
      if (categoriesJsonStrings != null) {
        _categories = categoriesJsonStrings
            .map((jsonString) => Category.fromJson(jsonDecode(jsonString)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // print('Error loading categories from local storage: $e');
      throw Exception('Failed to load categories from local storage');
    }
  }

  Future<void> loadBrandsFromLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? brandsJsonStrings = prefs.getStringList('brands');
      if (brandsJsonStrings != null) {
        _brands = brandsJsonStrings
            .map((jsonString) => Brand.fromJson(jsonDecode(jsonString)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // print('Error loading brands from local storage: $e');
      throw Exception('Failed to load brands from local storage');
    }
  }

  Future<void> saveCategoriesToLocal(List<Category> categories) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> categoriesJsonStrings =
          categories.map((category) => jsonEncode(category.toJson())).toList();
      await prefs.setStringList('categories', categoriesJsonStrings);
    } catch (e) {
      // print('Error updating local storage: $e');
      throw Exception('Failed to update local storage');
    }
  }

  Future<void> saveBrandsToLocal(List<Brand> brands) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> brandsJsonStrings =
          brands.map((brand) => jsonEncode(brand.toJson())).toList();
      await prefs.setStringList('brands', brandsJsonStrings);
    } catch (e) {
      // print('Error updating local storage: $e');
      throw Exception('Failed to update local storage');
    }
  }

  Future<void> fetchWarehouseCategoryBrand(String token) async {
    try {
      // Load warehouses, categories, and brands from local storage
      await loadWarehousesFromLocal();
      await loadCategoriesFromLocal();
      await loadBrandsFromLocal();

      // Fetch warehouses, categories, and brands from API
      final List<Warehouse> warehouses = await fetchWarehouses();
      final List<Category> categories = await fetchCategories(token);
      final List<Brand> brands = await fetchBrands(token);

      // Compare fetched data with local data
      final warehousesChanged = _compareWarehouses(warehouses);
      final categoriesChanged = _compareCategories(categories);
      final brandsChanged = _compareBrands(brands);

      // Update local data if necessary
      if (warehousesChanged) {
        await saveWarehousesToLocal(warehouses);
        _warehouses = warehouses;
      }
      if (categoriesChanged) {
        await saveCategoriesToLocal(categories);
        _categories = categories;
      }
      if (brandsChanged) {
        await saveBrandsToLocal(brands);
        _brands = brands;
      }

      notifyListeners();
    } catch (e) {
      // print('Error fetching warehouse, category, and brand: $e');
      throw Exception('Failed to fetch warehouse, category, and brand');
    }
  }

  // Compare local warehouses with fetched warehouses
  bool _compareWarehouses(List<Warehouse> fetchedWarehouses) {
    // Compare lengths
    if (_warehouses.length != fetchedWarehouses.length) {
      return true;
    }

    // Compare each warehouse
    for (int i = 0; i < _warehouses.length; i++) {
      if (_warehouses[i] != fetchedWarehouses[i]) {
        return true;
      }
    }

    return false;
  }

  // Compare local categories with fetched categories
  bool _compareCategories(List<Category> fetchedCategories) {
    // Compare lengths
    if (_categories.length != fetchedCategories.length) {
      return true;
    }

    // Compare each category
    for (int i = 0; i < _categories.length; i++) {
      if (_categories[i] != fetchedCategories[i]) {
        return true;
      }
    }

    return false;
  }

  // Compare local brands with fetched brands
  bool _compareBrands(List<Brand> fetchedBrands) {
    // Compare lengths
    if (_brands.length != fetchedBrands.length) {
      return true;
    }

    // Compare each brand
    for (int i = 0; i < _brands.length; i++) {
      if (_brands[i] != fetchedBrands[i]) {
        return true;
      }
    }

    return false;
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
}

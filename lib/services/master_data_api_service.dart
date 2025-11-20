import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/services/api_service.dart';
import 'package:inventory_user/utils/api_constants.dart';

/// Master Data API Service
///
/// Handles CRUD operations for:
/// - Warehouses
/// - Categories
/// - Brands
class MasterDataApiService {
  final ApiService _apiService = ApiService();

  // ============ WAREHOUSES ============

  /// Get all warehouses
  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _apiService.get(ApiConstants.WAREHOUSES_PATH);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final warehousesData = data['warehouses'] as List;
        return warehousesData
            .map((json) => Warehouse.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch warehouses');
      }
    } catch (e) {
      print('Get warehouses error: $e');
      rethrow;
    }
  }

  /// Create new warehouse
  Future<Warehouse> createWarehouse(String name) async {
    try {
      final response = await _apiService.post(
        ApiConstants.WAREHOUSES_PATH,
        data: {'name': name},
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return Warehouse.fromJson(data['warehouse'] as Map<String, dynamic>);
        } else {
          throw Exception(data['message'] ?? 'Failed to create warehouse');
        }
      } else {
        throw Exception('Failed to create warehouse');
      }
    } catch (e) {
      print('Create warehouse error: $e');
      rethrow;
    }
  }

  /// Update warehouse
  Future<bool> updateWarehouse(String id, String name) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.WAREHOUSES_PATH}/$id',
        data: {'name': name},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == true;
      } else {
        throw Exception('Failed to update warehouse');
      }
    } catch (e) {
      print('Update warehouse error: $e');
      rethrow;
    }
  }

  /// Delete warehouse
  Future<bool> deleteWarehouse(String id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.WAREHOUSES_PATH}/$id',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == true;
      } else {
        throw Exception('Failed to delete warehouse');
      }
    } catch (e) {
      print('Delete warehouse error: $e');
      rethrow;
    }
  }

  // ============ CATEGORIES ============

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiService.get(ApiConstants.CATEGORIES_PATH);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final categoriesData = data['categories'];

        // Handle null or empty response
        if (categoriesData == null || categoriesData is! List) {
          return [];
        }

        return categoriesData
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch categories');
      }
    } catch (e) {
      print('Get categories error: $e');
      rethrow;
    }
  }

  /// Create new category
  Future<Category> createCategory(String name, [String? description]) async {
    try {
      final response = await _apiService.post(
        ApiConstants.CATEGORIES_PATH,
        data: {
          'category_name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return Category.fromJson(data['category'] as Map<String, dynamic>);
        } else {
          throw Exception(data['message'] ?? 'Failed to create category');
        }
      } else {
        throw Exception('Failed to create category');
      }
    } catch (e) {
      print('Create category error: $e');
      rethrow;
    }
  }

  /// Update category
  Future<bool> updateCategory(String id, String name,
      [String? description]) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.CATEGORIES_PATH}/$id',
        data: {
          'category_name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == true;
      } else {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      print('Update category error: $e');
      rethrow;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.CATEGORIES_PATH}/$id',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == true;
      } else {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      print('Delete category error: $e');
      rethrow;
    }
  }

  // ============ BRANDS ============

  /// Get all brands
  Future<List<Brand>> getBrands() async {
    try {
      final response = await _apiService.get(ApiConstants.BRANDS_PATH);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final brandsData = data['brands'];

        // Handle null or empty response
        if (brandsData == null || brandsData is! List) {
          return [];
        }

        return brandsData
            .map((json) => Brand.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch brands');
      }
    } catch (e) {
      print('Get brands error: $e');
      rethrow;
    }
  }

  /// Create new brand
  Future<Brand> createBrand(String name, [String? description]) async {
    try {
      final response = await _apiService.post(
        ApiConstants.BRANDS_PATH,
        data: {
          'brand_name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return Brand.fromJson(data['brand'] as Map<String, dynamic>);
        } else {
          throw Exception(data['message'] ?? 'Failed to create brand');
        }
      } else {
        throw Exception('Failed to create brand');
      }
    } catch (e) {
      print('Create brand error: $e');
      rethrow;
    }
  }

  /// Update brand
  Future<bool> updateBrand(String id, String name,
      [String? description]) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.BRANDS_PATH}/$id',
        data: {
          'brand_name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == true;
      } else {
        throw Exception('Failed to update brand');
      }
    } catch (e) {
      print('Update brand error: $e');
      rethrow;
    }
  }

  /// Delete brand
  Future<bool> deleteBrand(String id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.BRANDS_PATH}/$id',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == true;
      } else {
        throw Exception('Failed to delete brand');
      }
    } catch (e) {
      print('Delete brand error: $e');
      rethrow;
    }
  }
}

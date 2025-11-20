import 'dart:io';
import 'package:dio/dio.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/services/api_service.dart';
import 'package:inventory_user/utils/api_constants.dart';

/// Product API Service
/// 
/// Handles all product-related API calls:
/// - Get products (paginated)
/// - Get products by warehouse
/// - Create product
/// - Update product
/// - Delete product
/// - Update product images
/// - Shift product between warehouses
/// - Get warehouses, categories, brands
class ProductApiService {
  final ApiService _apiService = ApiService();
  
  // ============ PRODUCT CRUD ============
  
  /// Get paginated products
  /// 
  /// [page] - Page number (starts from 1)
  /// Returns products list and pagination info
  Future<Map<String, dynamic>> getProducts(int page) async {
    try {
      final response = await _apiService.get(
        ApiConstants.productsPagePath(page),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch products');
      }
    } catch (e) {
      print('Get products error: $e');
      rethrow;
    }
  }
  
  /// Get products by warehouse ID
  Future<List<Product>> getProductsByWarehouse(int warehouseId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.productsByWarehousePath(warehouseId),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          final productsData = data['data'] as List;
          return productsData
              .map((json) => Product.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch products');
        }
      } else {
        throw Exception('Failed to fetch products by warehouse');
      }
    } catch (e) {
      print('Get products by warehouse error: $e');
      rethrow;
    }
  }
  
  /// Create new product (without images)
  /// 
  /// [productData] - Product information
  /// Returns created product data including the new product ID
  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.PRODUCTS_PATH,
        data: productData,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to create product');
        }
      } else {
        throw Exception('Failed to create product');
      }
    } catch (e) {
      print('Create product error: $e');
      rethrow;
    }
  }
  
  /// Update product information
  /// 
  /// [id] - Product ID
  /// [productData] - Updated product information
  Future<Map<String, dynamic>> updateProduct(
    int id,
    Map<String, dynamic> productData,
  ) async {
    try {
      // Use PUT request with JSON data (not FormData)
      final response = await _apiService.put(
        ApiConstants.productByIdPath(id),
        data: productData,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to update product');
        }
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      print('Update product error: $e');
      rethrow;
    }
  }
  
  /// Upload product images
  /// 
  /// [productId] - Product ID
  /// [imageFiles] - Image files to upload
  Future<Map<String, dynamic>> uploadProductImages(
    int productId,
    List<File> imageFiles,
  ) async {
    try {
      if (imageFiles.isEmpty) {
        return {
          'status': true,
          'message': 'No images to upload',
        };
      }

      final formData = FormData();
      
      // Add image files (backend expects 'images' field name)
      for (var imageFile in imageFiles) {
        final multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        );
        formData.files.add(MapEntry('images', multipartFile));
      }
      
      final response = await _apiService.uploadFile(
        ApiConstants.uploadProductImagesPath(productId),
        formData,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to upload images');
        }
      } else {
        throw Exception('Failed to upload product images');
      }
    } catch (e) {
      print('Upload product images error: $e');
      rethrow;
    }
  }
  
  /// Delete product
  Future<bool> deleteProduct(int id) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.productByIdPath(id),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == true;
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      print('Delete product error: $e');
      rethrow;
    }
  }
  
  /// Delete product image
  /// 
  /// [imageId] - Image ID to delete
  Future<bool> deleteProductImage(int imageId) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.deleteProductImagePath(imageId),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == true;
      } else {
        throw Exception('Failed to delete image');
      }
    } catch (e) {
      print('Delete image error: $e');
      rethrow;
    }
  }
  
  // ============ PRODUCT SHIFTING ============
  
  /// Shift product between warehouses
  Future<Map<String, dynamic>> shiftProduct({
    required int fromWarehouseId,
    required int toWarehouseId,
    required int productId,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.PRODUCT_SHIFT_PATH,
        data: {
          'from_warehouse_id': fromWarehouseId,
          'to_warehouse_id': toWarehouseId,
          'product_ids[]': productId,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to shift product');
        }
      } else {
        throw Exception('Failed to shift product');
      }
    } catch (e) {
      print('Shift product error: $e');
      rethrow;
    }
  }
  
  // ============ MASTER DATA ============
  
  /// Get all warehouses
  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _apiService.get(ApiConstants.WAREHOUSES_PATH);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final warehousesData = data['data'] as List?;
        if (warehousesData == null) {
          return [];
        }
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
  
  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiService.get(ApiConstants.CATEGORIES_PATH);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final categoriesData = data['data'] as List?;
        if (categoriesData == null) {
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
  
  /// Get all brands
  Future<List<Brand>> getBrands() async {
    try {
      final response = await _apiService.get(ApiConstants.BRANDS_PATH);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final brandsData = data['data'] as List?;
        if (brandsData == null) {
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
}

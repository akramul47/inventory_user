import 'package:dio/dio.dart';
import 'package:inventory_user/services/api_service.dart';
import 'package:inventory_user/utils/api_constants.dart';

/// Report API Service
/// 
/// Handles all reporting and import/export API calls:
/// - Shifting reports
/// - Sales reports
/// - Export products to CSV
/// - Import products from CSV
class ReportApiService {
  final ApiService _apiService = ApiService();
  
  // ============ REPORTS ============
  
  /// Get product shifting report
  /// 
  /// [startDate] - Report start date (yyyy-MM-dd)
  /// [endDate] - Report end date (yyyy-MM-dd)
  /// [warehouseId] - Optional warehouse filter
  /// [brandId] - Optional brand filter
  /// [categoryId] - Optional category filter
  Future<Map<String, dynamic>> getShiftingReport({
    required String startDate,
    required String endDate,
    int? warehouseId,
    int? brandId,
    int? categoryId,
  }) async {
    try {
      final queryParams = {
        'starting_date': startDate,
        'ending_date': endDate,
      };
      
      if (warehouseId != null) {
        queryParams['warehouse_id'] = warehouseId.toString();
      }
      if (brandId != null) {
        queryParams['brand_id'] = brandId.toString();
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }
      
      final response = await _apiService.get(
        ApiConstants.SHIFTING_REPORT_PATH,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch report');
        }
      } else {
        throw Exception('Failed to fetch shifting report');
      }
    } catch (e) {
      print('Get shifting report error: $e');
      rethrow;
    }
  }
  
  /// Get sales report
  /// 
  /// [startDate] - Report start date (yyyy-MM-dd)
  /// [endDate] - Report end date (yyyy-MM-dd)
  /// [warehouseId] - Optional warehouse filter
  /// [brandId] - Optional brand filter
  /// [categoryId] - Optional category filter
  Future<Map<String, dynamic>> getSalesReport({
    required String startDate,
    required String endDate,
    int? warehouseId,
    int? brandId,
    int? categoryId,
  }) async {
    try {
      final queryParams = {
        'starting_date': startDate,
        'ending_date': endDate,
      };
      
      if (warehouseId != null) {
        queryParams['warehouse_id'] = warehouseId.toString();
      }
      if (brandId != null) {
        queryParams['brand_id'] = brandId.toString();
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }
      
      final response = await _apiService.get(
        ApiConstants.SALES_REPORT_PATH,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch report');
        }
      } else {
        throw Exception('Failed to fetch sales report');
      }
    } catch (e) {
      print('Get sales report error: $e');
      rethrow;
    }
  }
  
  // ============ IMPORT/EXPORT ============
  
  /// Export products to CSV
  /// 
  /// [warehouseId] - Optional - export only specific warehouse products
/// Returns CSV download URL
  Future<String> exportProducts({int? warehouseId}) async {
    try {
      final String endpoint = warehouseId != null
          ? ApiConstants.exportByWarehousePath(warehouseId)
          : ApiConstants.EXPORT_PATH;
      
      final data = warehouseId != null ? {'id': warehouseId} : {};
      
      final response = await _apiService.post(
        endpoint,
        data: data,
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['status'] == true) {
          return responseData['url'] as String;
        } else {
          throw Exception(responseData['message'] ?? 'Failed to export');
        }
      } else {
        throw Exception('Failed to export products');
      }
    } catch (e) {
      print('Export products error: $e');
      rethrow;
    }
  }
  
  /// Import products from CSV
  /// 
  /// [csvData] - Parsed CSV data as list of maps
  Future<Map<String, dynamic>> importProducts(
    List<Map<String, dynamic>> csvData,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.IMPORT_PATH,
        data: csvData,
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['status'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to import');
        }
      } else {
        throw Exception('Failed to import products');
      }
    } catch (e) {
      print('Import products error: $e');
      rethrow;
    }
  }
  
  /// Download file from URL
  /// 
  /// [url] - File URL
  /// [savePath] - Local path to save the file
  Future<void> downloadFile(String url, String savePath) async {
    try {
      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );
    } catch (e) {
      print('Download file error: $e');
      rethrow;
    }
  }
}

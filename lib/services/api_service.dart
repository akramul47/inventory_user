import 'package:dio/dio.dart';
import 'package:inventory_user/utils/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base API Service using Dio
/// 
/// Provides centralized HTTP client with:
/// - Automatic token injection
/// - Timeout configuration
/// - Error handling
/// - Request/response logging
class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.BASE_URL,
        connectTimeout: const Duration(milliseconds: ApiConstants.CONNECTION_TIMEOUT),
        receiveTimeout: const Duration(milliseconds: ApiConstants.RECEIVE_TIMEOUT),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Inject token for authenticated requests
          final token = await _getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // Log request
          print('🌐 REQUEST: ${options.method} ${options.path}');
          print('📦 DATA: ${options.data}');
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response
          print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Log error
          print('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('📛 MESSAGE: ${error.message}');
          
          // Handle token expiration
          if (error.response?.statusCode == 401) {
            await _handleUnauthorized();
          }
          
          return handler.next(error);
        },
      ),
    );
  }
  
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
  
  Future<void> _handleUnauthorized() async {
    // Clear token and redirect to login
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    print('🔒 Token expired - user logged out');
  }
  
  // ============ HTTP METHODS ============
  
  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Upload file (multipart)
  Future<Response> uploadFile(
    String path,
    FormData formData, {
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // ============ ERROR HANDLING ============
  
  Exception _handleError(DioException error) {
    String errorMessage = 'An error occurred';
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        break;
        
      case DioExceptionType.badResponse:
        errorMessage = _handleHttpError(error.response?.statusCode, error.response?.data);
        break;
        
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
        
      case DioExceptionType.unknown:
        errorMessage = 'Network error. Please check your connection.';
        break;
        
      default:
        errorMessage = error.message ?? 'Unknown error occurred';
    }
    
    return Exception(errorMessage);
  }
  
  String _handleHttpError(int? statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        return responseData?['message'] ?? 'Bad request';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Resource not found';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return responseData?['message'] ?? 'An error occurred';
    }
  }
}

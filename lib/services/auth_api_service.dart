import 'package:dio/dio.dart';
import 'package:inventory_user/services/api_service.dart';
import 'package:inventory_user/utils/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication API Service
///
/// Handles all authentication-related API calls:
/// - Email/password login
/// - Google OAuth login
/// - Logout
/// - Get current user info
class AuthApiService {
  final ApiService _apiService = ApiService();

  /// Login with email and password
  ///
  /// Returns user data and token on success
  /// Throws Exception on failure
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.LOGIN_PATH,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        // Save token and user data to local storage
        await _saveAuthData(responseData);

        return responseData;
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Register new user
  ///
  /// Returns user data and token on success
  /// Throws Exception on failure
  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConstants.REGISTER_PATH,
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        // Save token and user data to local storage
        await _saveAuthData(responseData);

        return responseData;
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  /// Login with Google OAuth
  ///
  /// [idToken] - Google ID token from Google Sign-In
  /// Returns user data and token on success
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await _apiService.post(
        ApiConstants.LOGIN_GOOGLE_PATH,
        data: {
          'id_token': idToken,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        // Save token and user data to local storage
        await _saveAuthData(responseData);

        return responseData;
      } else {
        throw Exception('Google login failed');
      }
    } catch (e) {
      print('Google login error: $e');
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Call logout endpoint (optional - for server-side session cleanup)
      await _apiService.post(ApiConstants.LOGOUT_PATH);
    } catch (e) {
      print('Logout API error: $e');
      // Continue with local logout even if API fails
    } finally {
      // Clear local auth data
      await _clearAuthData();
    }
  }

  /// Get current authenticated user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiService.get(ApiConstants.ME_PATH);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get user info');
      }
    } catch (e) {
      print('Get current user error: $e');
      rethrow;
    }
  }

  /// Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Save authentication data to local storage
  Future<void> _saveAuthData(Map<String, dynamic> responseData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save token
    final token = responseData['token'] ?? responseData['user']?['jwt_token'];
    if (token != null) {
      await prefs.setString('token', token);
    }

    // Save user data
    final user = responseData['user'];
    if (user != null) {
      if (user['email'] != null) {
        await prefs.setString('email', user['email']);
      }
      if (user['name'] != null) {
        await prefs.setString('name', user['name']);
      }
      if (user['get_role']?['role'] != null) {
        await prefs.setString('role', user['get_role']['role']);
      } else if (user['role'] != null) {
        await prefs.setString('role', user['role']);
      }
      if (user['img'] != null || user['profile_image'] != null) {
        final imageUrl = user['img'] ?? user['profile_image'];
        await prefs.setString('imageUrl', imageUrl);
      }
      if (user['google_id'] != null) {
        await prefs.setString('google_id', user['google_id']);
      }
    }
  }

  /// Clear all authentication data from local storage
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('email');
    await prefs.remove('name');
    await prefs.remove('role');
    await prefs.remove('imageUrl');
    await prefs.remove('google_id');
  }
}

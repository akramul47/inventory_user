import 'package:flutter/material.dart';
import 'package:inventory_user/main.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/services/auth_api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _authApiService = AuthApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoggedIn;
  String? _userRole; // 'admin' or 'user'

  AuthProvider(this._isLoggedIn);

  bool get isLoggedIn => _isLoggedIn;
  String? get userRole => _userRole;
  bool get isAdmin => _userRole == 'admin';

  Future<void> updateLoginStatus(bool status) async {
    _isLoggedIn = status;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
      final String? role = prefs.getString('userRole');
      _isLoggedIn = loggedIn;
      _userRole = role;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Set user role (used during app initialization)
  void setRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  /// Login with email and password
  Future<void> login(String email, String password,
      {bool isAdmin = false}) async {
    try {
      await _authApiService.login(email, password);

      // Save role
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String role = isAdmin ? 'admin' : 'user';
      await prefs.setString('userRole', role);
      _userRole = role;

      await updateLoginStatus(true);
    } catch (e) {
      print('Login failed: $e');
      rethrow;
    }
  }

  /// Register with name, email and password
  Future<void> register(String name, String email, String password) async {
    try {
      await _authApiService.register(name, email, password);
      await updateLoginStatus(true);
    } catch (e) {
      print('Registration failed: $e');
      rethrow;
    }
  }

  /// Login with Google
  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return;
      }

      // Get Google authentication
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send ID token to backend
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      await _authApiService.loginWithGoogle(idToken);
      await updateLoginStatus(true);
    } catch (e) {
      print('Google login failed: $e');
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Clear SharedPreferences data
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Logout from backend
      await _authApiService.logout();

      // Sign out from Google if logged in with Google (only on supported platforms)
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (e) {
        // Google Sign-In not available on this platform (e.g., Windows)
        print('Google Sign-In not available: $e');
      }

      // Clear product-related data
      final ProductProvider productProvider = Provider.of<ProductProvider>(
          navigatorKey.currentContext!,
          listen: false);
      productProvider.clearAllData();
      productProvider.resetCurrentPage();

      // Update login status
      await updateLoginStatus(false);

      // Set _isLoggedIn to false
      _isLoggedIn = false;

      // Notify listeners after logout
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
      // Still mark as logged out locally even if API call fails
      _isLoggedIn = false;
      notifyListeners();
    }
  }
}

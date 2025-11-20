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

  AuthProvider(this._isLoggedIn);

  bool get isLoggedIn => _isLoggedIn;

  Future<void> updateLoginStatus(bool status) async {
    _isLoggedIn = status;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
      _isLoggedIn = loggedIn;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    try {
      await _authApiService.login(email, password);
      await updateLoginStatus(true);
    } catch (e) {
      print('Login failed: $e');
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
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
      
      // Sign out from Google if logged in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
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
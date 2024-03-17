import 'package:flutter/material.dart';
import 'package:inventory_user/main.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn;

  AuthProvider(this._isLoggedIn);

  bool get isLoggedIn => _isLoggedIn;

  Future<void> login(String email, String password) async {
    try {
      await AuthService.login(email, password);
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      // Handle login failure
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Clear SharedPreferences data
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Remove the token from local storage
      await AuthService.removeToken();

      // Navigate to the login page
      navigatorKey.currentState?.pushReplacementNamed('/login');

      // Set _isLoggedIn to false
      _isLoggedIn = false;

      // Notify listeners after logout
      notifyListeners();
    } catch (e) {
      // Handle logout failure
      rethrow;
    }
  }
}

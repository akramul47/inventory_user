import 'package:flutter/material.dart';
import 'package:inventory_user/main.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product_provider.dart';

class AuthProvider extends ChangeNotifier {
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

  Future<void> login(String email, String password) async {
    try {
      await AuthService.login(email, password);
      await updateLoginStatus(true);
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
      // Handle logout failure
      rethrow;
    }
  }
}
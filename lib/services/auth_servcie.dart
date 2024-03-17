import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String baseUrl =
      'https://warehouse.z8tech.one/Backend/public/api';

  static Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final Uri apiUrl = Uri.parse('$baseUrl/jwt/login');
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final Map<String, String> body = {
      'email': email,
      'password': password,
    };

    final http.Response response = await http.post(
      apiUrl,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['user']['jwt_token']);
      prefs.setString('role', responseData['user']['get_role']['role']);
      prefs.setString('email', responseData['user']['email']);
      if (responseData['user']['img'] != null) {
        prefs.setString('imageUrl', responseData['user']['img']);
      }

      return responseData;
    } else {
      throw Exception('Failed to login');
    }
  }

  static Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}

import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/screens/home_screen.dart';
import 'package:inventory_user/widgets/gradient_button.dart';
import 'package:inventory_user/widgets/login_field.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    setState(() => isLoading = true);

    try {
      final authService = Provider.of<AuthProvider>(context, listen: false);
      await authService.login(emailController.text, passwordController.text);

      // Navigate to home page on successful login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Inventory+'),
        ),
      );
    } catch (e) {
      // Handle login error
      // print('Login Error: $e');

      // Show error dialog or message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please try again.'),
          backgroundColor: Pallete.borderColor,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _handleLogin() {
    if (!isLoading) {
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center content horizontally
            children: [
              // Spacing
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
              ),
              // Logo section
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(
                  'assets/logo.jpeg', height: 70, width: 400, // logo path
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              // Login fields
              LoginField(
                hintText: 'Email',
                controller: emailController,
              ),
              const SizedBox(height: 15),
              LoginField(
                hintText: 'Password',
                controller: passwordController,
                obscureText: true,
              ),

              const SizedBox(height: 20),

              // Gradient button
              GradientButton(
                isLoading: isLoading,
                onPressed: _handleLogin,
              ),

              const SizedBox(height: 40), // Additional spacing at bottom
            ],
          ),
        ),
      ),
    );
  }
}

class Pallete {
  static const Color backgroundColor = Color.fromRGBO(24, 24, 32, 1);
  static const Color gradient1 = Color.fromRGBO(187, 63, 221, 1);
  static const Color gradient2 = Color.fromRGBO(251, 109, 169, 1);
  static const Color gradient3 = Color.fromRGBO(255, 159, 124, 1);
  static const Color borderColor = Color(0xFFCE1126);
  static const Color whiteColor = Colors.white;
}

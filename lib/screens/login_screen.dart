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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we're on a larger screen
            final isLargeScreen = constraints.maxWidth > 600;
            
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 40.0 : 20.0,
                  vertical: 20.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 500 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Spacing - adaptive based on screen size
                      SizedBox(
                        height: isLargeScreen 
                            ? 40 
                            : MediaQuery.of(context).size.height * 0.1,
                      ),
                      
                      // Logo section - centered and responsive
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Image.asset(
                            'assets/logo.jpeg',
                            height: isLargeScreen ? 100 : 70,
                            width: isLargeScreen ? 500 : 400,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isLargeScreen ? 50 : 30),
                      
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

                      SizedBox(height: isLargeScreen ? 60 : 40),
                    ],
                  ),
                ),
              ),
            );
          },
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

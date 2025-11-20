import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/screens/home_screen.dart';
import 'package:inventory_user/utils/pallete.dart';
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
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  bool _isLogin = true; // Toggle between Login and Signup
  bool _isAdmin = false; // Toggle between User and Admin

  Future<void> _authenticate() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (!_isLogin && nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isLogin) {
        // Login Logic
        if (_isAdmin) {
          // Admin Login - For now, same as user login but we could add specific checks
          // or redirect to a different dashboard
          await authProvider.login(
              emailController.text, passwordController.text);
          // Check role if needed, but for now assume success means access
          // In real app, check if user.role == 'admin'
        } else {
          // User Login
          await authProvider.login(
              emailController.text, passwordController.text);
        }
      } else {
        // Registration Logic (User only, Admins usually created by other admins)
        if (_isAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin registration is restricted')),
          );
          return;
        }
        await authProvider.register(
            nameController.text, emailController.text, passwordController.text);
      }

      if (!mounted) return;

      // Navigate based on role/mode
      if (_isAdmin) {
        // Navigate to Admin Dashboard (to be implemented)
        // For now, just go to Home but show a message
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Inventory+ Admin'),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Inventory+'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin
              ? 'Login failed. Check credentials.'
              : 'Registration failed. Try again.'),
          backgroundColor: Pallete.borderColor,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                      // Admin Toggle (Top Right or Center)
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isAdmin = !_isAdmin;
                              // If switching to admin, force login mode
                              if (_isAdmin) _isLogin = true;
                            });
                          },
                          icon: Icon(
                            _isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person_outline,
                            color: _isAdmin ? Pallete.gradient2 : Colors.grey,
                          ),
                          label: Text(
                            _isAdmin ? 'Admin Mode' : 'User App',
                            style: TextStyle(
                              color: _isAdmin ? Pallete.gradient2 : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: isLargeScreen
                            ? 20
                            : MediaQuery.of(context).size.height * 0.05,
                      ),

                      // Logo
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

                      SizedBox(height: isLargeScreen ? 40 : 20),

                      // Title
                      Text(
                        _isAdmin
                            ? 'Admin Portal'
                            : (_isLogin ? 'Welcome Back' : 'Create Account'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Pallete.whiteColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      // Name Field (Signup only)
                      if (!_isLogin) ...[
                        LoginField(
                          hintText: 'Full Name',
                          controller: nameController,
                        ),
                        const SizedBox(height: 15),
                      ],

                      // Email Field
                      LoginField(
                        hintText: 'Email',
                        controller: emailController,
                      ),
                      const SizedBox(height: 15),

                      // Password Field
                      LoginField(
                        hintText: 'Password',
                        controller: passwordController,
                        obscureText: true,
                      ),

                      const SizedBox(height: 20),

                      // Action Button
                      GradientButton(
                        isLoading: isLoading,
                        onPressed: _authenticate,
                        text: _isLogin ? 'Sign In' : 'Sign Up',
                      ),

                      const SizedBox(height: 20),

                      // Toggle Login/Signup
                      if (!_isAdmin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin ? 'Sign Up' : 'Sign In',
                                style: const TextStyle(
                                  color: Pallete.gradient2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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

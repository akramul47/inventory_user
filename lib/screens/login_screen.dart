import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/screens/home_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Start loading state
                      setState(() => isLoading = true);

                      // Attempt login
                      try {
                        final authService =
                            Provider.of<AuthProvider>(context, listen: false);
                        await authService.login(
                            emailController.text, passwordController.text);

                        // Navigate to home page on successful login
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const MyHomePage(title: 'Inventory+')),
                        );
                      } catch (e) {
                        // Handle login error
                        print('Login Error: $e');
                        // Show error dialog or message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Login failed. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        // Stop loading state
                        setState(() => isLoading = false);
                      }
                    },
              child: const Text('Login'),
            ),
            if (isLoading)
              const CircularProgressIndicator(), // Show loading indicator
          ],
        ),
      ),
    );
  }
}

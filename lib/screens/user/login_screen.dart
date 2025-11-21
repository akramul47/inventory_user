import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/screens/admin/admin_dashboard_screen.dart';
import 'package:inventory_user/screens/user/home_screen.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:inventory_user/widgets/login_field.dart';
import 'package:inventory_user/widgets/gradient_button.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;
  bool _isLogin = true;
  bool _isAdmin = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    if (!_isLogin && nameController.text.isEmpty) {
      _showSnackBar('Please enter your name', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isLogin) {
        await authProvider.login(
          emailController.text.trim(),
          passwordController.text,
          isAdmin: _isAdmin,
        );
      } else {
        if (_isAdmin) {
          _showSnackBar('Admin registration is restricted', isError: true);
          setState(() => isLoading = false);
          return;
        }
        await authProvider.register(
          nameController.text.trim(),
          emailController.text.trim(),
          passwordController.text,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => _isAdmin
              ? const AdminDashboardScreen()
              : const MyHomePage(title: 'Inventory+'),
        ),
      );
    } catch (e) {
      _showSnackBar(
        _isLogin
            ? 'Login failed. Check credentials.'
            : 'Registration failed. Try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    Colors.white,
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 60.0 : 24.0,
                vertical: 20.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isLargeScreen ? 480 : double.infinity,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and Title Section
                        _buildHeader(isDark),

                        SizedBox(height: isLargeScreen ? 50 : 40),

                        // User/Admin Toggle
                        _buildModeSelector(isDark),

                        const SizedBox(height: 32),

                        // Form Card
                        _buildFormCard(isDark, isLargeScreen),

                        const SizedBox(height: 24),

                        // Toggle Login/Signup
                        if (!_isAdmin) _buildAuthToggle(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // App Title
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Pallete.gradient1, Pallete.gradient2],
          ).createShader(bounds),
          child: const Text(
            'Inventory+',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Manage your inventory with ease',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: 'User',
              icon: Icons.person_rounded,
              isSelected: !_isAdmin,
              onTap: () {
                setState(() => _isAdmin = false);
              },
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeButton(
              label: 'Admin',
              icon: Icons.admin_panel_settings_rounded,
              isSelected: _isAdmin,
              onTap: () {
                setState(() {
                  _isAdmin = true;
                  _isLogin = true; // Force login mode for admin
                });
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [Pallete.gradient1, Pallete.gradient2],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Pallete.gradient2.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isDark, bool isLargeScreen) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(isLargeScreen ? 40 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Text
          Text(
            _isAdmin
                ? 'Admin Portal'
                : (_isLogin ? 'Welcome Back!' : 'Create Account'),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            _isAdmin
                ? 'Sign in to access admin dashboard'
                : (_isLogin
                    ? 'Sign in to continue'
                    : 'Fill in the details to get started'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Name Field (Signup only)
          if (!_isLogin) ...[
            LoginField(
              hintText: 'Full Name',
              controller: nameController,
            ),
            const SizedBox(height: 12),
          ],

          // Email Field
          LoginField(
            hintText: 'Email',
            controller: emailController,
          ),

          const SizedBox(height: 12),

          // Password Field
          LoginField(
            hintText: 'Password',
            controller: passwordController,
            obscureText: true,
            onFieldSubmitted: _authenticate,
          ),

          const SizedBox(height: 24),

          // Submit Button
          GradientButton(
            isLoading: isLoading,
            onPressed: _authenticate,
            text: _isLogin ? 'Sign In' : 'Sign Up',
          ),
        ],
      ),
    );
  }

  Widget _buildAuthToggle(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isLogin = !_isLogin),
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: TextStyle(
              color: Pallete.gradient2,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

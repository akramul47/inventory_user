import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/screens/add_item.dart';
import 'package:inventory_user/screens/dashboard/admin_dashboard_screen.dart';
import 'package:inventory_user/screens/home_screen.dart';
import 'package:inventory_user/screens/login_screen.dart';
import 'package:inventory_user/services/auth_api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Check if the user is already logged in and get their role
  bool isLoggedIn = await AuthApiService().isUserLoggedIn();

  // Load user role from SharedPreferences
  String? userRole;
  if (isLoggedIn) {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString('userRole');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = AuthProvider(isLoggedIn);
            // Set the loaded role
            if (userRole != null) {
              provider.setRole(userRole);
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp({Key? key, required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Inventory+',
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: ThemeMode.system,
          home: authProvider.isLoggedIn
              ? (authProvider.isAdmin
                  ? const AdminDashboardScreen()
                  : const MyHomePage(title: 'Inventory+'))
              : const LoginPage(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/add_item': (context) => const AddItemPage(),
            // Define other routes as needed
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/screens/add_item.dart';
import 'package:inventory_user/screens/home_screen.dart';
import 'package:inventory_user/screens/login_screen.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:provider/provider.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the user is already logged in
  bool isLoggedIn = await AuthService.isUserLoggedIn();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(isLoggedIn)),
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
              ? const MyHomePage(title: 'Inventory+')
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

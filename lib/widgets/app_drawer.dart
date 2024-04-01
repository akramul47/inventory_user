import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/screens/report_screen.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/export_import_screen.dart';

class AppDrawer extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AppDrawer({Key? key, required this.navigatorKey}) : super(key: key);

  void _handleLogout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    // Ensure that the navigation occurs after the logout
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Pallete.primaryRed,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String?>(
                    future: SharedPreferences.getInstance()
                        .then((prefs) => prefs.getString('imageUrl')),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return CircleAvatar(
                          backgroundImage: NetworkImage(snapshot.data!),
                        );
                      } else {
                        return const CircleAvatar(
                          backgroundImage: AssetImage('assets/gamer.png'),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<String?>(
                    future: SharedPreferences.getInstance()
                        .then((prefs) => prefs.getString('role')),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return const Text(
                          'Role Not Found',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    },
                  ),
                  FutureBuilder<String?>(
                    future: SharedPreferences.getInstance()
                        .then((prefs) => prefs.getString('email')),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        );
                      } else {
                        return const Text(
                          'Email Not Found',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            _buildListTile(Icons.import_export_outlined, 'Import/Export', () {
              // Close the drawer
              Navigator.of(context).pop();

              // Navigate to the ExportImportPage
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExportImportPage()),
              );
            }),
            _buildListTile(Icons.file_copy, 'Report', () {
              // Close the drawer
              Navigator.of(context).pop();

              // Navigate to the ExportImportPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportPage(),
                ),
              );
            }),
            // _buildListTile(Icons.ios_share_outlined, 'Export', () {}),
            _buildListTile(Icons.settings, 'Settings', () {
              // Settings page logic here
            }),
            _buildListTile(Icons.help, 'Help', () {
              // Help page logic here
            }),
            const Divider(),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, Function()? onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout_outlined),
      title: const Text('Sign Out'),
      onTap: () => _handleLogout(context),
    );
  }
}

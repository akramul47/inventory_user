import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
              decoration: BoxDecoration(
                color: Colors.redAccent[200],
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
                        return CircleAvatar(
                          backgroundImage: AssetImage('assets/gamer.png'),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  FutureBuilder<String?>(
                    future: SharedPreferences.getInstance()
                        .then((prefs) => prefs.getString('role')),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          snapshot.data!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return Text(
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
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        );
                      } else {
                        return Text(
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
            _buildListTile(Icons.import_export_outlined, 'Import', () {}),
            _buildListTile(Icons.ios_share_outlined, 'Export', () {}),
            _buildListTile(Icons.settings, 'Settings', () {
              // Settings page logic here
            }),
            _buildListTile(Icons.help, 'Help', () {
              // Help page logic here
            }),
            Divider(),
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
      leading: Icon(Icons.logout_outlined),
      title: Text('Sign Out'),
      onTap: () => _handleLogout(context),
    );
  }
}

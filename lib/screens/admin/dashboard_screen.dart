import 'package:flutter/material.dart';
import 'package:inventory_user/providers/auth_provider.dart';
import 'package:inventory_user/screens/admin/product_management_screen.dart';
import 'package:inventory_user/screens/user/login_screen.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<Widget> _screens = [
    const ProductManagementScreen(),
    const Center(
        child: Text('Orders (Coming Soon)',
            style: TextStyle(color: Colors.white))),
    const Center(
        child:
            Text('Users (Coming Soon)', style: TextStyle(color: Colors.white))),
    const Center(
        child: Text('Settings (Coming Soon)',
            style: TextStyle(color: Colors.white))),
  ];

  final List<String> _titles = [
    'Product Management',
    'Orders',
    'Users',
    'Settings',
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          if (isLargeScreen) {
            return Row(
              children: [
                // Sidebar
                NavigationRail(
                  backgroundColor: const Color(0xFF1E1E2C),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  extended: !_isSidebarCollapsed,
                  leading: Column(
                    children: [
                      const SizedBox(height: 20),
                      IconButton(
                        icon: Icon(
                          _isSidebarCollapsed ? Icons.menu : Icons.menu_open,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      if (!_isSidebarCollapsed)
                        const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined,
                          color: Colors.white70),
                      selectedIcon:
                          Icon(Icons.inventory_2, color: Pallete.gradient2),
                      label: Text('Products',
                          style: TextStyle(color: Colors.white)),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.shopping_cart_outlined,
                          color: Colors.white70),
                      selectedIcon:
                          Icon(Icons.shopping_cart, color: Pallete.gradient2),
                      label:
                          Text('Orders', style: TextStyle(color: Colors.white)),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline, color: Colors.white70),
                      selectedIcon:
                          Icon(Icons.people, color: Pallete.gradient2),
                      label:
                          Text('Users', style: TextStyle(color: Colors.white)),
                    ),
                    NavigationRailDestination(
                      icon:
                          Icon(Icons.settings_outlined, color: Colors.white70),
                      selectedIcon:
                          Icon(Icons.settings, color: Pallete.gradient2),
                      label: Text('Settings',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: IconButton(
                          icon:
                              const Icon(Icons.logout, color: Colors.redAccent),
                          onPressed: _logout,
                          tooltip: 'Logout',
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(
                    thickness: 1, width: 1, color: Colors.white10),
                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: const Color(0xFF1E1E2C),
                        child: Row(
                          children: [
                            Text(
                              _titles[_selectedIndex],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const CircleAvatar(
                              backgroundColor: Pallete.gradient2,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      // Content Body
                      Expanded(
                        child: _screens[_selectedIndex],
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Mobile Layout
            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFF1E1E2C),
                title: Text(_titles[_selectedIndex]),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _logout,
                  ),
                ],
              ),
              drawer: Drawer(
                backgroundColor: const Color(0xFF1E1E2C),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const DrawerHeader(
                      decoration: BoxDecoration(
                        color: Pallete.backgroundColor,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Pallete.gradient2,
                            child: Icon(Icons.admin_panel_settings,
                                size: 30, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Admin Panel',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.inventory_2, color: Colors.white70),
                      title: const Text('Products',
                          style: TextStyle(color: Colors.white)),
                      selected: _selectedIndex == 0,
                      selectedTileColor: Pallete.gradient2.withOpacity(0.1),
                      onTap: () {
                        _onDestinationSelected(0);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.shopping_cart,
                          color: Colors.white70),
                      title: const Text('Orders',
                          style: TextStyle(color: Colors.white)),
                      selected: _selectedIndex == 1,
                      selectedTileColor: Pallete.gradient2.withOpacity(0.1),
                      onTap: () {
                        _onDestinationSelected(1);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people, color: Colors.white70),
                      title: const Text('Users',
                          style: TextStyle(color: Colors.white)),
                      selected: _selectedIndex == 2,
                      selectedTileColor: Pallete.gradient2.withOpacity(0.1),
                      onTap: () {
                        _onDestinationSelected(2);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.settings, color: Colors.white70),
                      title: const Text('Settings',
                          style: TextStyle(color: Colors.white)),
                      selected: _selectedIndex == 3,
                      selectedTileColor: Pallete.gradient2.withOpacity(0.1),
                      onTap: () {
                        _onDestinationSelected(3);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              body: _screens[_selectedIndex],
            );
          }
        },
      ),
    );
  }
}

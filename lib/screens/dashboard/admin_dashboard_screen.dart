import 'package:flutter/material.dart';
import 'package:inventory_user/screens/dashboard/admin_overview_screen.dart';
import 'package:inventory_user/screens/dashboard/warehouse_management_screen.dart';
import 'package:inventory_user/screens/dashboard/category_management_screen.dart';
import 'package:inventory_user/screens/dashboard/brand_management_screen.dart';
import 'package:inventory_user/utils/pallete.dart';

/// Admin Dashboard Screen
/// Main container for admin panel with navigation to all admin sections
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
        AdminOverviewScreen(onNavigateToTab: _navigateToTab),
        const WarehouseManagementScreen(),
        const CategoryManagementScreen(),
        const BrandManagementScreen(),
      ];

  final List<String> _titles = const [
    'Admin Overview',
    'Warehouse Management',
    'Category Management',
    'Brand Management',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E2E),
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Pallete.gradient1,
                  Pallete.gradient2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Pallete.gradient2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Inventory Management',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Overview',
                  index: 0,
                ),
                _buildDrawerItem(
                  icon: Icons.warehouse,
                  title: 'Warehouses',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Categories',
                  index: 2,
                ),
                _buildDrawerItem(
                  icon: Icons.business_center,
                  title: 'Brands',
                  index: 3,
                ),
                const Divider(color: Colors.white24, height: 32),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Pallete.gradient2.withOpacity(0.2),
      leading: Icon(
        icon,
        color: isSelected ? Pallete.gradient2 : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Pallete.gradient2 : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // Close drawer
      },
    );
  }
}

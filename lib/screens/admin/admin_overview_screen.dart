import 'package:flutter/material.dart';
import 'package:inventory_user/screens/admin/warehouse_management_screen.dart';
import 'package:inventory_user/screens/admin/category_management_screen.dart';
import 'package:inventory_user/screens/admin/brand_management_screen.dart';
import 'package:inventory_user/services/master_data_api_service.dart';
import 'package:inventory_user/utils/pallete.dart';

/// Admin Overview Screen
/// Displays statistics and quick actions for the admin
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({Key? key}) : super(key: key);

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final MasterDataApiService _masterDataService = MasterDataApiService();

  bool _isLoading = true;
  int _warehouseCount = 0;
  int _categoryCount = 0;
  int _brandCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final warehouses = await _masterDataService.getWarehouses();
      final categories = await _masterDataService.getCategories();
      final brands = await _masterDataService.getBrands();

      setState(() {
        _warehouseCount = warehouses.length;
        _categoryCount = categories.length;
        _brandCount = brands.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Statistics Cards (Clickable)
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Pallete.gradient2),
                  ),
                ),
              )
            else
              _buildStatsGrid(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          icon: Icons.warehouse,
          title: 'Warehouses',
          value: _warehouseCount.toString(),
          color: const Color(0xFF3B82F6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WarehouseManagementScreen(),
              ),
            );
          },
        ),
        _buildStatCard(
          icon: Icons.category,
          title: 'Categories',
          value: _categoryCount.toString(),
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryManagementScreen(),
              ),
            );
          },
        ),
        _buildStatCard(
          icon: Icons.business_center,
          title: 'Brands',
          value: _brandCount.toString(),
          color: const Color(0xFFEC4899),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BrandManagementScreen(),
              ),
            );
          },
        ),
        _buildStatCard(
          icon: Icons.inventory_2,
          title: 'Products',
          value: 'N/A',
          color: const Color(0xFF10B981),
          onTap: null, // No action for products yet
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150, // Fixed height to avoid overflow
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

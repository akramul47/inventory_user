import 'package:flutter/material.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/widgets/modern_shimmer.dart';
import 'package:inventory_user/widgets/empty_state_widget.dart';
import 'package:provider/provider.dart';

class WarehouseListWidget extends StatefulWidget {
  const WarehouseListWidget({Key? key}) : super(key: key);

  @override
  State<WarehouseListWidget> createState() => _WarehouseListWidgetState();
}

class _WarehouseListWidgetState extends State<WarehouseListWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading (warehouse data should be loaded by provider)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final warehouses = productProvider.warehouses;

        // Show shimmer while loading
        if (_isLoading) {
          return const WarehouseListShimmer();
        }

        // Show empty state if no warehouses
        if (warehouses.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Warehouses',
            message: 'Start by adding warehouse locations to organize your inventory efficiently.',
            icon: Icons.warehouse_outlined,
          );
        }

        // Show warehouse list
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: warehouses.length,
          itemBuilder: (context, index) {
            final warehouse = warehouses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warehouse_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  warehouse.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

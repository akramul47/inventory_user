import 'package:flutter/material.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:provider/provider.dart';

class WarehouseListWidget extends StatelessWidget {
  const WarehouseListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final warehouses = productProvider.warehouses;

        if (warehouses.isEmpty) {
          // Show loading indicator or empty state if no warehouses are fetched yet
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView.builder(
          itemCount: warehouses.length,
          itemBuilder: (context, index) {
            final warehouse = warehouses[index];
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  warehouse.name,
                  style: TextStyle(
                    fontSize: 16, // Adjust font size as needed
                    fontWeight: FontWeight.bold, // Headline font weight
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

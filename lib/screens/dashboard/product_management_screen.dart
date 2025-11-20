import 'package:flutter/material.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/screens/dashboard/product_form_dialog.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:provider/provider.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      // Load master data first to ensure we can map IDs to names
      await Provider.of<ProductProvider>(context, listen: false)
          .fetchWarehouseCategoryBrand();
      await Provider.of<ProductProvider>(context, listen: false)
          .fetchProductsByPage(1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper to get category name
  String _getCategoryName(int categoryId) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    try {
      final category = provider.categories.firstWhere((c) => c.id == categoryId,
          orElse: () => Category(id: 0, name: 'Unknown'));
      return category.name;
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showAddEditProductDialog([Product? product]) async {
    await showDialog(
      context: context,
      builder: (context) => ProductFormDialog(product: product),
    );
    _loadProducts(); // Refresh list after dialog closes
  }

  void _deleteProduct(int id) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content:
                const Text('Are you sure you want to delete this product?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await Provider.of<ProductProvider>(context, listen: false)
            .deleteProduct(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting product: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditProductDialog(),
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
        backgroundColor: Pallete.gradient2,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (_isLoading && productProvider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No products found',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProducts,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Use DataTable for large screens, ListView for small
              if (constraints.maxWidth > 800) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    color: const Color(0xFF2A2D3E),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Product List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white70),
                                onPressed: _loadProducts,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          DataTable(
                            headingRowColor:
                                MaterialStateProperty.all(Colors.black12),
                            dataRowColor:
                                MaterialStateProperty.all(Colors.transparent),
                            columns: const [
                              DataColumn(
                                  label: Text('Image',
                                      style: TextStyle(color: Colors.white70))),
                              DataColumn(
                                  label: Text('Name',
                                      style: TextStyle(color: Colors.white70))),
                              DataColumn(
                                  label: Text('Category',
                                      style: TextStyle(color: Colors.white70))),
                              DataColumn(
                                  label: Text('Price',
                                      style: TextStyle(color: Colors.white70))),
                              DataColumn(
                                  label: Text('Stock',
                                      style: TextStyle(color: Colors.white70))),
                              DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(color: Colors.white70))),
                            ],
                            rows: productProvider.products.map((product) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        image: DecorationImage(
                                          image: NetworkImage(product
                                                  .images.isNotEmpty
                                              ? product.images.first.image
                                              : (product.imageUrl.isNotEmpty
                                                  ? product.imageUrl
                                                  : 'https://via.placeholder.com/40')),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(product.name,
                                      style: const TextStyle(
                                          color: Colors.white))),
                                  DataCell(Text(
                                      _getCategoryName(product.categoryId),
                                      style: const TextStyle(
                                          color: Colors.white70))),
                                  DataCell(Text('\$${product.retailPrice}',
                                      style: const TextStyle(
                                          color: Colors.white70))),
                                  DataCell(Text('${product.quantity}',
                                      style: const TextStyle(
                                          color: Colors.white70))),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blueAccent, size: 20),
                                        onPressed: () =>
                                            _showAddEditProductDialog(product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent, size: 20),
                                        onPressed: () =>
                                            _deleteProduct(product.id),
                                      ),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // Mobile ListView
                return ListView.builder(
                  itemCount: productProvider.products.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return Card(
                      color: const Color(0xFF2A2D3E),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            image: DecorationImage(
                              image: NetworkImage(product.images.isNotEmpty
                                  ? product.images.first.image
                                  : (product.imageUrl.isNotEmpty
                                      ? product.imageUrl
                                      : 'https://via.placeholder.com/50')),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${_getCategoryName(product.categoryId)} • \$${product.retailPrice}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert,
                              color: Colors.white70),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.edit,
                                      color: Colors.blue, size: 20),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ],
                              ),
                              onTap: () => Future.delayed(Duration.zero,
                                  () => _showAddEditProductDialog(product)),
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 10),
                                  Text('Delete'),
                                ],
                              ),
                              onTap: () => Future.delayed(Duration.zero,
                                  () => _deleteProduct(product.id)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}

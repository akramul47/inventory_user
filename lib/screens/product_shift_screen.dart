import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/auth_servcie.dart';
import '../utils/pallete.dart';

class ShiftProductPage extends StatefulWidget {
  const ShiftProductPage({Key? key}) : super(key: key);

  @override
  State<ShiftProductPage> createState() => _ShiftProductPageState();
}

class _ShiftProductPageState extends State<ShiftProductPage> {
  Warehouse? _fromWarehouse;
  Warehouse? _toWarehouse;
  Product? _selectedProduct;
  bool _isLoading = false;
  List<Product> _products = [];

  Future<void> _fetchProducts(int warehouseId) async {
    setState(() {
      _isLoading = true;
      _products = [];
    });

    try {
      final token = await AuthService.getToken();
      final url =
          'https://warehouse.z8tech.one/Backend/public/api/app/products/warhouse/$warehouseId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _products = data['data']
                .map<Product>((json) => Product.fromJson(json))
                .toList();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error fetching products')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _shiftProduct() async {
    if (_fromWarehouse == null ||
        _toWarehouse == null ||
        _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select from warehouse, to warehouse, and product'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      final url =
          'https://warehouse.z8tech.one/Backend/public/api/productshift/store';
      final body = {
        'from_warehouse_id': _fromWarehouse!.id.toString(),
        'to_warehouse_id': _toWarehouse!.id.toString(),
        'product_ids[]': _selectedProduct!.id.toString(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
        body: body,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product shifted successfully')),
          );
          // Reset dropdown data after successful shift
          setState(() {
            _fromWarehouse = null;
            _toWarehouse = null;
            _selectedProduct = null;
            _products = [];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error shifting product')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final warehouses = productProvider.warehouses;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shift Product',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Pallete.primaryRed,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'From Warehouse',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Warehouse>(
              value: _fromWarehouse,
              hint: const Text('Select From Warehouse'),
              items: warehouses.map((warehouse) {
                return DropdownMenuItem<Warehouse>(
                  value: warehouse,
                  child: Text(warehouse.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _fromWarehouse = value;
                  if (value != null) {
                    _fetchProducts(value.id);
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a warehouse';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'To Warehouse',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Warehouse>(
              value: _toWarehouse,
              hint: const Text('Select To Warehouse'),
              items: warehouses.map((warehouse) {
                return DropdownMenuItem<Warehouse>(
                  value: warehouse,
                  child: Text(warehouse.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _toWarehouse = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a warehouse';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Product',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              hint: const Text('Select Product'),
              items: _products.map((product) {
                return DropdownMenuItem<Product>(
                  value: product,
                  child: Text('${product.productName} (${product.scanCode})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProduct = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a product';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              height: 40,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _shiftProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.primaryRed.withOpacity(0.8),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Shift Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  final int id;
  final String productName;
  final String scanCode;

  Product({
    required this.id,
    required this.productName,
    required this.scanCode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      productName: json['product_name'],
      scanCode: json['scan_code'],
    );
  }
}

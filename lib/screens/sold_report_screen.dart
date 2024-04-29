import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/auth_servcie.dart';
import '../utils/pallete.dart';

class SoldReportPage extends StatefulWidget {
  const SoldReportPage({Key? key}) : super(key: key);

  @override
  State<SoldReportPage> createState() => _SoldReportPageState();
}

class _SoldReportPageState extends State<SoldReportPage> {
  Warehouse? _selectedWarehouse;
  Brand? _selectedBrand;
  Category? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  Future<void> _fetchReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date range'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _reportData = null;
    });

    try {
      final token = await AuthService.getToken();
      final startDateString = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endDateString = DateFormat('yyyy-MM-dd').format(_endDate!);
      final warehouseId = _selectedWarehouse?.id?.toString();
      final brandId = _selectedBrand?.id?.toString();
      final categoryId = _selectedCategory?.id?.toString();

      String url =
          'http://warehouse.z8tech.one/Backend/public/api/sale/report/?starting_date=$startDateString&ending_date=$endDateString';

      if (warehouseId != null) {
        url += '&warehouse_id=$warehouseId';
      }

      if (brandId != null) {
        url += '&brand_id=$brandId';
      }

      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        print(response.body);
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _reportData = data;
            _selectedWarehouse = null;
            _selectedBrand = null;
            _selectedCategory = null;
            _startDate = null;
            _endDate = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error fetching report')),
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
    final brands = productProvider.brands;
    final categories = productProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sold Report',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Pallete.primaryRed,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Select Warehouse (Optional)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Warehouse>(
                value: _selectedWarehouse,
                hint: const Text('Select Warehouse'),
                items: warehouses.map((warehouse) {
                  return DropdownMenuItem<Warehouse>(
                    value: warehouse,
                    child: Text(warehouse.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWarehouse = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Brand (Optional)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Brand>(
                value: _selectedBrand,
                hint: const Text('Select Brand'),
                items: brands.map((brand) {
                  return DropdownMenuItem<Brand>(
                    value: brand,
                    child: Text(brand.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBrand = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Category (Optional)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                hint: const Text('Select Category'),
                items: categories.map((category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Date Range',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            _startDate = selectedDate;
                          });
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat('dd/MM/yyyy').format(_startDate!)
                              : 'Start Date',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            _endDate = selectedDate;
                          });
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat('dd/MM/yyyy').format(_endDate!)
                              : 'End Date',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fetchReport,
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
                      : const Text('Generate Report'),
                ),
              ),
              const SizedBox(height: 16),
              if (_reportData != null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Product Name')),
                      DataColumn(label: Text('Scan Code')),
                      DataColumn(label: Text('Warehouse')),
                      DataColumn(label: Text('Product Price')),
                      DataColumn(label: Text('Sold Price')),
                      DataColumn(label: Text('Sold Date')),
                    ],
                    rows: _reportData!['data']['data'].map<DataRow>(
                      (data) {
                        final product = data['products'];
                        final warehouseName = product['warehouse']['name'];
                        return DataRow(
                          cells: [
                            DataCell(Text(product['product_name'])),
                            DataCell(Text(product['scan_code'])),
                            DataCell(Text(warehouseName)),
                            DataCell(Text(product['product_retail_price'])),
                            DataCell(Text(data['product_sold_price'])),
                            DataCell(
                              Text(
                                DateFormat('dd/MM/yyyy').format(
                                  DateTime.parse(data['updated_at']),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
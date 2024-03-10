import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:provider/provider.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({
    Key? key,
    this.initialQRCode,
    this.initialName,
    this.initialDescription,
    this.initialQuantity,
    this.initialWarehouseTag,
    this.product,
    this.isUpdatingItem = false,
  }) : super(key: key);

  final String? initialQRCode;
  final String? initialName;
  final String? initialDescription;
  final String? initialQuantity;
  final String? initialWarehouseTag;
  final Product? product;
  final bool isUpdatingItem;

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  List<XFile>? _imageFiles;
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  int? _selectedWarehouseId;
  int? _selectedCategoryId;
  int? _selectedBrandId;
  Warehouse? _selectedWarehouse;
  Category? _selectedCategory;
  Brand? _selectedBrand;

  @override
  void initState() {
    super.initState();
    final itemProvider = Provider.of<ProductProvider>(context, listen: false);
    final warehouses = itemProvider.warehouses;
    if (widget.isUpdatingItem && widget.product != null) {
      _barcodeController.text = widget.product!.barcode;
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _quantityController.text = widget.product!.quantity.toString();
      _selectedWarehouse = warehouses.isNotEmpty
          ? warehouses.firstWhere(
              (warehouse) =>
                  warehouse.id == int.parse(widget.product!.warehouseId),
              orElse: () => warehouses.first,
            )
          : Warehouse(id: 0, name: 'Default Warehouse');
      _selectedCategory = itemProvider.categories
          .firstWhere((category) => category.id == widget.product!.categoryId);
      _selectedBrand = itemProvider.brands
          .firstWhere((brand) => brand.id == widget.product!.brandId);
    } else {
      _barcodeController.text = widget.initialQRCode ?? '';
      _nameController.text = widget.initialName ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      _quantityController.text = widget.initialQuantity ?? '';
      _selectedWarehouseId = int.tryParse(widget.initialWarehouseTag ?? '');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _imageFiles = pickedFiles;
      });
    }
  }

  Future<void> _saveProduct() async {
    final token = await AuthService.getToken();
    if (_formKey.currentState!.validate()) {
      final String barcode = _barcodeController.text;
      final String name = _nameController.text;
      try {
        final response = await http.post(
          Uri.parse(
              'https://warehouse.z8tech.one/Backend/public/api/products/store'),
          headers: {
            'Authorization': 'Bearer $token',
          },
          body: {
            'warehouse_id': _selectedWarehouseId.toString(),
            'category_id': _selectedCategoryId.toString(),
            'brand_id': _selectedBrandId.toString(),
            'product_name': name,
            'product_retail_price': '0',
            'product_sale_price': '0',
            'scan_code': barcode,
            'image[]': _imageFiles?.map((file) => file.path).toList().join(','),
          },
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData['status'] == true) {
          // Product saved successfully
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product saved successfully')),
          );
          Navigator.pop(context);
        } else {
          // Product save failed
          String errorMessage =
              responseData['message'] as String? ?? 'Failed to save product';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        // Exception occurred
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
        print('Error saving product: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ProductProvider>(context);
    final warehouses = itemProvider.warehouses;
    final categories = itemProvider.categories;
    final brands = itemProvider.brands;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent[200],
        centerTitle: true,
        title: Text(
          widget.isUpdatingItem ? 'Edit Item' : 'Add New Item',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: () {
                    _showImagePickerDialog(context);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.redAccent[200],
                    radius: 40,
                    child: const Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Existing images
                if (widget.product != null &&
                    widget.product!.imageUrls.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: widget.product!.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.product!.imageUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                const SizedBox(
                  height: 16,
                ),
                const Divider(),
                const SizedBox(
                  height: 16,
                ),
                // Show picked images
                if (_imageFiles != null && _imageFiles!.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _imageFiles!.length,
                    itemBuilder: (context, index) {
                      return Image.file(File(_imageFiles![index].path));
                    },
                  ),
                // Replace with your Image Picker implementation
                // Add Image Picker Functionality
                // Add Image Picker Functionality
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'QR Code/Barcode Value',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () {
                        // Implement Barcode Scanner
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
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
                      _selectedWarehouseId = value?.id;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a warehouse';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
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
                      _selectedCategoryId = value?.id;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
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
                      _selectedBrandId = value?.id;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a brand';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Implement delete functionality
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent[200],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent[200],
        onPressed: _saveProduct,
        child: const Icon(Icons.save, color: Colors.white),
      ),
    );
  }

  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                title: Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

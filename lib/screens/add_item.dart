import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
    this.initialRetailPrice,
    this.initialSalePrice,
    this.initialWarehouseTag,
    this.product,
    this.isUpdatingItem = false,
  }) : super(key: key);

  final String? initialQRCode;
  final String? initialName;
  final String? initialDescription;
  final String? initialQuantity;
  final String? initialRetailPrice;
  final String? initialSalePrice;
  final String? initialWarehouseTag;
  final Product? product;
  final bool isUpdatingItem;

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  List<File> _imageFiles = [];
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  int? _selectedWarehouseId;
  int? _selectedCategoryId;
  int? _selectedBrandId;
  Warehouse? _selectedWarehouse;
  Category? _selectedCategory;
  Brand? _selectedBrand;
  bool _isSaving = false;
  
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
      _retailPriceController.text = widget.product!.retailPrice.toString();
      _salePriceController.text = widget.product!.salePrice.toString();
      _selectedWarehouse = warehouses.isNotEmpty
          ? warehouses.firstWhere(
              (warehouse) =>
                  warehouse.id == int.parse(widget.product!.warehouseId),
              orElse: () => warehouses.first,
            )
          : Warehouse(id: 0, name: 'Default Warehouse');
      _selectedWarehouseId = int.parse(widget.product!.warehouseId);
      _selectedCategory = itemProvider.categories
          .firstWhere((category) => category.id == widget.product!.categoryId);
      _selectedCategoryId = widget.product!.categoryId;
      _selectedBrand = itemProvider.brands
          .firstWhere((brand) => brand.id == widget.product!.brandId);
      _selectedBrandId = widget.product!.brandId;

      // Print statements for debugging
      print('Barcode: ${_barcodeController.text}');
      print('Name: ${_nameController.text}');
      print('Description: ${_descriptionController.text}');
      print('Quantity: ${_quantityController.text}');
      print('Retail Price: ${_retailPriceController.text}');
      print('Sale Price: ${_salePriceController.text}');
      print('Selected Warehouse ID: $_selectedWarehouseId');
      print('Selected Category ID: $_selectedCategoryId');
      print('Selected Brand ID: $_selectedBrandId');
    } else {
      _barcodeController.text = widget.initialQRCode ?? '';
      _nameController.text = widget.initialName ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      _quantityController.text = widget.initialQuantity ?? '';
      _retailPriceController.text = widget.initialRetailPrice ?? '';
      _salePriceController.text = widget.initialSalePrice ?? '';
      _selectedWarehouseId = int.tryParse(widget.initialWarehouseTag ?? '');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _imageFiles =
            pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true; // Show circular progress indicator
      });
      if (widget.isUpdatingItem) {
        await _updateProduct();
      } else {
        await _postProduct();
      }
      setState(() {
        _isSaving = false; // Hide circular progress indicator
      });
    } else {
      print('Validation errors');
    }
  }

  Future<void> _updateProduct() async {
    final token = await AuthService.getToken();
    final productId = widget.product?.id;

    try {
      if (productId != null) {
        // Validate required fields
        if (_selectedWarehouseId == null ||
            _selectedCategoryId == null ||
            _selectedBrandId == null ||
            _nameController.text.isEmpty ||
            _retailPriceController.text.isEmpty ||
            _salePriceController.text.isEmpty ||
            _barcodeController.text.isEmpty) {
          throw Exception('One or more required fields are missing');
        }

        final uri = Uri.parse(
            'https://warehouse.z8tech.one/Backend/public/api/products/update');
        final request = http.MultipartRequest('PUT', uri);
        request.headers['Authorization'] = 'Bearer $token';

        // Add text fields
        request.fields['id'] = productId.toString();
        request.fields['warehouse_id'] = _selectedWarehouseId.toString();
        request.fields['category_id'] = _selectedCategoryId.toString();
        request.fields['brand_id'] = _selectedBrandId.toString();
        request.fields['product_name'] = _nameController.text;
        request.fields['product_retail_price'] = _retailPriceController.text;
        request.fields['product_sale_price'] = _salePriceController.text;
        request.fields['scan_code'] = _barcodeController.text;

        // Add image files
        for (var imageFile in _imageFiles) {
          request.files.add(
              await http.MultipartFile.fromPath('images[]', imageFile.path));
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData['status'] == true) {
          print('Product information updated successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          Navigator.pop(context);
        } else {
          // Product information update failed
          String errorMessage =
              responseData['message'] as String? ?? 'Failed to update product';
          print('Error updating product: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        throw Exception('Product ID is null');
      }
    } catch (e) {
      print('Error updating product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }


  Future<void> _updateProductImages(int productId, String token) async {
    final imageUri = Uri.parse(
        'https://warehouse.z8tech.one/Backend/public/api/update/image');
    final imageRequest = http.MultipartRequest(
        'POST', imageUri); // Use POST method for updating images
    imageRequest.headers['Authorization'] = 'Bearer $token';

    imageRequest.fields['image_ids[]'] = productId.toString();

    for (var imageFile in _imageFiles) {
      final multipartFile = await http.MultipartFile.fromPath(
        'images[]',
        imageFile.path,
      );
      imageRequest.files.add(multipartFile);
    }

    final imageStreamedResponse = await imageRequest.send();
    final imageResponse = await http.Response.fromStream(imageStreamedResponse);

    print('Image request status code: ${imageResponse.statusCode}');
    print('Image request body: ${imageResponse.body}');

    final imageResponseData = jsonDecode(imageResponse.body);

    if (imageResponse.statusCode == 200 &&
        imageResponseData['status'] == true) {
      // Product images updated successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product images updated successfully')),
      );
      Navigator.pop(context);
    } else {
      // Product image update failed
      String errorMessage = imageResponseData['message'] as String? ??
          'Failed to update product images';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }


  Future<void> _postProduct() async {
    final String barcode = _barcodeController.text;
    final String name = _nameController.text;
    final double retailPrice = double.parse(_retailPriceController.text);
    final double salePrice = double.parse(_salePriceController.text);
    final token = await AuthService.getToken();

    try {
      final uri = Uri.parse(
          'https://warehouse.z8tech.one/Backend/public/api/products/store');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['warehouse_id'] = _selectedWarehouseId.toString();
      request.fields['category_id'] = _selectedCategoryId.toString();
      request.fields['brand_id'] = _selectedBrandId.toString();
      request.fields['product_name'] = name;
      request.fields['product_retail_price'] = retailPrice.toString();
      request.fields['product_sale_price'] = salePrice.toString();
      request.fields['scan_code'] = barcode;

      // Add multiple image files
      if (_imageFiles.isNotEmpty) {
        print('Selected image count: ${_imageFiles.length}');
        for (var imageFile in _imageFiles) {
          print('Image file path: ${imageFile.path}');
          // Extract file name from the path
          String fileName = imageFile.path
              .split('/')
              .last; // Assuming path uses '/' separator
          print('Image file name: $fileName');
          // Add file name to the request payload
          request.fields['images[]'] = fileName;
        }
        for (var imageFile in _imageFiles) {
          // Add file to the request
          final multipartFile =
              await http.MultipartFile.fromPath('images[]', imageFile.path);
          request.files.add(multipartFile);
        }
      }

      // Print the request payload
      print('Request payload:');
      print('Headers: ${request.headers}');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.map((file) => file.field)}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      print('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while uploading the images')),
      );
    }
  }

  Future<void> _deleteProduct() async {
    final token = await AuthService.getToken();
    final productId = widget.product?.id;

    try {
      if (productId != null) {
        final uri = Uri.parse(
            'https://warehouse.z8tech.one/Backend/public/api/products/delete/$productId');
        final response = await http.delete(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item deleted successfully')),
            );
            Navigator.pop(context); // Go back to previous route
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'])),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete item')),
          );
        }
      } else {
        throw Exception('Product ID is null');
      }
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
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
                TextFormField(
                  controller: _retailPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Retail Price',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a retail price';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _salePriceController,
                  decoration: const InputDecoration(
                    labelText: 'Sale Price',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a sale price';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                        // Show delete confirmation dialog
                        _showDeleteConfirmationDialog(context);
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
      floatingActionButton: _isSaving
          ? FloatingActionButton(
              backgroundColor: Colors.redAccent[200],
              onPressed: null, // Disable button while saving
              child: const Padding(
                padding:  EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : FloatingActionButton(
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

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Item'),
          content: Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Dismiss the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true); // Dismiss the dialog
                await _deleteProduct(); // Call delete method
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({
    Key? key,
    this.initialQRCode,
    this.initialName,
    this.initialDescription,
    this.initialRetailPrice,
    this.initialSalePrice,
    this.initialWarehouseTag,
    this.product,
    this.isUpdatingItem = false,
    this.refreshDataCallback,
  }) : super(key: key);

  final String? initialQRCode;
  final String? initialName;
  final String? initialDescription;
  final String? initialRetailPrice;
  final String? initialSalePrice;
  final String? initialWarehouseTag;
  final Product? product;
  final bool isUpdatingItem;

  final Function? refreshDataCallback;

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
  String? _barcodeError;

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
      // print('Barcode: ${_barcodeController.text}');
      // print('Name: ${_nameController.text}');
      // print('Description: ${_descriptionController.text}');
      // print('Quantity: ${_quantityController.text}');
      // print('Retail Price: ${_retailPriceController.text}');
      // print('Sale Price: ${_salePriceController.text}');
      // print('Selected Warehouse ID: $_selectedWarehouseId');
      // print('Selected Category ID: $_selectedCategoryId');
      // print('Selected Brand ID: $_selectedBrandId');
    } else {
      _barcodeController.text = widget.initialQRCode ?? '';
      _nameController.text = widget.initialName ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      _retailPriceController.text = widget.initialRetailPrice ?? '';
      _salePriceController.text = widget.initialSalePrice ?? '';
      _selectedWarehouseId = int.tryParse(widget.initialWarehouseTag ?? '');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    List<XFile> pickedFiles = [];

    if (source == ImageSource.camera) {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        pickedFiles = [pickedFile];
      }
    } else {
      final selectedFiles = await ImagePicker().pickMultiImage();
      pickedFiles.addAll(selectedFiles);
        }

    if (pickedFiles.isNotEmpty) {
      _compressAndAddFiles(pickedFiles);
    } else {
      // Show a snackbar if no image is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
    }
  }

  void _compressAndUpdateImages(List<XFile> pickedFiles) {
    setState(() {
      _imageFiles = []; // Clear the existing list
      _compressAndAddFiles(pickedFiles);
    });
  }

  Future<void> _compressAndAddFiles(List<XFile> pickedFiles) async {
    for (var pickedFile in pickedFiles) {
      final compressedFile = await _compressImage(File(pickedFile.path));
      setState(() {
        _imageFiles.add(compressedFile);
      });
    }
  }

  Future<File> _compressImage(File file) async {
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 2300,
      minHeight: 1500,
      quality: 85,
    );

    // Get the temporary directory
    final tempDir = await getTemporaryDirectory();

    // Create a new file in the temporary directory
    final compressedFile =
        File('${tempDir.path}/compressed_${file.path.split('/').last}');
    await compressedFile.writeAsBytes(compressedBytes!);

    return compressedFile;
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
      // print('Validation errors');
    }
  }

  // Function for updating product information
  Future<void> _updateProduct() async {
    // print('Entering _updateProduct');

    final token = await AuthService.getToken();
    final productId = widget.product?.id;

    try {
      if (productId != null) {
        final uri = Uri.parse(
            'https://warehouse.z8tech.one/Backend/public/api/products/app/update/$productId');
        final request = http.MultipartRequest('POST', uri);
        request.fields['_method'] = 'PUT'; // Set the request method to PUT
        request.headers['Authorization'] = 'Bearer $token';

        // Add fields to the request body
        request.fields['warehouse_id'] = _selectedWarehouseId.toString();
        request.fields['category_id'] = _selectedCategoryId.toString();
        request.fields['product_name'] = _nameController.text.trim();
        request.fields['description'] = _descriptionController.text.trim();
        request.fields['product_retail_price'] =
            _retailPriceController.text.trim();
        request.fields['product_sale_price'] = _salePriceController.text.trim();
        request.fields['scan_code'] = _barcodeController.text.trim();

        // print('Request Headers: ${request.headers}');
        // print('Request Fields: ${request.fields}');

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        // print('Response status code: ${response.statusCode}');
        // print('Response body: ${response.body}');

        final responseData = jsonDecode(response.body);

        if (responseData['status'] == true) {
          // Product information updated successfully
          // print('Product information updated successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );

          // print('_imageFiles length: ${_imageFiles.length}');
          if (_imageFiles.isNotEmpty) {
            // print('Calling _updateProductImages');
            await _updateProductImages(productId, token);
          } else {
            // print('No new images selected or product update failed');
          }
        } else {
          // Product information update failed
          String errorMessage =
              responseData['message'] as String? ?? 'Failed to update product';
          // print('Error updating product: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } else {
        throw Exception('Product ID is null');
      }
    } catch (e) {
      // print('Error updating product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  Future<void> _updateProductImages(int productId, String token) async {
    // print('Entering _updateProductImages');

    final uri = Uri.parse(
        'https://warehouse.z8tech.one/Backend/public/api/products/app/update/image/$productId');
    final request = http.MultipartRequest('POST', uri);
    request.fields['_method'] = 'PUT'; // Set the request method to PUT
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Content-type'] = 'Application/json';

    try {
      // Handle image files
      if (_imageFiles.isNotEmpty) {
        // print('Selected image count: ${_imageFiles.length}');
        for (var imageFile in _imageFiles) {
          // print('Image file path: ${imageFile.path}');
          // Extract file name from the path
          String fileName = imageFile.path.split('/').last;
          // print('Image file name: $fileName');
          // Add file name to the request payload
          request.fields['images[]'] = fileName;
          // Add file to the request
          final multipartFile =
              await http.MultipartFile.fromPath('images[]', imageFile.path);
          request.files.add(multipartFile);
        }
      } else {
        // print('No new images selected');
      }

      // Print the request payload
      // print('Request Headers: ${request.headers}');
      // print('Request Fields: ${request.fields}');
      // print('Request Files: ${request.files.map((file) => file.field)}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // print('Image request status code: ${response.statusCode}');
      // print('Image request body: ${response.body}');

      final imageResponseData = jsonDecode(response.body);

      if (response.statusCode == 200 && imageResponseData['status'] == true) {
        // Product images updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product images updated successfully')),
        );
        widget.refreshDataCallback?.call();
        Navigator.pop(context);
      } else {
        // Product image update failed
        String errorMessage = imageResponseData['message'] as String? ??
            'Failed to update product images';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // print('Error updating product images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while uploading the images')),
      );
    }
  }

  Future<void> _postProduct() async {
    // print('Entering _postProduct');
    final String barcode = _barcodeController.text;
    final String name = _nameController.text;
    final String description = _descriptionController.text;
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
      request.fields['description'] = description;
      request.fields['product_retail_price'] = retailPrice.toString();
      request.fields['product_sale_price'] = salePrice.toString();
      request.fields['scan_code'] = barcode;

      // Add multiple image files
      if (_imageFiles.isNotEmpty) {
        // print('Selected image count: ${_imageFiles.length}');
        for (var imageFile in _imageFiles) {
          // Extract file name from the path
          String fileName = imageFile.path.split('/').last;
          // print('Image file name: $fileName');
          // Add file name to the request payload
          request.fields['images[]'] = fileName;
          // Add file to the request
          final multipartFile =
              await http.MultipartFile.fromPath('images[]', imageFile.path);
          request.files.add(multipartFile);
        }
      }

      // Print the request payload
      // print('Request payload:');
      // print('Headers: ${request.headers}');
      // print('Fields: ${request.fields}');
      // print('Files: ${request.files.map((file) => file.field)}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // print('Response status code: ${response.statusCode}');
      // print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        // Product saved successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved successfully')),
        );
        // Call the _fetchData method to refresh the data
        widget.refreshDataCallback?.call();
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
      // print('Error uploading images: $e');
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
            widget.refreshDataCallback?.call();
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
      // print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  List<int> deletedImageIds = [];

  Future<void> _deleteImage(int productImageId) async {
    final token = await AuthService.getToken();
    final productId = widget.product?.id;

    // print('Image ID: ${productImageId}');
    // print('Product ID: ${productId}');

    try {
      final response = await http.post(
        Uri.parse(
            'https://warehouse.z8tech.one/Backend/public/api/products/app/update/image/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-type': 'Appication/json'
        },
        body: jsonEncode({
          '_method': 'PUT',
          'imageId': productImageId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        // Image deleted successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully')),
        );

        // Add the image ID to the list of deleted image IDs
        setState(() {
          deletedImageIds.add(productImageId);
        });
      } else {
        // Image deletion failed
        final errorMessage =
            responseData['message'] as String? ?? 'Failed to delete image';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // Error occurred
      // print('Error deleting image: $e');
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
        backgroundColor: Pallete.primaryRed,
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
                  child: const CircleAvatar(
                    backgroundColor: Pallete.primaryRed,
                    radius: 40,
                    child: Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                // Existing images with delete buttons
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
                      final imageUrl = widget.product!.imageUrls[index];
                      final productImageId =
                          widget.product!.productImages[index].id;

                      if (deletedImageIds.contains(productImageId)) {
                        // If the image ID is in the list of deleted image IDs, display an empty placeholder
                        return Container(); // or any placeholder widget you want to show
                      } else {
                        // Otherwise, display the image
                        return Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: -2,
                              right: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Pallete.primaryRed,
                                ),
                                onPressed: () {
                                  _deleteImage(productImageId);
                                },
                              ),
                            ),
                          ],
                        );
                      }
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
                if (_imageFiles.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _imageFiles.length,
                    itemBuilder: (context, index) {
                      return Image.file(File(_imageFiles[index].path));
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
                    errorText: _barcodeError,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () async {
                        try {
                          var result = await BarcodeScanner.scan();
                          String? scannedCode = result.rawContent;
                          setState(() {
                            _barcodeController.text = scannedCode;
                            _barcodeError = null; // Clear previous error if any
                          });
                        } catch (e) {
                          // print('Error scanning barcode: $e');
                          setState(() {
                            _barcodeError = 'Error scanning barcode';
                          });
                        }
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
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                if (widget.isUpdatingItem)
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
                          backgroundColor: Pallete.primaryRed,
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
          ? const FloatingActionButton(
              backgroundColor: Pallete.primaryRed,
              onPressed: null, // Disable button while saving
              child: Padding(
                padding: EdgeInsets.all(17.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : FloatingActionButton(
              backgroundColor: Pallete.primaryRed,
              onPressed: _saveProduct,
              child: const Icon(Icons.save, color: Colors.white),
            ),
    );
  }

  void _showImagePickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true); // Dismiss the dialog
                await _deleteProduct(); // Call delete method
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

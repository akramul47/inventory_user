import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/services/product_api_service.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _selectedWarehouseId;
  String? _selectedCategoryId;
  String? _selectedBrandId;
  bool _isSaving = false;
  String? _barcodeError;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _getUserRole();
    if (widget.isUpdatingItem && widget.product != null) {
      _barcodeController.text = widget.product!.barcode;
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _quantityController.text = widget.product!.quantity.toString();
      _retailPriceController.text = widget.product!.retailPrice.toString();
      _salePriceController.text = widget.product!.salePrice.toString();
      _selectedWarehouseId = widget.product!.warehouseId;
      _selectedCategoryId = widget.product!.categoryId.toString();
      _selectedBrandId = widget.product!.brandId.toString();

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
      _nameController.text = widget.initialQRCode ?? ''; // Show same as Barcode
      _descriptionController.text = widget.initialDescription ?? '';
      _retailPriceController.text = widget.initialRetailPrice ?? '';
      _salePriceController.text = widget.initialSalePrice ?? '0.0';
      _selectedWarehouseId = widget.initialWarehouseTag;
    }
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('role') ?? '';
    _userRole = roleString.toLowerCase();
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
        const SnackBar(content: Text('No image selected')),
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
      final file = File(pickedFile.path);
      // Only compress on mobile platforms (Android/iOS)
      final compressedFile = (Platform.isAndroid || Platform.isIOS)
          ? await _compressImage(file)
          : file;
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
        File('${tempDir.path}/compressed_${path.basename(file.path)}');
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
    final productId = widget.product?.id;

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product ID is missing')),
      );
      return;
    }

    try {
      final productApiService = ProductApiService();
      
      // Prepare product data
      final productData = {
        'warehouse_id': _selectedWarehouseId,
        'category_id': _selectedCategoryId,
        'brand_id': _selectedBrandId,
        'product_name': _nameController.text.trim(),
        'scan_code': _barcodeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'product_retail_price': _retailPriceController.text.trim(),
        'product_sale_price': _salePriceController.text.trim(),
        'quantity': _quantityController.text.trim(),
      };

      // Update product info
      final result = await productApiService.updateProduct(productId, productData);
      
      if (result['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        }

        // Update images if new ones were selected
        if (_imageFiles.isNotEmpty) {
          await _uploadProductImages(productId);
        } else {
          widget.refreshDataCallback?.call();
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to update product')),
          );
        }
      }
    } catch (e) {
      print('Error updating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  Future<void> _uploadProductImages(int productId) async {
    try {
      final productApiService = ProductApiService();
      
      // Upload images
      final result = await productApiService.uploadProductImages(
        productId,
        _imageFiles,
      );
      
      if (result['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product images uploaded successfully')),
          );
          widget.refreshDataCallback?.call();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to upload images')),
          );
        }
      }
    } catch (e) {
      print('Error uploading product images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading images: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _postProduct() async {
    try {
      final productApiService = ProductApiService();
      
      // Prepare product data
      final productData = {
        'warehouse_id': _selectedWarehouseId,
        'category_id': _selectedCategoryId,
        'brand_id': _selectedBrandId,
        'product_name': _nameController.text.trim(),
        'scan_code': _barcodeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'product_retail_price': _retailPriceController.text.trim(),
        'product_sale_price': _salePriceController.text.trim(),
        'quantity': _quantityController.text.trim(),
      };

      // Create product first (without images)
      final result = await productApiService.createProduct(productData);
      
      if (result['status'] == true) {
        final productId = result['product']?['id'];
        
        if (productId != null && _imageFiles.isNotEmpty) {
          // Upload images after product creation
          await _uploadProductImages(productId);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product saved successfully')),
            );
            widget.refreshDataCallback?.call();
            Navigator.pop(context);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to save product')),
          );
        }
      }
    } catch (e) {
      print('Error creating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    final productId = widget.product?.id;

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product ID is missing')),
      );
      return;
    }

    try {
      final productApiService = ProductApiService();
      final success = await productApiService.deleteProduct(productId);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
          widget.refreshDataCallback?.call();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete item')),
          );
        }
      }
    } catch (e) {
      print('Error deleting product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  List<int> deletedImageIds = [];

  Future<void> _deleteImage(int productImageId) async {
    try {
      final productApiService = ProductApiService();
      final success = await productApiService.deleteProductImage(productImageId);
      
      if (success) {
        setState(() {
          deletedImageIds.add(productImageId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image deleted successfully')),
          );
        }
      }
    } catch (e) {
      print('Error deleting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting image: ${e.toString()}')),
        );
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
        backgroundColor: Pallete.primaryRed,
        centerTitle: true,
        title: Text(
          widget.isUpdatingItem ? 'Edit Item' : 'Add New Item',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;
          return Form(
            key: _formKey,
            child: isWideScreen
                ? _buildWideScreenLayout(warehouses, categories, brands)
                : _buildMobileLayout(warehouses, categories, brands),
          );
        },
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

  Widget _buildWideScreenLayout(
      List<Warehouse> warehouses, List<Category> categories, List<Brand> brands) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.all(32.0),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Images and Dropdowns
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Images section
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[900]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: _buildImageSection(4, showTitle: true),
                      ),
                      const SizedBox(height: 24),
                      // Dropdowns section
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[900]
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: _buildDropdownFields(warehouses, categories, brands),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right column - Form fields
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]!
                            : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildTextFields(),
                        if (widget.isUpdatingItem) ...[
                          const SizedBox(height: 24),
                          _buildDeleteButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      List<Warehouse> warehouses, List<Category> categories, List<Brand> brands) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildImageSection(3),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 20),
        _buildTextFields(),
        const SizedBox(height: 24),
        _buildDropdownFields(warehouses, categories, brands),
        if (widget.isUpdatingItem) ...[
          const SizedBox(height: 24),
          Center(child: _buildDeleteButton()),
        ],
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildImageSection(int crossAxisCount, {bool showTitle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Photos Button
        Center(
          child: GestureDetector(
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
        ),
        if (showTitle &&
            ((widget.product != null && widget.product!.imageUrls.isNotEmpty) ||
                _imageFiles.isNotEmpty)) ...[
          const SizedBox(height: 20),
          Text(
            'Product Images',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[800],
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Existing images grid
        if (widget.product != null && widget.product!.imageUrls.isNotEmpty)
          _buildExistingImagesGrid(crossAxisCount),
        // New images grid
        if (_imageFiles.isNotEmpty) ...[
          if (widget.product != null && widget.product!.imageUrls.isNotEmpty)
            const SizedBox(height: 16),
          _buildNewImagesGrid(crossAxisCount),
        ],
      ],
    );
  }

  Widget _buildExistingImagesGrid(int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.0,
      ),
      itemCount: widget.product!.imageUrls.length,
      itemBuilder: (context, index) {
        final imageUrl = widget.product!.imageUrls[index];
        final productImageId = widget.product!.productImages[index].id;

        if (deletedImageIds.contains(productImageId)) {
          return Container();
        } else {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _deleteImage(productImageId);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildNewImagesGrid(int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.0,
      ),
      itemCount: _imageFiles.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _imageFiles[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      },
    );
  }

  Widget _buildDropdownFields(
      List<Warehouse> warehouses, List<Category> categories, List<Brand> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Classification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedWarehouseId,
          hint: const Text('Select Warehouse'),
          decoration: InputDecoration(
            labelText: 'Warehouse',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: warehouses.map((warehouse) {
            return DropdownMenuItem<String>(
              value: warehouse.id,
              child: Text(warehouse.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedWarehouseId = value;
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
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          hint: const Text('Select Category'),
          decoration: InputDecoration(
            labelText: 'Category',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
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
        DropdownButtonFormField<String>(
          value: _selectedBrandId,
          hint: const Text('Select Brand'),
          decoration: InputDecoration(
            labelText: 'Brand',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: brands.map((brand) {
            return DropdownMenuItem<String>(
              value: brand.id,
              child: Text(brand.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBrandId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a brand';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _barcodeController,
          decoration: InputDecoration(
            labelText: 'Barcode',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorText: _barcodeError,
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                try {
                  final result = await BarcodeScanner.scan();
                  if (result.rawContent.isNotEmpty) {
                    setState(() {
                      _barcodeController.text = result.rawContent;
                    });
                  }
                  setState(() {
                    _barcodeError = null;
                  });
                } catch (e) {
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
          decoration: InputDecoration(
            labelText: 'Product Name',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(
            labelText: 'Quantity',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _retailPriceController,
          decoration: InputDecoration(
            labelText: 'Retail Price',
            prefixText: '\$ ',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a retail price';
            }
            return null;
          },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _salePriceController,
          decoration: InputDecoration(
            labelText: 'Sale Price',
            prefixText: '\$ ',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryRed,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a sale price (e.g., 0.0)';
            }
            return null;
          },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 900;
        return SizedBox(
          width: isWideScreen ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
            icon: const Icon(Icons.delete, size: 20),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.primaryRed,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isWideScreen ? 16 : 12,
                horizontal: isWideScreen ? 24 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
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

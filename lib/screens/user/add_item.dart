import 'dart:io';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/services/product_api_service.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:inventory_user/utils/image_helper.dart';
import 'package:inventory_user/widgets/product_dropdown_field.dart';
import 'package:inventory_user/widgets/product_text_field.dart';
import 'package:inventory_user/widgets/product_image_grid.dart';
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
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _salePriceController = TextEditingController();

  // State
  List<File> _imageFiles = [];
  List<int> _deletedImageIds = [];
  String? _selectedWarehouseId;
  String? _selectedCategoryId;
  String? _selectedBrandId;
  bool _isSaving = false;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _initializeFormData();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _retailPriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('role') ?? '';
    setState(() => _userRole = roleString.toLowerCase());
  }

  void _initializeFormData() {
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
    } else {
      _barcodeController.text = widget.initialQRCode ?? '';
      _nameController.text = widget.initialQRCode ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      _retailPriceController.text = widget.initialRetailPrice ?? '';
      _salePriceController.text = widget.initialSalePrice ?? '0.0';
      _selectedWarehouseId = widget.initialWarehouseTag;
    }
  }

  // Image handling
  Future<void> _pickImages(ImageSource source) async {
    try {
      final images = await ImageHelper.pickImages(source);
      if (images.isNotEmpty) {
        setState(() => _imageFiles.addAll(images));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _deleteImage(int productImageId) async {
    try {
      final productApiService = ProductApiService();
      final success =
          await productApiService.deleteProductImage(productImageId);

      if (success) {
        setState(() => _deletedImageIds.add(productImageId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting image: $e')),
        );
      }
    }
  }

  // Product operations
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.isUpdatingItem) {
        await _updateProduct();
      } else {
        await _createProduct();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createProduct() async {
    final productApiService = ProductApiService();

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

    final result = await productApiService.createProduct(productData);

    if (result['status'] == true) {
      final productId = result['product']?['id'];

      if (productId != null && _imageFiles.isNotEmpty) {
        await _uploadProductImages(productId);
      } else {
        _showSuccessAndClose('Product saved successfully');
      }
    } else {
      _showError(result['message'] ?? 'Failed to save product');
    }
  }

  Future<void> _updateProduct() async {
    final productId = widget.product?.id;
    if (productId == null) {
      _showError('Product ID is missing');
      return;
    }

    final productApiService = ProductApiService();

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

    final result =
        await productApiService.updateProduct(productId, productData);

    if (result['status'] == true) {
      if (_imageFiles.isNotEmpty) {
        await _uploadProductImages(productId);
      } else {
        _showSuccessAndClose('Product updated successfully');
      }
    } else {
      _showError(result['message'] ?? 'Failed to update product');
    }
  }

  Future<void> _uploadProductImages(int productId) async {
    final productApiService = ProductApiService();

    final result = await productApiService.uploadProductImages(
      productId,
      _imageFiles,
    );

    if (result['status'] == true) {
      _showSuccessAndClose('Product images uploaded successfully');
    } else {
      _showError(result['message'] ?? 'Failed to upload images');
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    final productId = widget.product?.id;
    if (productId == null) {
      _showError('Product ID is missing');
      return;
    }

    try {
      final productApiService = ProductApiService();
      final success = await productApiService.deleteProduct(productId);

      if (success) {
        _showSuccessAndClose('Item deleted successfully');
      } else {
        _showError('Failed to delete item');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  // Barcode scanning
  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        setState(() => _barcodeController.text = result.rawContent);
      }
    } catch (e) {
      _showError('Error scanning barcode: $e');
    }
  }

  // UI Helpers
  void _showSuccessAndClose(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    widget.refreshDataCallback?.call();
    Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Product'),
            content:
                const Text('Are you sure you want to delete this product?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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
        iconTheme: const IconThemeData(color: Colors.white),
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
              onPressed: null,
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
    List<Warehouse> warehouses,
    List<Category> categories,
    List<Brand> brands,
  ) {
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
                      _buildImageSection(4, showTitle: true),
                      const SizedBox(height: 24),
                      _buildDropdownSection(warehouses, categories, brands),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right column - Form fields
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildFormFields(),
                      if (widget.isUpdatingItem) ...[
                        const SizedBox(height: 24),
                        _buildDeleteButton(),
                      ],
                    ],
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
    List<Warehouse> warehouses,
    List<Category> categories,
    List<Brand> brands,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildImageSection(3),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 20),
        _buildFormFields(),
        const SizedBox(height: 24),
        _buildDropdownSection(warehouses, categories, brands),
        if (widget.isUpdatingItem) ...[
          const SizedBox(height: 24),
          Center(child: _buildDeleteButton()),
        ],
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildImageSection(int crossAxisCount, {bool showTitle = false}) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Photos Button
          Center(
            child: GestureDetector(
              onTap: _showImagePickerDialog,
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
              ((widget.product != null &&
                      widget.product!.imageUrls.isNotEmpty) ||
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
          // Existing images
          if (widget.product != null && widget.product!.imageUrls.isNotEmpty)
            ProductImageGrid(
              imageUrls: widget.product!.imageUrls,
              crossAxisCount: crossAxisCount,
              onDeleteImage: _deleteImage,
              deletedImageIds: _deletedImageIds,
              productImages: widget.product!.productImages,
            ),
          // New images
          if (_imageFiles.isNotEmpty) ...[
            if (widget.product != null && widget.product!.imageUrls.isNotEmpty)
              const SizedBox(height: 16),
            ProductImageGrid(
              imageFiles: _imageFiles,
              crossAxisCount: crossAxisCount,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownSection(
    List<Warehouse> warehouses,
    List<Category> categories,
    List<Brand> brands,
  ) {
    return Container(
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
          ProductDropdownField<Warehouse>(
            value: warehouses
                .where((w) => w.id == _selectedWarehouseId)
                .firstOrNull,
            label: 'Warehouse',
            hint: 'Select Warehouse',
            items: warehouses,
            getItemLabel: (w) => w.name,
            getItemValue: (w) => w,
            onChanged: (value) =>
                setState(() => _selectedWarehouseId = value?.id),
            validator: (value) =>
                value == null ? 'Please select a warehouse' : null,
          ),
          const SizedBox(height: 16.0),
          ProductDropdownField<Category>(
            value: categories
                .where((c) => c.id == _selectedCategoryId)
                .firstOrNull,
            label: 'Category',
            hint: 'Select Category',
            items: categories,
            getItemLabel: (c) => c.name,
            getItemValue: (c) => c,
            onChanged: (value) =>
                setState(() => _selectedCategoryId = value?.id),
            validator: (value) =>
                value == null ? 'Please select a category' : null,
          ),
          const SizedBox(height: 16.0),
          ProductDropdownField<Brand>(
            value: brands.where((b) => b.id == _selectedBrandId).firstOrNull,
            label: 'Brand',
            hint: 'Select Brand',
            items: brands,
            getItemLabel: (b) => b.name,
            getItemValue: (b) => b,
            onChanged: (value) => setState(() => _selectedBrandId = value?.id),
            validator: (value) =>
                value == null ? 'Please select a brand' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          ProductTextField(
            controller: _barcodeController,
            label: 'Barcode / SKU',
            hint: 'Scan or enter barcode',
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanBarcode,
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a barcode' : null,
          ),
          const SizedBox(height: 16.0),
          ProductTextField(
            controller: _nameController,
            label: 'Product Name',
            hint: 'Enter product name',
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a product name' : null,
          ),
          const SizedBox(height: 16.0),
          ProductTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Enter product description',
            maxLines: 3,
          ),
          const SizedBox(height: 16.0),
          ProductTextField(
            controller: _quantityController,
            label: 'Quantity',
            hint: 'Enter quantity',
            keyboardType: TextInputType.number,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter quantity' : null,
          ),
          const SizedBox(height: 16.0),
          ProductTextField(
            controller: _retailPriceController,
            label: 'Retail Price',
            hint: 'Enter retail price',
            keyboardType: TextInputType.number,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter retail price' : null,
          ),
          const SizedBox(height: 16.0),
          ProductTextField(
            controller: _salePriceController,
            label: 'Sale Price',
            hint: 'Enter sale price',
            keyboardType: TextInputType.number,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter sale price' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return ElevatedButton.icon(
      onPressed: _deleteProduct,
      icon: const Icon(Icons.delete),
      label: const Text('Delete'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }
}

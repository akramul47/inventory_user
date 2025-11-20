import 'package:flutter/material.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:provider/provider.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _retailPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _quantityController;
  late TextEditingController _barcodeController;
  late TextEditingController _uniqueCodeController;

  String? _selectedWarehouseId;
  String? _selectedCategoryId;
  String? _selectedBrandId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _retailPriceController =
        TextEditingController(text: p?.retailPrice.toString() ?? '');
    _salePriceController =
        TextEditingController(text: p?.salePrice.toString() ?? '');
    _quantityController =
        TextEditingController(text: p?.quantity.toString() ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _uniqueCodeController = TextEditingController(text: p?.uniqueCode ?? '');

    if (p != null) {
      _selectedWarehouseId = p.warehouseId;
      _selectedCategoryId = p.categoryId.toString();
      _selectedBrandId = p.brandId.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _retailPriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    _barcodeController.dispose();
    _uniqueCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);

      final productData = {
        'product_name': _nameController.text,
        'description': _descriptionController.text,
        'product_retail_price': _retailPriceController.text,
        'product_sale_price': _salePriceController.text,
        'quantity': _quantityController.text,
        'scan_code': _barcodeController.text,
        'unique_code': _uniqueCodeController.text,
        'warehouse_id': _selectedWarehouseId,
        'category_id': _selectedCategoryId,
        'brand_id': _selectedBrandId,
        'is_sold': 0, // Default
      };

      if (widget.product == null) {
        // Create
        await provider.addProduct(productData, []); // No images for now
      } else {
        // Update
        await provider.updateProduct(
          id: widget.product!.id,
          updatedFields: productData,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.product == null
                  ? 'Product added'
                  : 'Product updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2D3E),
      title: Text(
        widget.product == null ? 'Add Product' : 'Edit Product',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _uniqueCodeController,
                        label: 'Unique Code',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _retailPriceController,
                        label: 'Retail Price',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _salePriceController,
                        label: 'Sale Price',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _quantityController,
                        label: 'Quantity',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _barcodeController,
                        label: 'Barcode',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedWarehouseId,
                        items: provider.warehouses
                            .map((e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.name),
                                ))
                            .toList(),
                        label: 'Warehouse',
                        onChanged: (v) =>
                            setState(() => _selectedWarehouseId = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedCategoryId,
                        items: provider.categories
                            .map((e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.name),
                                ))
                            .toList(),
                        label: 'Category',
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown<String>(
                        value: _selectedBrandId,
                        items: provider.brands
                            .map((e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.name),
                                ))
                            .toList(),
                        label: 'Brand',
                        onChanged: (v) => setState(() => _selectedBrandId = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: Pallete.gradient2,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Pallete.gradient2),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.black12,
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String label,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Pallete.gradient2),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.black12,
      ),
      dropdownColor: const Color(0xFF2A2D3E),
      style: const TextStyle(color: Colors.white),
    );
  }
}

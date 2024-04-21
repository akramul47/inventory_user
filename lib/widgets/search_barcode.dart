import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_user/screens/add_item.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:inventory_user/utils/pallete.dart';

class SearchFromBarcode {
  static Future<void> scanBarcodeAndNavigate(BuildContext context) async {
    try {
      var result = await BarcodeScanner.scan();
      String? scannedCode = result.rawContent;
      await _fetchProductDetailsAndNavigate(context, scannedCode);
    } on Exception {
      // print('Error scanning barcode: $e');
    }
  }

  static Future<void> _fetchProductDetailsAndNavigate(
      BuildContext context, String? scannedCode) async {
    if (scannedCode != null) {

      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent dialog dismissal by tapping outside
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryRed),
                ),
                SizedBox(width: 15),
                Text(
                  'Loading data...',
                  style: TextStyle(
                    color: Pallete.primaryRed,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          );
        },
      );

      // Retrieve token
      String? token = await AuthService.getToken();

      Uri url = Uri.parse(
          'https://warehouse.z8tech.one/Backend/public/api/product/search?scan_code=$scannedCode');

      var response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Close the loading dialog

        var responseData = jsonDecode(response.body);
        // print('Response Data: $responseData');

        var productData = responseData['data'];
        // print('Product Data: $productData');

        Product product = Product.fromJson(productData);
        // print('Parsed Product: $product');

        // Delay navigation to allow the loading dialog to be visible
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemPage(
                initialQRCode: product.barcode,
                initialName: product.name,
                initialDescription: product.description,
                initialRetailPrice: product.retailPrice.toString(),
                initialSalePrice: product.salePrice.toString(),
                initialWarehouseTag: product.warehouseTag,
                product: product, // Pass the product object for updating
                isUpdatingItem: true, // Set the flag for updating
              ),
            ),
          );
        });
      } else {
        Navigator.pop(context); // Close the loading dialog
        // Handle error - Failed to fetch product details
        // print(
        //     'Failed to fetch product details. Status Code: ${response.statusCode}');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Error',
                style: TextStyle(color: Pallete.primaryRed),
              ),
              content: Text('Product not found.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }
}

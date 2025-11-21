import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:inventory_user/screens/user/add_item.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:inventory_user/utils/pallete.dart';

class BarcodeHelper {
  static Future<void> scanBarcodeAndNavigate(BuildContext context) async {
    try {
      var result = await BarcodeScanner.scan();
      String? scannedCode = result.rawContent;

      // Show loading dialog
      showLoadingDialog(context);

      // Attempt to fetch product details from the API
      Product? product = await _fetchProductDetailsFromAPI(scannedCode);

      // Close the loading dialog
      Navigator.pop(context);

      if (product != null) {
        // Product found, navigate to AddItemPage with fetched details
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
      } else {
        // Product not found, navigate to AddItemPage with just the scanned code
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddItemPage(initialQRCode: scannedCode),
          ),
        );
      }
    } on Exception catch (e) {
      // print('Error scanning barcode: $e');
    }
  }

  static Future<Product?> _fetchProductDetailsFromAPI(
      String? scannedCode) async {
    if (scannedCode != null) {
      // Retrieve token
      String? token = await AuthService.getToken();

      Uri url = Uri.parse(
          'https://warehouse.z8tech.one/Backend/public/api/product/search?scan_code=$scannedCode');

      var response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var productData = responseData['data'];
        return Product.fromJson(productData);
      } else {
        // Handle error - Failed to fetch product details
        // print(
        //     'Failed to fetch product details. Status Code: ${response.statusCode}');
        return null;
      }
    }
    return null;
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog dismissal by tapping outside
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
  }
}

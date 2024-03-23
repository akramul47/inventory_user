import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:inventory_user/screens/add_item.dart';

class BarcodeHelper {
  static Future<void> scanBarcodeAndNavigate(BuildContext context) async {
    try {
      var result = await BarcodeScanner.scan();
      String? scannedCode = result.rawContent;
      // Navigate to the AddItemPage, passing the scanned code as initialQRCode
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddItemPage(initialQRCode: scannedCode),
        ),
      );
        } on Exception catch (e) {
      print('Error scanning barcode: $e');
    }
  }
}

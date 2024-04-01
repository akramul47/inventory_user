import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/auth_servcie.dart';
import '../utils/pallete.dart';
import 'package:csv/csv.dart';

class ExportImportPage extends StatefulWidget {
  const ExportImportPage({Key? key}) : super(key: key);

  @override
  State<ExportImportPage> createState() => _ExportImportPageState();
}

class _ExportImportPageState extends State<ExportImportPage> {
  Warehouse? _selectedWarehouse;
  PlatformFile? _selectedFile;
  bool _isImportingProducts = false;
  bool _isExportingProducts = false;
  String? _downloadUrl;

  Future<void> _importProducts() async {
    print('_selectedFile: $_selectedFile');
    print('_selectedFile!.bytes: ${_selectedFile!.bytes}');

    if (_selectedFile == null || _selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a CSV file')),
      );
      return;
    }

    setState(() {
      _isImportingProducts = true;
    });

    try {
      // Read the CSV file
      String csvString = String.fromCharCodes(_selectedFile!.bytes!);

      // Parse the CSV string
      List<List<dynamic>> csvDataList =
          const CsvToListConverter().convert(csvString);

      // Convert the parsed CSV data to a list of maps
      List<Map<String, dynamic>> jsonDataList = [];

      for (List<dynamic> row in csvDataList) {
        Map<String, dynamic> rowData = {
          'id': row[0],
          'field1': row[1],
          'field2': row[2],
          'field3': row[3],
          'name': row[4],
          // Add other fields as necessary
        };
        jsonDataList.add(rowData);
      }

      // Convert list of maps to JSON
      String jsonData = json.encode(jsonDataList);

      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('https://warehouse.z8tech.one/Backend/public/api/import'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonData,
      );

      setState(() {
        _isImportingProducts = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imported successfully')),
        );
      } else if (response.statusCode == 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Internal Server Error')),
        );
      } else {
        final errorBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${errorBody['message']}')),
        );
      }
    } catch (e) {
      print('Error importing products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error importing products')),
      );
    } finally {
      setState(() {
        _isImportingProducts = false;
      });
    }
  }

  Future<void> _exportProducts() async {
    setState(() {
      _isExportingProducts = true;
      _downloadUrl = null;
    });

    final token = await AuthService.getToken();
    final url = _selectedWarehouse == null
        ? 'https://warehouse.z8tech.one/Backend/public/api/export'
        : 'https://warehouse.z8tech.one/Backend/public/api/export-By-Warehouse/${_selectedWarehouse!.id}';

    final payload =
        _selectedWarehouse == null ? {} : {'id': _selectedWarehouse!.id};

    print('Export request URL: $url');
    print('Export request payload: $payload');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );

    setState(() {
      _isExportingProducts = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        final fileUrl = data['url'];
        setState(() {
          _downloadUrl = fileUrl;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error exporting products')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.reasonPhrase}')),
      );
    }
  }

  Future<void> _downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;

    final directory = await getExternalStorageDirectory();
    final path = directory!.path;
    final fileName = url.split('/').last;
    final file = File('$path/$fileName');

    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File downloaded to $path/$fileName'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final warehouses = productProvider.warehouses;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Import / Export',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Pallete.primaryRed,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              const Text(
                'IMPORT',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: false,
                        type: FileType.custom,
                        allowedExtensions: ['csv'],
                      );
                      if (result != null && result.files.isNotEmpty) {
                        // Retrieve the first selected file
                        final selectedFile = result.files.first;

                        // Read the file as a byte list
                        final List<int> fileBytes =
                            await File(selectedFile.path!).readAsBytes();

                        setState(() {
                          // Convert List<int> to Uint8List
                          final Uint8List uint8FileBytes =
                              Uint8List.fromList(fileBytes);

                          // Create a new PlatformFile object with updated bytes
                          _selectedFile = PlatformFile(
                            name: selectedFile.name,
                            size: selectedFile.size,
                            path: selectedFile.path,
                            bytes: uint8FileBytes,
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallete.primaryRed.withOpacity(0.8),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose File'),
                  ),

                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isImportingProducts ? null : _importProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.primaryRed.withOpacity(0.8),
                        foregroundColor: Colors.white,
                      ),
                      child: _isImportingProducts
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
                          : const Text('Import'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_selectedFile != null)
                Text(
                  'Selected file: ${_selectedFile!.name}',
                  style: const TextStyle(fontSize: 16),
                ),
              const Divider(
                height: 70,
                thickness: 3,
                color: Pallete.primaryRed,
              ),
              const Text(
                'EXPORT',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Warehouse>(
                value: _selectedWarehouse,
                hint: const Text('Select Warehouse'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All'),
                  ),
                  ...warehouses.map((warehouse) {
                    return DropdownMenuItem<Warehouse>(
                      value: warehouse,
                      child: Text(warehouse.name),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedWarehouse = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a warehouse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isExportingProducts ? null : _exportProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.primaryRed.withOpacity(0.8),
                    foregroundColor: Colors.white,
                  ),
                  child: _isExportingProducts
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
                      : const Text('Generate CSV'),
                ),
              ),
              const SizedBox(height: 16),
              if (_downloadUrl != null)
                ElevatedButton.icon(
                  onPressed: () => _downloadFile(_downloadUrl!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.primaryRed.withOpacity(0.8),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Download CSV'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

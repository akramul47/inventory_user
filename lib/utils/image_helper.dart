import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Helper class for handling image operations
class ImageHelper {
  /// Pick images from gallery or camera
  static Future<List<File>> pickImages(ImageSource source) async {
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

    if (pickedFiles.isEmpty) {
      return [];
    }

    return await _compressImages(pickedFiles);
  }

  /// Compress a list of image files
  static Future<List<File>> _compressImages(List<XFile> pickedFiles) async {
    List<File> compressedFiles = [];

    for (var pickedFile in pickedFiles) {
      final file = File(pickedFile.path);
      // Only compress on mobile platforms (Android/iOS)
      final compressedFile = (Platform.isAndroid || Platform.isIOS)
          ? await _compressImage(file)
          : file;
      compressedFiles.add(compressedFile);
    }

    return compressedFiles;
  }

  /// Compress a single image file
  static Future<File> _compressImage(File file) async {
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
}

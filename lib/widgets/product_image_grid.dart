import 'dart:io';
import 'package:flutter/material.dart';

/// Widget to display a grid of images (existing or new)
class ProductImageGrid extends StatelessWidget {
  final List<String>? imageUrls;
  final List<File>? imageFiles;
  final int crossAxisCount;
  final Function(int)? onDeleteImage;
  final List<int>? deletedImageIds;
  final List<dynamic>? productImages;

  const ProductImageGrid({
    Key? key,
    this.imageUrls,
    this.imageFiles,
    required this.crossAxisCount,
    this.onDeleteImage,
    this.deletedImageIds,
    this.productImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Build existing images from URLs
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.0,
        ),
        itemCount: imageUrls!.length,
        itemBuilder: (context, index) {
          final imageUrl = imageUrls![index];
          final productImageId = productImages?[index]?.id;

          if (deletedImageIds != null &&
              productImageId != null &&
              deletedImageIds!.contains(productImageId)) {
            return Container();
          }

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
                if (onDeleteImage != null && productImageId != null)
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
                        onPressed: () => onDeleteImage!(productImageId),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    // Build new images from files
    if (imageFiles != null && imageFiles!.isNotEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.0,
        ),
        itemCount: imageFiles!.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              imageFiles![index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

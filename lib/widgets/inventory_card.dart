import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/screens/add_item.dart';
import 'package:provider/provider.dart';
import 'package:inventory_user/models/product_model.dart';

class MyCardWidget extends StatelessWidget {
  const MyCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ProductProvider>(context);
    final List<Product> items =
        itemProvider.products; // Retrieve the list of items

    return ListView.builder(
      itemCount: items.length, // Use the actual length of your data
      itemBuilder: (context, index) {
        // Access the item data from the list
        Product product = items[index];

        // Replace the following placeholders with actual data
        String name = product.name;
        String createDate =
            'Create Date: ${product.createdAt.toLocal().toString().split(' ')[0]}';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddItemPage(
                  initialQRCode: product.barcode,
                  initialName: product.name,
                  initialDescription: product.description,
                  initialWarehouseTag: product.warehouseTag,
                  product: product, // Pass the product object for updating
                  isUpdatingItem: true, // Set the flag for updating
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.all(5.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrls.isNotEmpty
                      ? product.imageUrls.first
                      : '',
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    backgroundImage: imageProvider,
                  ),
                  // placeholder: (context, url) =>
                  //     const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(createDate),
              trailing:
                  const Icon(Icons.star), // Replace with your star icon logic
            ),
          ),
        );
      },
    );
  }
}

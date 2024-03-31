import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:inventory_user/models/product_model.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/screens/add_item.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:provider/provider.dart';

class MyCardWidget extends StatefulWidget {
  const MyCardWidget({Key? key, required this.refreshDataCallback})
      : super(key: key);

  final Function refreshDataCallback;

  @override
  _MyCardWidgetState createState() => _MyCardWidgetState();
}

class _MyCardWidgetState extends State<MyCardWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      // Call the refreshDataCallback function to trigger data refresh
      widget.refreshDataCallback();
    } catch (e) {
      // If an error occurs during refresh, notify the RefreshController about the error
    }
  }

  void _onScroll() {
    if (_isScrollAtBottom()) {
      // Load more products when scroll reaches the bottom
      _loadMoreProducts();
    }
  }

  bool _isScrollAtBottom() {
    return (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent);
  }

  void _loadMoreProducts() {
    final itemProvider = Provider.of<ProductProvider>(context, listen: false);
    itemProvider.loadMoreProducts();
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ProductProvider>(context);
    final List<Product> items = itemProvider.products;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: items.length + 1, // Add 1 for loading indicator
        itemBuilder: (context, index) {
          if (index == items.length) {
            // Reached the end of the list, show loading indicator
            return _buildLoadingIndicator(context);
          } else {
            // Existing item
            Product product = items[index];
            return _buildProductItem(context, product);
          }
        },
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Product product) {
    // Build your product item here as before
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
              refreshDataCallback: widget.refreshDataCallback,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(5.0),
        child: ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
              imageUrl:
                  product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
              imageBuilder: (context, imageProvider) => CircleAvatar(
                backgroundImage: imageProvider,
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.error,
                color: Pallete.primaryRed,
              ),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(createDate),
          trailing: const Icon(Icons.star),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryRed),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading more products',
            style: TextStyle(
              color: Pallete.primaryRed,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

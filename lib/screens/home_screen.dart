import 'package:flutter/material.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/screens/add_item.dart';
import 'package:inventory_user/widgets/app_drawer.dart';
import 'package:inventory_user/widgets/barcode_scanner.dart';
import 'package:inventory_user/widgets/inventory_card.dart';
import 'package:inventory_user/widgets/shimmer.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Fetch data on initialization
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      await productProvider.fetchProducts(forceRefresh: true);
    } catch (e) {
      print('Error fetching products: $e');
      // Handle error, e.g., show a snackbar
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleScanBarcode() async {
    // Call BarcodeScanner.scanBarcode function when "Add New From QR Code" is selected
    String? scannedQRCode = await BarcodeScanner.scanBarcode();
    if (scannedQRCode != null) {
      // Navigate to AddItemPage and pass the scanned QR code as a parameter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddItemPage(initialQRCode: scannedQRCode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarHeight: 55,
          backgroundColor: Colors.redAccent[200],
          title: Text(
            widget.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _handleScanBarcode,
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    iconSize: 30,
                    color: Colors.white,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.sort_by_alpha_outlined),
                    iconSize: 30,
                    color: Colors.white,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_outlined),
                    iconSize: 30,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(
                  Icons.category,
                  color: Colors.white,
                ),
                text: 'ALL ITEMS',
              ),
              Tab(
                icon: Icon(
                  Icons.local_offer,
                  color: Colors.white,
                ),
                text: 'WAREHOUSE',
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
          ),
        ),
        drawer: AppDrawer(navigatorKey: GlobalKey<NavigatorState>()),
        body: const TabBarView(
          children: [
            // Content of the first tab (ITEMS)
            _ItemsTabContent(),
            // Content of the second tab (TAGS)
            Center(
              child: Text('Content for TAGS tab'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Add items',
          backgroundColor: Colors.redAccent[200],
          child: PopupMenuButton(
            color: Theme.of(context).colorScheme.secondary,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _handleScanBarcode,
                child: const Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(width: 16.0),
                    Text(
                      'Add New From QR Code',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(
                      Icons.add_box_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(width: 16.0),
                    Text(
                      'Add new item',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to a different page when "Add new item" is selected
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddItemPage(),
                    ),
                  );
                },
              ),
            ],
            offset: const Offset(0, -130),
          ),
        ),
      ),
    );
  }
}

class _ItemsTabContent extends StatelessWidget {
  const _ItemsTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.products;

        // If products is empty, show circular progress indicator
        if (products.isEmpty) {
          return CardSkeleton();
        }

        // If products is not empty, show the list of items
        return MyCardWidget();
      },
    );
  }
}


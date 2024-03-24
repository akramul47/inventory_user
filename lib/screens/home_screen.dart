import 'package:flutter/material.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/screens/add_item.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:inventory_user/widgets/app_drawer.dart';
import 'package:inventory_user/widgets/inventory_card.dart';
import 'package:inventory_user/widgets/scanner.dart';
import 'package:inventory_user/widgets/shimmer.dart';
import 'package:inventory_user/widgets/warehouse_list.dart';
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
  bool _isLoading = true;

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
      final token = await AuthService.getToken();

      // Fetch products and warehouse data
      await productProvider.fetchProducts(forceRefresh: true);
      await productProvider.fetchWarehouseCategoryBrand(token);
      setState(() {
        _isLoading = false; // Set isLoading to false when data is loaded
      });
    } catch (e) {
      print('Error fetching data: $e');
      // Handle error, e.g., show a snackbar
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCodeScanned(String code) {
    // Navigate to the "add item" page while passing the scanned code as a parameter
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddItemPage(initialQRCode: code)),
    );
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
          title: Image.asset('assets/logo.jpeg'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      await BarcodeHelper.scanBarcodeAndNavigate(context);
                    },
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
        body: TabBarView(
          children: [
            _ItemsTabContent(isLoading: _isLoading),
            WarehouseListWidget(),
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
                onTap: () async {
                  await BarcodeHelper.scanBarcodeAndNavigate(context);
                },
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
  const _ItemsTabContent({Key? key, required this.isLoading}) : super(key: key);

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.products;

        // If isLoading is true or products is empty, show circular progress indicator
        if (isLoading || products.isEmpty) {
          return const CardSkeleton();
        }

        // If products is not empty, show the list of items
        return const MyCardWidget();
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:inventory_user/providers/product_provider.dart';
import 'package:inventory_user/screens/add_item.dart';
import 'package:inventory_user/services/auth_servcie.dart';
import 'package:inventory_user/utils/pallete.dart';
import 'package:inventory_user/widgets/app_drawer.dart';
import 'package:inventory_user/widgets/inventory_card.dart';
import 'package:inventory_user/widgets/scanner.dart';
import 'package:inventory_user/widgets/search_barcode.dart';
import 'package:inventory_user/widgets/modern_shimmer.dart';
import 'package:inventory_user/widgets/warehouse_list.dart';
import 'package:inventory_user/widgets/empty_state_widget.dart';
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
  bool _isRefreshing = false;

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
      setState(() {
        _isLoading = true;
        _isRefreshing = true;
      });

      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      // Clear the product data and reset the current page
      productProvider.clearProducts();
      productProvider.resetCurrentPage();

      final token = await AuthService.getToken();

      // Fetch products and warehouse data
      await productProvider.fetchWarehouseCategoryBrand();
      await productProvider.loadMoreProducts();

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      // print('Error fetching data: $e');
      // Handle error, e.g., show a snackbar
    }
  }

  void refreshData() {
    _fetchData();
  }

  Widget buildMyCardWidget() {
    return MyCardWidget(refreshDataCallback: refreshData);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;
        
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              toolbarHeight: 55,
              backgroundColor: Pallete.primaryRed,
              title: const Text(
                'Inventory+',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // title: Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
              //   child: Image.asset(
              //     'assets/logo.jpeg',
              //     height: 40,
              //   ),
              // ),
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
                        onPressed: () async {
                          await SearchFromBarcode.scanBarcodeAndNavigate(context);
                        },
                        icon: const Icon(Icons.search_outlined),
                        iconSize: 30,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
              // Only show TabBar on mobile screens
              bottom: isLargeScreen ? null : const TabBar(
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 600;
            
            if (isLargeScreen) {
              // Show both tabs side by side on larger screens
              return Row(
                children: [
                  // All Items - 70%
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header for All Items
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  color: Pallete.primaryRed,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'ALL ITEMS',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Content
                          Expanded(
                            child: _ItemsTabContent(
                              isLoading: _isLoading,
                              isRefreshing: _isRefreshing,
                              myCardWidget: buildMyCardWidget(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Warehouse - 30%
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Header for Warehouse
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                color: Pallete.primaryRed,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'WAREHOUSE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        const Expanded(
                          child: WarehouseListWidget(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Show tabs on mobile screens
              return TabBarView(
                children: [
                  _ItemsTabContent(
                    isLoading: _isLoading,
                    isRefreshing: _isRefreshing,
                    myCardWidget: buildMyCardWidget(),
                  ),
                  const WarehouseListWidget(),
                ],
              );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Add items',
          backgroundColor: Pallete.primaryRed,
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
                      builder: (context) => AddItemPage(
                        refreshDataCallback:
                            refreshData, // Pass the refreshData method reference
                      ),
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
      },
    );
  }
}

class _ItemsTabContent extends StatelessWidget {
  const _ItemsTabContent({Key? key, required this.isLoading, required this.isRefreshing,
      required this.myCardWidget}) : super(key: key);

  final bool isLoading;
  final bool isRefreshing;
  final Widget myCardWidget;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.products;

        // Show loading skeleton while fetching data
        if (isLoading) {
          return const ProductCardShimmer();
        }

        // Show empty state when no products are available
        if (products.isEmpty) {
          return const NoProductsEmptyState();
        }

        // Show the list of items
        return myCardWidget;
      },
    );
  }
}

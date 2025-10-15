import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../models/product.dart';
import '../../services/inventory_service.dart';
import 'package:barcode_widget/barcode_widget.dart';

class PrintBarcodePage extends StatefulWidget {
  const PrintBarcodePage({super.key});

  @override
  State<PrintBarcodePage> createState() => _PrintBarcodePageState();
}

class _PrintBarcodePageState extends State<PrintBarcodePage> {
  ProductResponse? productResponse;
  String? errorMessage;
  int currentPage = 1;
  final int itemsPerPage =
      10; // Load 10 products per page for better performance

  // Caching and filtering
  List<Product> _allProductsCache = [];
  List<Product> _allFilteredProducts = [];
  List<Product> _filteredProducts = [];
  Timer? _searchDebounceTimer;
  bool _isFilterActive = false;

  String selectedCategory = 'All';
  String selectedVendor = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Selection state
  Set<String> selectedProductCodes = {};
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    _fetchAllProductsOnInit(); // Fetch all products once on page load
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  // Fetch all products once when page loads
  Future<void> _fetchAllProductsOnInit() async {
    try {
      print('🚀 Initial load: Fetching all products');
      setState(() {
        errorMessage = null;
      });

      // Fetch all products from all pages
      List<Product> allProducts = [];
      int currentFetchPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          print('📡 Fetching page $currentFetchPage');
          final response = await InventoryService.getProducts(
            page: currentFetchPage,
            limit: 50, // Use larger page size for efficiency
          );

          allProducts.addAll(response.data);
          print(
            '📦 Page $currentFetchPage: ${response.data.length} products (total: ${allProducts.length})',
          );

          // Check if there are more pages
          if (response.meta.currentPage >= response.meta.lastPage) {
            hasMorePages = false;
          } else {
            currentFetchPage++;
          }
        } catch (e) {
          print('❌ Error fetching page $currentFetchPage: $e');
          hasMorePages = false; // Stop fetching on error
        }
      }

      _allProductsCache = allProducts;
      print('💾 Cached ${_allProductsCache.length} total products');

      // Apply initial filters (which will be no filters, showing all products)
      _applyFiltersClientSide();
    } catch (e) {
      print('❌ Critical error in _fetchAllProductsOnInit: $e');
      setState(() {
        errorMessage = 'Failed to load products. Please refresh the page.';
      });
    }
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      // Cancel previous timer
      _searchDebounceTimer?.cancel();

      // Set new timer for debounced search (500ms delay)
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        print('🔍 Search triggered: "${_searchController.text}"');
        setState(() {
          currentPage = 1; // Reset to first page when search changes
        });
        // Apply filters when search changes
        _applyFilters();
      });
    });
  }

  // Client-side only filter application
  void _applyFilters() {
    print('🎯 _applyFilters called - performing client-side filtering only');
    _applyFiltersClientSide();
  }

  // Pure client-side filtering method
  void _applyFiltersClientSide() {
    try {
      final searchText = _searchController.text.toLowerCase().trim();
      final hasSearch = searchText.isNotEmpty;
      final hasCategoryFilter = selectedCategory != 'All';
      final hasVendorFilter = selectedVendor != 'All';

      print(
        '🎯 Client-side filtering - search: "$searchText", category: "$selectedCategory", vendor: "$selectedVendor"',
      );
      print(
        '🎯 hasSearch: $hasSearch, hasCategoryFilter: $hasCategoryFilter, hasVendorFilter: $hasVendorFilter',
      );

      setState(() {
        _isFilterActive = hasSearch || hasCategoryFilter || hasVendorFilter;
      });

      // Apply filters to cached products (no API calls)
      _filterCachedProducts(searchText);

      print('🔄 _isFilterActive: $_isFilterActive');
      print('📦 _allProductsCache.length: ${_allProductsCache.length}');
      print('🎯 _allFilteredProducts.length: ${_allFilteredProducts.length}');
      print('👀 _filteredProducts.length: ${_filteredProducts.length}');
    } catch (e) {
      print('❌ Error in _applyFiltersClientSide: $e');
      setState(() {
        errorMessage = 'Search error: Please try a different search term';
      });
    }
  }

  // Filter cached products without any API calls
  void _filterCachedProducts(String searchText) {
    try {
      // Apply filters to cached products with enhanced error handling
      _allFilteredProducts = _allProductsCache.where((product) {
        try {
          // Category filter
          if (selectedCategory != 'All' &&
              product.subCategoryId != selectedCategory) {
            return false;
          }

          // Vendor filter
          if (selectedVendor != 'All' &&
              product.vendor.name != selectedVendor) {
            return false;
          }

          // Search filter
          if (searchText.isEmpty) {
            return true;
          }

          // Search in multiple fields with better null safety and error handling
          final productTitle = product.title.toLowerCase();
          final productDesignCode = product.designCode.toLowerCase();
          final productBarcode = product.barcode.toLowerCase();
          final vendorName = product.vendor.name?.toLowerCase() ?? '';
          final subCategoryId = product.subCategoryId.toLowerCase();

          return productTitle.contains(searchText) ||
              productDesignCode.contains(searchText) ||
              productBarcode.contains(searchText) ||
              vendorName.contains(searchText) ||
              subCategoryId.contains(searchText);
        } catch (e) {
          // If there's any error during filtering, exclude this product
          print('⚠️ Error filtering product ${product.id}: $e');
          return false;
        }
      }).toList();

      print(
        '🔍 After filtering: ${_allFilteredProducts.length} products match criteria',
      );
      print(
        '📝 Search text: "$searchText", Category filter: "$selectedCategory", Vendor filter: "$selectedVendor"',
      );

      // Update selection state: keep only products that are still in filtered results
      final filteredProductCodes = _allFilteredProducts
          .map((p) => p.designCode)
          .toSet();
      selectedProductCodes.retainAll(filteredProductCodes);

      // Apply local pagination to filtered results
      _paginateFilteredProducts();

      setState(() {
        errorMessage = null;
      });
    } catch (e) {
      print('❌ Critical error in _filterCachedProducts: $e');
      setState(() {
        errorMessage =
            'Search failed. Please try again with a simpler search term.';
        // Fallback: show empty results instead of crashing
        _filteredProducts = [];
        _allFilteredProducts = [];
      });
    }
  }

  // Apply local pagination to filtered products
  void _paginateFilteredProducts() {
    try {
      // Handle empty results case
      if (_allFilteredProducts.isEmpty) {
        setState(() {
          _filteredProducts = [];
          // Update productResponse meta for pagination controls
          productResponse = ProductResponse(
            data: [],
            links: Links(),
            meta: Meta(
              currentPage: 1,
              lastPage: 1,
              links: [],
              path: "/products",
              perPage: itemsPerPage,
              total: 0,
            ),
          );
        });
        return;
      }

      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      // Ensure startIndex is not greater than the list length
      if (startIndex >= _allFilteredProducts.length) {
        // Reset to page 1 if current page is out of bounds
        setState(() {
          currentPage = 1;
        });
        _paginateFilteredProducts(); // Recursive call with corrected page
        return;
      }

      setState(() {
        _filteredProducts = _allFilteredProducts.sublist(
          startIndex,
          endIndex > _allFilteredProducts.length
              ? _allFilteredProducts.length
              : endIndex,
        );

        // Update productResponse meta for pagination controls
        final totalPages = (_allFilteredProducts.length / itemsPerPage).ceil();
        print('📄 Pagination calculation:');
        print(
          '   📊 _allFilteredProducts.length: ${_allFilteredProducts.length}',
        );
        print('   📝 itemsPerPage: $itemsPerPage');
        print('   🔢 totalPages: $totalPages');
        print('   📍 currentPage: $currentPage');

        productResponse = ProductResponse(
          data: _filteredProducts,
          links: Links(), // Empty links for local pagination
          meta: Meta(
            currentPage: currentPage,
            lastPage: totalPages,
            links: [], // Empty links array for local pagination
            path: "/products", // Default path
            perPage: itemsPerPage,
            total: _allFilteredProducts.length,
          ),
        );

        // Update selectAll state based on current filtered products
        selectAll =
            _filteredProducts.isNotEmpty &&
            selectedProductCodes.length == _filteredProducts.length &&
            _filteredProducts.every(
              (product) => selectedProductCodes.contains(product.designCode),
            );
      });
    } catch (e) {
      print('❌ Error in _paginateFilteredProducts: $e');
      setState(() {
        _filteredProducts = [];
        currentPage = 1;
      });
    }
  }

  // Handle page changes for both filtered and normal pagination
  Future<void> _changePage(int newPage) async {
    setState(() {
      currentPage = newPage;
    });

    // Always use client-side pagination when we have cached products
    if (_allProductsCache.isNotEmpty) {
      _paginateFilteredProducts();
    } else {
      // Fallback to server pagination only if no cached data
      await _fetchProducts(page: newPage);
    }
  }

  Future<void> _fetchProducts({int page = 1}) async {
    if (!mounted) return;

    setState(() {
      errorMessage = null;
    });

    try {
      final response = await InventoryService.getProducts(
        page: page,
        limit: itemsPerPage,
      );

      if (!mounted) return;

      setState(() {
        productResponse = response;
        currentPage = response.meta.currentPage;
        // Clear selections when changing pages
        selectedProductCodes.clear();
        selectAll = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  void toggleSelectAll(bool? value) {
    if (_filteredProducts.isEmpty) return;

    setState(() {
      if (value == true) {
        selectedProductCodes = _filteredProducts
            .map((product) => product.designCode)
            .toSet();
        selectAll = true;
      } else {
        selectedProductCodes.clear();
        selectAll = false;
      }
    });
  }

  void toggleProductSelection(String productCode, bool? value) {
    setState(() {
      if (value == true) {
        selectedProductCodes.add(productCode);
      } else {
        selectedProductCodes.remove(productCode);
      }
      // Update selectAll based on current filtered products
      selectAll =
          _filteredProducts.isNotEmpty &&
          selectedProductCodes.length == _filteredProducts.length &&
          _filteredProducts.every(
            (product) => selectedProductCodes.contains(product.designCode),
          );
    });
  }

  List<Product> getSelectedProducts() {
    if (productResponse == null) return [];
    return productResponse!.data
        .where((product) => selectedProductCodes.contains(product.designCode))
        .toList();
  }

  void generateAndPrintBarcode() {
    final selectedProducts = getSelectedProducts();
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one product to generate barcode',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if all products are selected
    final isAllProductsSelected =
        selectAll ||
        selectedProductCodes.length == productResponse?.data.length;

    // Show barcode generation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isAllProductsSelected
                ? 'Generate Single Barcode (All Products)'
                : 'Generate Barcodes',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${selectedProducts.length} product(s) selected'),
                const SizedBox(height: 16),
                if (isAllProductsSelected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Single Barcode for All Products',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF17A2B8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: _generateAllProductsBarcodeData(
                            selectedProducts,
                          ),
                          width: 250,
                          height: 80,
                          drawText: false,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contains data for ${selectedProducts.length} products',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(children: _buildBarcodeRows(selectedProducts)),
                const SizedBox(height: 16),
                Text(
                  isAllProductsSelected
                      ? 'This barcode contains information for all products in your inventory.'
                      : 'Barcode generation and printing feature coming soon!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAllProductsSelected
                          ? 'Generating single barcode for all ${selectedProducts.length} products...'
                          : 'Generating barcodes for ${selectedProducts.length} products...',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1845),
                foregroundColor: Colors.white,
              ),
              child: Text(
                isAllProductsSelected
                    ? 'Generate Single Barcode'
                    : 'Generate & Print',
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildBarcodeRows(List<Product> products) {
    List<Widget> rows = [];
    const int itemsPerRow = 3;

    for (int i = 0; i < products.length; i += itemsPerRow) {
      final endIndex = (i + itemsPerRow < products.length)
          ? i + itemsPerRow
          : products.length;
      final rowProducts = products.sublist(i, endIndex);

      rows.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: rowProducts.map((product) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        product.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF17A2B8),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: product.barcode,
                        width: 160,
                        height: 50,
                        drawText: true,
                        style: TextStyle(fontSize: 8, color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Code: ${product.barcode}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Color(0xFF6C757D),
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return rows;
  }

  String _generateAllProductsBarcodeData(List<Product> products) {
    final productData = products
        .map(
          (product) => {
            'id': product.id.toString(),
            'code': product.designCode,
            'name': product.title,
            'price': product.salePrice,
            'category': product.subCategoryId,
            'vendor': product.vendor.name ?? 'Vendor ${product.vendorId}',
            'quantity': product.openingStockQuantity,
          },
        )
        .toList();

    // Convert to JSON-like string that can be encoded in QR
    final data = {
      'type': 'all_products',
      'total_products': products.length,
      'timestamp': DateTime.now().toIso8601String(),
      'products': productData,
    };

    return data.toString();
  }

  void generateQRCode() {
    final selectedProducts = getSelectedProducts();
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one product to generate QR code',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show QR code generation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate QR Codes'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${selectedProducts.length} product(s) selected'),
                const SizedBox(height: 16),
                // Show QR code preview for first selected product
                if (selectedProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          selectedProducts[0].title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF17A2B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        QrImageView(
                          data: _generateProductQRData(selectedProducts[0]),
                          size: 120,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code: ${selectedProducts[0].designCode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'QR codes will be generated for ${selectedProducts.length} product(s)',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Generating QR codes for ${selectedProducts.length} products...',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1845),
                foregroundColor: Colors.white,
              ),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  String _generateProductQRData(Product product) {
    final qrData = {
      'product_id': product.id,
      'title': product.title,
      'design_code': product.designCode,
      'barcode': product.barcode,
      'sale_price': product.salePrice,
      'buying_price': product.buyingPrice ?? 0,
      'opening_stock_quantity': product.openingStockQuantity,
      'vendor': {
        'id': product.vendorId,
        'name': product.vendor.name ?? 'Vendor ${product.vendorId}',
      },
      'category': product.subCategoryId,
      'images': product.imagePaths ?? [],
      'qr_code_data': product.qrCodeData,
      'status': product.status,
      'created_at': product.createdAt,
    };

    return jsonEncode(qrData);
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF0D1845),
    );
  }

  TextStyle _cellStyle() {
    return const TextStyle(fontSize: 12, color: Color(0xFF6C757D));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Barcode'),
        backgroundColor: const Color(0xFF0D1845),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF8F9FA)],
          ),
        ),
        child: Column(
          children: [
            // Header with Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF0D1845).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Print Barcode',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Generate barcodes and QR codes for your products',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: generateAndPrintBarcode,
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: const Text('Generate & Print Barcode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0D1845),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Summary Cards
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Total Products',
                        _allProductsCache.length.toString(),
                        Icons.inventory,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Selected Products',
                        getSelectedProducts().length.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Filtered Products',
                        _filteredProducts.length.toString(),
                        Icons.filter_list,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search and Table
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search and Filters Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search by product name, code...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButton<String>(
                                  value: selectedCategory,
                                  underline: const SizedBox(),
                                  items:
                                      [
                                            'All',
                                            'Computers',
                                            'Electronics',
                                            'Shoe',
                                          ]
                                          .map(
                                            (category) =>
                                                DropdownMenuItem<String>(
                                                  value: category,
                                                  child: Text(category),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedCategory = value;
                                      });
                                      _applyFilters();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButton<String>(
                                  value: selectedVendor,
                                  underline: const SizedBox(),
                                  items:
                                      [
                                            'All',
                                            'Lenovo',
                                            'Beats',
                                            'Nike',
                                            'Dell',
                                            'Apple',
                                          ]
                                          .map(
                                            (vendor) =>
                                                DropdownMenuItem<String>(
                                                  value: vendor,
                                                  child: Text(vendor),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedVendor = value;
                                      });
                                      _applyFilters();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: generateQRCode,
                                icon: const Icon(Icons.qr_code, size: 16),
                                label: const Text('Generate QR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Selection Controls
                          Row(
                            children: [
                              Checkbox(
                                value: selectAll,
                                onChanged: (value) => toggleSelectAll(value),
                                activeColor: const Color(0xFF0D1845),
                              ),
                              Text(
                                'Select All',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF343A40),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: const Color(0xFF1976D2),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${getSelectedProducts().length} product(s) selected',
                                      style: TextStyle(
                                        color: const Color(0xFF1976D2),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Select Column - Fixed width
                          SizedBox(
                            width: 60,
                            child: Text('Select', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          // Product Code Column
                          Expanded(
                            flex: 2,
                            child: Text('Product Code', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          // Product Name Column
                          Expanded(
                            flex: 3,
                            child: Text('Product Name', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          // Category Column
                          Expanded(
                            flex: 2,
                            child: Text('Category', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          // Vendor Column
                          Expanded(
                            flex: 2,
                            child: Text('Vendor', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          // Price Column - Centered
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Price', style: _headerStyle()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Unit Column - Centered
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Unit', style: _headerStyle()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Qty Column - Centered
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Qty', style: _headerStyle()),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchAllProductsOnInit,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isFilterActive
                                        ? 'No products match your filters'
                                        : 'No products found',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  if (_isFilterActive) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          selectedCategory = 'All';
                                          selectedVendor = 'All';
                                          _isFilterActive = false;
                                        });
                                        _applyFilters();
                                      },
                                      child: const Text('Clear Filters'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final quantity =
                                    int.tryParse(
                                      product.openingStockQuantity,
                                    ) ??
                                    0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0
                                        ? Colors.white
                                        : Colors.grey[50],
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Select Column - Fixed width
                                      SizedBox(
                                        width: 60,
                                        child: Checkbox(
                                          value: selectedProductCodes.contains(
                                            product.designCode,
                                          ),
                                          onChanged: (value) =>
                                              toggleProductSelection(
                                                product.designCode,
                                                value,
                                              ),
                                          activeColor: const Color(0xFF0D1845),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Product Code Column
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F9FA),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          child: Text(
                                            product.designCode,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D1845),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Product Name Column
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              product.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF343A40),
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Code: ${product.designCode}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF6C757D),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Category Column
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _getCategoryColor(
                                                  product.subCategoryId
                                                      .toString(),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Category ${product.subCategoryId}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF495057),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Vendor Column
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          product.vendor.name ??
                                              'Vendor ${product.vendorId}',
                                          style: _cellStyle(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Price Column - Centered
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Text(
                                            'PKR ${product.salePrice}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF28A745),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Unit Column - Centered
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8F9FA),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: const Text(
                                              'Pc',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF6C757D),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Qty Column - Centered
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: quantity < 50
                                                  ? const Color(0xFFFFF3CD)
                                                  : const Color(0xFFD4EDDA),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              quantity.toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: quantity < 50
                                                    ? const Color(0xFF856404)
                                                    : const Color(0xFF155724),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Enhanced Pagination
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous button
                  ElevatedButton.icon(
                    onPressed: currentPage > 1
                        ? () => _changePage(currentPage - 1)
                        : null,
                    icon: Icon(Icons.chevron_left, size: 14),
                    label: Text('Previous', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: currentPage > 1
                          ? const Color(0xFF0D1845)
                          : const Color(0xFF6C757D),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Page numbers
                  ..._buildPageButtons(),

                  const SizedBox(width: 8),

                  // Next button
                  ElevatedButton.icon(
                    onPressed:
                        (productResponse?.meta != null &&
                            currentPage < productResponse!.meta.lastPage)
                        ? () => _changePage(currentPage + 1)
                        : null,
                    icon: Icon(Icons.chevron_right, size: 14),
                    label: Text('Next', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (productResponse?.meta != null &&
                              currentPage < productResponse!.meta.lastPage)
                          ? const Color(0xFF0D1845)
                          : Colors.grey.shade300,
                      foregroundColor:
                          (productResponse?.meta != null &&
                              currentPage < productResponse!.meta.lastPage)
                          ? Colors.white
                          : Colors.grey.shade600,
                      elevation:
                          (productResponse?.meta != null &&
                              currentPage < productResponse!.meta.lastPage)
                          ? 2
                          : 0,
                      side:
                          (productResponse?.meta != null &&
                              currentPage < productResponse!.meta.lastPage)
                          ? null
                          : const BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),

                  // Page info
                  if (productResponse != null) ...[
                    const SizedBox(width: 16),
                    Builder(
                      builder: (context) {
                        final meta = productResponse!.meta;
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Page $currentPage of ${meta.lastPage} (${meta.total} total)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6C757D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Computers':
        return Color(0xFF17A2B8);
      case 'Electronics':
        return Color(0xFF28A745);
      case 'Shoe':
        return Color(0xFFDC3545);
      default:
        return Color(0xFF6C757D);
    }
  }

  List<Widget> _buildPageButtons() {
    if (productResponse?.meta == null) {
      return [];
    }

    final meta = productResponse!.meta;
    final totalPages = meta.lastPage;
    final current = meta.currentPage;

    // Show max 5 page buttons centered around current page
    const maxButtons = 5;
    final halfRange = maxButtons ~/ 2; // 2

    // Calculate desired start and end
    int startPage = (current - halfRange).clamp(1, totalPages);
    int endPage = (startPage + maxButtons - 1).clamp(1, totalPages);

    // If endPage exceeds totalPages, adjust startPage
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = (endPage - maxButtons + 1).clamp(1, totalPages);
    }

    List<Widget> buttons = [];

    for (int i = startPage; i <= endPage; i++) {
      buttons.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal: 1),
          child: ElevatedButton(
            onPressed: i == current ? null : () => _changePage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor: i == current
                  ? const Color(0xFF0D1845)
                  : Colors.white,
              foregroundColor: i == current
                  ? Colors.white
                  : const Color(0xFF6C757D),
              elevation: i == current ? 2 : 0,
              side: i == current
                  ? null
                  : const BorderSide(color: Color(0xFFDEE2E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(32, 32),
            ),
            child: Text(
              i.toString(),
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
        ),
      );
    }

    return buttons;
  }
}

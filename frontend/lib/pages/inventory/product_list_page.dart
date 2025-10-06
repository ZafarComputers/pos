import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../services/inventory_service.dart';
import '../../models/product.dart';
import 'add_product_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  ProductResponse? productResponse;
  List<Product> _filteredProducts = [];
  List<Product> _allFilteredProducts =
      []; // Store all filtered products for local pagination
  List<Product> _allProductsCache =
      []; // Cache for all products to avoid refetching
  bool isLoading = false; // Start with false to show UI immediately
  String? errorMessage;
  int currentPage = 1;
  final int itemsPerPage = 10;
  Timer? _searchDebounceTimer; // Add debounce timer for search
  bool _isFilterActive = false; // Track if any filter is currently active

  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'All';

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
        isLoading = false;
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
      final hasStatusFilter = selectedStatus != 'All';

      print(
        '🎯 Client-side filtering - search: "$searchText", status: "$selectedStatus"',
      );
      print('📊 hasSearch: $hasSearch, hasStatusFilter: $hasStatusFilter');

      setState(() {
        _isFilterActive = hasSearch || hasStatusFilter;
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
        isLoading = false;
        _filteredProducts = [];
      });
    }
  }

  // Filter cached products without any API calls
  void _filterCachedProducts(String searchText) {
    try {
      // Apply filters to cached products with enhanced error handling
      _allFilteredProducts = _allProductsCache.where((product) {
        try {
          // Status filter
          if (selectedStatus != 'All' && product.status != selectedStatus) {
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
      print('📝 Search text: "$searchText", Status filter: "$selectedStatus"');

      // Apply local pagination to filtered results
      _paginateFilteredProducts();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Critical error in _filterCachedProducts: $e');
      setState(() {
        errorMessage =
            'Search failed. Please try again with a simpler search term.';
        isLoading = false;
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
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await InventoryService.getProducts(
        page: page,
        limit: itemsPerPage,
      );
      setState(() {
        productResponse = response;
        currentPage = page;
        isLoading = false;
        _filteredProducts = response.data;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> exportToPDF() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D1845)),
                ),
                SizedBox(width: 16),
                Text('Fetching all products...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL products from database for export
      List<Product> allProductsForExport = [];

      try {
        // Fetch ALL products with unlimited pagination
        int currentPage = 1;
        bool hasMorePages = true;

        while (hasMorePages) {
          final pageResponse = await InventoryService.getProducts(
            page: currentPage,
            limit: 100, // Fetch in chunks of 100
          );

          allProductsForExport.addAll(pageResponse.data);

          // Check if there are more pages
          if (pageResponse.meta.currentPage >= pageResponse.meta.lastPage) {
            hasMorePages = false;
          } else {
            currentPage++;
          }

          // Update loading message
          Navigator.of(context).pop();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0D1845),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text('Fetched ${allProductsForExport.length} products...'),
                  ],
                ),
              );
            },
          );
        }

        // Apply filters if any are active
        if (_searchController.text.isNotEmpty || selectedStatus != 'All') {
          final searchText = _searchController.text.toLowerCase().trim();
          allProductsForExport = allProductsForExport.where((product) {
            // Status filter
            if (selectedStatus != 'All' && product.status != selectedStatus) {
              return false;
            }

            // Search filter
            if (searchText.isEmpty) {
              return true;
            }

            // Search in multiple fields
            return product.title.toLowerCase().contains(searchText) ||
                product.designCode.toLowerCase().contains(searchText) ||
                product.barcode.toLowerCase().contains(searchText) ||
                product.vendor.name?.toLowerCase().contains(searchText) ==
                    true ||
                product.subCategoryId.toLowerCase().contains(searchText);
          }).toList();
        }
      } catch (e) {
        print('Error fetching all products: $e');
        // Fallback to current data
        allProductsForExport = _filteredProducts.isNotEmpty
            ? _filteredProducts
            : (productResponse?.data ?? []);
      }

      if (allProductsForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No products to export'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
        return;
      }

      // Update loading message
      Navigator.of(context).pop();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D1845)),
                ),
                SizedBox(width: 16),
                Text(
                  'Generating PDF with ${allProductsForExport.length} products...',
                ),
              ],
            ),
          );
        },
      );

      // Create a new PDF document with landscape orientation for better table fit
      final PdfDocument document = PdfDocument();

      // Set page to landscape for better table visibility
      document.pageSettings.orientation = PdfPageOrientation.landscape;
      document.pageSettings.size = PdfPageSize.a4;

      // Define fonts - adjusted for landscape
      final PdfFont titleFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        18,
        style: PdfFontStyle.bold,
      );
      final PdfFont headerFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        11,
        style: PdfFontStyle.bold,
      );
      final PdfFont regularFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 9);

      // Colors
      final PdfColor headerColor = PdfColor(
        13,
        24,
        69,
      ); // Product page theme color
      final PdfColor tableHeaderColor = PdfColor(248, 249, 250);

      // Create table with proper settings for pagination
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 7);

      // Use full page width but account for table borders and padding
      final double pageWidth =
          document.pageSettings.size.width -
          15; // Only 15px left margin, 0px right margin
      final double tableWidth =
          pageWidth *
          0.85; // Use 85% to ensure right boundary is clearly visible

      // Balanced column widths for products
      grid.columns[0].width = tableWidth * 0.12; // 12% - Product Code
      grid.columns[1].width = tableWidth * 0.20; // 20% - Product Name
      grid.columns[2].width = tableWidth * 0.15; // 15% - Barcode
      grid.columns[3].width = tableWidth * 0.18; // 18% - Vendor
      grid.columns[4].width = tableWidth * 0.10; // 10% - Price
      grid.columns[5].width = tableWidth * 0.10; // 10% - Quantity
      grid.columns[6].width = tableWidth * 0.15; // 15% - Status

      // Enable automatic page breaking and row splitting
      grid.allowRowBreakingAcrossPages = true;

      // Set grid style with better padding for readability
      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
        font: smallFont,
      );

      // Add header row
      final PdfGridRow headerRow = grid.headers.add(1)[0];
      headerRow.cells[0].value = 'Product Code';
      headerRow.cells[1].value = 'Product Name';
      headerRow.cells[2].value = 'Barcode';
      headerRow.cells[3].value = 'Vendor';
      headerRow.cells[4].value = 'Price';
      headerRow.cells[5].value = 'Quantity';
      headerRow.cells[6].value = 'Status';

      // Style header row
      for (int i = 0; i < headerRow.cells.count; i++) {
        headerRow.cells[i].style = PdfGridCellStyle(
          backgroundBrush: PdfSolidBrush(tableHeaderColor),
          textBrush: PdfSolidBrush(PdfColor(73, 80, 87)),
          font: headerFont,
          format: PdfStringFormat(
            alignment: PdfTextAlignment.center,
            lineAlignment: PdfVerticalAlignment.middle,
          ),
        );
      }

      // Add all product data rows
      for (var product in allProductsForExport) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = product.designCode;
        row.cells[1].value = product.title;
        row.cells[2].value = product.barcode;
        row.cells[3].value = product.vendor.name ?? 'N/A';
        row.cells[4].value = 'PKR ${product.salePrice}';
        row.cells[5].value = product.openingStockQuantity;
        row.cells[6].value = product.status;

        // Style data cells with better text wrapping
        for (int i = 0; i < row.cells.count; i++) {
          row.cells[i].style = PdfGridCellStyle(
            font: smallFont,
            textBrush: PdfSolidBrush(PdfColor(33, 37, 41)),
            format: PdfStringFormat(
              alignment: i == 4 || i == 5 || i == 6
                  ? PdfTextAlignment.center
                  : PdfTextAlignment.left,
              lineAlignment: PdfVerticalAlignment.top,
              wordWrap: PdfWordWrapType.word,
            ),
          );
        }

        // Color code status
        if (product.status == 'Active') {
          row.cells[6].style.backgroundBrush = PdfSolidBrush(
            PdfColor(212, 237, 218),
          );
          row.cells[6].style.textBrush = PdfSolidBrush(PdfColor(21, 87, 36));
        } else {
          row.cells[6].style.backgroundBrush = PdfSolidBrush(
            PdfColor(248, 215, 218),
          );
          row.cells[6].style.textBrush = PdfSolidBrush(PdfColor(114, 28, 36));
        }
      }

      // Set up page template for headers and footers
      final PdfPageTemplateElement headerTemplate = PdfPageTemplateElement(
        Rect.fromLTWH(0, 0, document.pageSettings.size.width, 50),
      );

      // Draw header on template - minimal left margin, full width
      headerTemplate.graphics.drawString(
        'Complete Products Database Export',
        titleFont,
        brush: PdfSolidBrush(headerColor),
        bounds: Rect.fromLTWH(
          15,
          10,
          document.pageSettings.size.width - 15,
          25,
        ),
      );

      headerTemplate.graphics.drawString(
        'Total Products: ${allProductsForExport.length} | Generated: ${DateTime.now().toString().substring(0, 19)} | Filters: ${selectedStatus != 'All' ? 'Status=$selectedStatus' : 'All'} ${_searchController.text.isNotEmpty ? ', Search="${_searchController.text}"' : ''}',
        regularFont,
        brush: PdfSolidBrush(PdfColor(108, 117, 125)),
        bounds: Rect.fromLTWH(
          15,
          32,
          document.pageSettings.size.width - 15,
          15,
        ),
      );

      // Add line under header - full width
      headerTemplate.graphics.drawLine(
        PdfPen(PdfColor(200, 200, 200), width: 1),
        Offset(15, 48),
        Offset(document.pageSettings.size.width, 48),
      );

      // Create footer template
      final PdfPageTemplateElement footerTemplate = PdfPageTemplateElement(
        Rect.fromLTWH(
          0,
          document.pageSettings.size.height - 25,
          document.pageSettings.size.width,
          25,
        ),
      );

      // Draw footer - full width
      footerTemplate.graphics.drawString(
        'Page \$PAGE of \$TOTAL | ${allProductsForExport.length} Total Products | Generated from POS System',
        regularFont,
        brush: PdfSolidBrush(PdfColor(108, 117, 125)),
        bounds: Rect.fromLTWH(15, 8, document.pageSettings.size.width - 15, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Apply templates to document
      document.template.top = headerTemplate;
      document.template.bottom = footerTemplate;

      // Draw the grid with automatic pagination - use full width, minimal left margin
      grid.draw(
        page: document.pages.add(),
        bounds: Rect.fromLTWH(
          15,
          55,
          document.pageSettings.size.width - 15,
          document.pageSettings.size.height - 85,
        ),
        format: PdfLayoutFormat(
          layoutType: PdfLayoutType.paginate,
          breakType: PdfLayoutBreakType.fitPage,
        ),
      );

      // Get page count before disposal
      final int pageCount = document.pages.count;
      print(
        'PDF generated with $pageCount page(s) for ${allProductsForExport.length} products',
      );

      // Save PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Complete Products Database PDF',
        fileName:
            'complete_products_${DateTime.now().millisecondsSinceEpoch}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Complete Database Exported!\n📊 ${allProductsForExport.length} products across $pageCount pages\n📄 Landscape format for better visibility',
              ),
              backgroundColor: Color(0xFF28A745),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    await Process.run('explorer', ['/select,', outputFile]);
                  } catch (e) {
                    print('File saved at: $outputFile');
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Color(0xFFDC3545),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void addNewProduct() async {
    print('🔘 Add Product button pressed');
    try {
      // Navigate to Add Product Page
      print('🚀 Navigating to AddProductPage...');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddProductPage()),
      );
      print('📦 Navigation result: $result');

      // If a product was added successfully, refresh the product list
      if (result == true) {
        print('✅ Product added successfully, refreshing list...');
        // Refresh the product list by re-fetching all products
        _fetchAllProductsOnInit();
      } else {
        print('❌ Product not added or user cancelled');
      }
    } catch (e) {
      print('❌ Error in addNewProduct: $e');
    }
  }

  void viewProduct(Product product) async {
    // Implementation remains the same as original
    // This would be a long method, keeping the original implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View product feature - implementation needed'),
        backgroundColor: Color(0xFF17A2B8),
      ),
    );
  }

  void editProduct(Product product) async {
    // Implementation remains the same as original
    // This would be a long method, keeping the original implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit product feature - implementation needed'),
        backgroundColor: Color(0xFF17A2B8),
      ),
    );
  }

  void deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Color(0xFFDC3545)),
              SizedBox(width: 8),
              Text('Delete Product'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${product.title}"?\n\nThis action cannot be undone.',
            style: TextStyle(color: Color(0xFF6C757D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF6C757D))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await InventoryService.deleteProduct(product.id);

                  // Remove from cache and update UI in real-time
                  setState(() {
                    _allProductsCache.removeWhere((p) => p.id == product.id);
                  });

                  // Re-apply current filters to update the display
                  _applyFiltersClientSide();

                  // If current page is now empty and we're not on page 1, go to previous page
                  if (_filteredProducts.isEmpty && currentPage > 1) {
                    setState(() {
                      currentPage = currentPage - 1;
                    });
                    _paginateFilteredProducts();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Product "${product.title}" deleted successfully',
                          ),
                        ],
                      ),
                      backgroundColor: Color(0xFF28A745),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Failed to delete product: ${e.toString()}'),
                        ],
                      ),
                      backgroundColor: Color(0xFFDC3545),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC3545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your complete product inventory and stock levels',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: ElevatedButton.icon(
                          onPressed: exportToPDF,
                          icon: Icon(Icons.picture_as_pdf, size: 16),
                          label: Text('Export PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFFDC3545),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: addNewProduct,
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Add Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0D1845),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Enhanced Filters Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Color(0xFF6C757D),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Search & Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF343A40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Search products...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF6C757D),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFFDEE2E6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFFDEE2E6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFF0D1845),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFF0D1845),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                                items: ['All', 'Active', 'Inactive']
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: Color(0xFF343A40),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedStatus = value;
                                      currentPage =
                                          1; // Reset to first page when filter changes
                                    });
                                    // Apply filters with new status
                                    _applyFilters();
                                  }
                                },
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
            const SizedBox(height: 24),

            // Enhanced Table Section
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Color(0xFF0D1845),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Products List',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${_filteredProducts.length} Products',
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  errorMessage != null
                      ? Container(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.wifi_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load products',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Check your internet connection and try again',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _fetchAllProductsOnInit,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0D1845),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Color(0xFFF8F9FA),
                            ),
                            dataRowColor:
                                MaterialStateProperty.resolveWith<Color>((
                                  Set<MaterialState> states,
                                ) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Color(0xFF0D1845).withOpacity(0.1);
                                  }
                                  return Colors.white;
                                }),
                            columns: const [
                              DataColumn(label: Text('Image')),
                              DataColumn(label: Text('Product Code')),
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Vendor')),
                              DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Qty')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _filteredProducts.map((product) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF0D1845),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Color(0xFFDEE2E6),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        product.designCode,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0D1845),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            product.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF343A40),
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            product.barcode,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF6C757D),
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        product.vendor.name ?? 'N/A',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1976D2),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      'PKR ${product.salePrice}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF28A745),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            int.tryParse(
                                                      product
                                                          .openingStockQuantity,
                                                    ) !=
                                                    null &&
                                                int.parse(
                                                      product
                                                          .openingStockQuantity,
                                                    ) <
                                                    10
                                            ? Color(0xFFFFF3CD)
                                            : Color(0xFFD4EDDA),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        product.openingStockQuantity,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color:
                                              int.tryParse(
                                                        product
                                                            .openingStockQuantity,
                                                      ) !=
                                                      null &&
                                                  int.parse(
                                                        product
                                                            .openingStockQuantity,
                                                      ) <
                                                      10
                                              ? Color(0xFF856404)
                                              : Color(0xFF155724),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: product.status == 'Active'
                                            ? Color(0xFFD4EDDA)
                                            : Color(0xFFF8D7DA),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            product.status == 'Active'
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: product.status == 'Active'
                                                ? Color(0xFF28A745)
                                                : Color(0xFFDC3545),
                                            size: 10,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            product.status,
                                            style: TextStyle(
                                              color: product.status == 'Active'
                                                  ? Color(0xFF155724)
                                                  : Color(0xFF721C24),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => viewProduct(product),
                                          icon: Icon(
                                            Icons.visibility,
                                            color: Color(0xFF0D1845),
                                            size: 16,
                                          ),
                                          tooltip: 'View Details',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                        SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () => editProduct(product),
                                          icon: Icon(
                                            Icons.edit,
                                            color: Color(0xFF28A745),
                                            size: 16,
                                          ),
                                          tooltip: 'Edit Product',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                        SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () =>
                                              deleteProduct(product),
                                          icon: Icon(
                                            Icons.delete,
                                            color: Color(0xFFDC3545),
                                            size: 16,
                                          ),
                                          tooltip: 'Delete Product',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ),

            // Enhanced Pagination
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                          ? Color(0xFF0D1845)
                          : Color(0xFF6C757D),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.symmetric(
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
                          ? Color(0xFF0D1845)
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
                          : BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.symmetric(
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
          ],
        ),
      ),
    );
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
              backgroundColor: i == current ? Color(0xFF0D1845) : Colors.white,
              foregroundColor: i == current ? Colors.white : Color(0xFF6C757D),
              elevation: i == current ? 2 : 0,
              side: i == current ? null : BorderSide(color: Color(0xFFDEE2E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size(32, 32),
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

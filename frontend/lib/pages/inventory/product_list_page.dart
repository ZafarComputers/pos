import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:provider/provider.dart';
import '../../services/inventory_service.dart';
import '../../models/product.dart';
import '../../models/sub_category.dart';
import '../../models/vendor.dart' as vendor;
import '../../providers/providers.dart';
import 'add_product_page.dart';
import 'product_details_page.dart';

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

  // Image-related state variables
  File? _selectedImage;
  String? _imagePath;

  // Sub categories and vendors for dropdowns
  List<SubCategory> _subCategories = [];
  List<vendor.Vendor> _vendors = [];

  @override
  void initState() {
    super.initState();
    _fetchAllProductsOnInit(); // Fetch all products once on page load
    _fetchSubCategories();
    _fetchVendors();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  Future<Uint8List?> _loadProductImage(String imagePath) async {
    try {
      // Extract filename from any path format
      String filename;
      if (imagePath.contains('/')) {
        // If it contains slashes, take the last part after the last /
        filename = imagePath.split('/').last;
      } else {
        // Use as is if no slashes
        filename = imagePath;
      }

      // Remove any query parameters
      if (filename.contains('?')) {
        filename = filename.split('?').first;
      }

      print('🖼️ Extracted filename: $filename from path: $imagePath');

      // Check if file exists in local products directory
      final file = File('assets/images/products/$filename');
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        // Try to load from network if it's a valid URL
        if (imagePath.startsWith('http')) {
          // For now, return null to show default icon
          // In future, could implement network loading with caching
        }
      }
    } catch (e) {
      // Error loading image
    }
    return null;
  }

  Future<void> _fetchSubCategories() async {
    try {
      final response = await InventoryService.getSubCategories(limit: 1000);
      setState(() {
        _subCategories = response.data;
      });
    } catch (e) {
      print('Error fetching sub categories: $e');
      // Don't show error to user, just use empty list
      setState(() {
        _subCategories = [];
      });
    }
  }

  Future<void> _fetchVendors() async {
    try {
      final response = await InventoryService.getVendors(limit: 1000);
      setState(() {
        _vendors = response.data;
      });
      print('📦 Fetched ${_vendors.length} vendors');

      // Populate vendor data for cached products if they exist
      if (_allProductsCache.isNotEmpty) {
        _populateVendorDataForProducts();
      }
    } catch (e) {
      print('Error fetching vendors: $e');
      // Don't show error to user, just use empty list
      setState(() {
        _vendors = [];
      });
    }
  }

  // Populate vendor data for products by matching vendor IDs
  void _populateVendorDataForProducts() {
    if (_vendors.isEmpty || _allProductsCache.isEmpty) {
      print('⚠️ Cannot populate vendor data: vendors or products not loaded');
      return;
    }

    print('🔗 Populating vendor data for ${_allProductsCache.length} products');

    // Create a map for faster vendor lookup
    final vendorMap = {for (var vendor in _vendors) vendor.id: vendor};

    // Update products with vendor data
    for (int i = 0; i < _allProductsCache.length; i++) {
      final product = _allProductsCache[i];
      final vendorId = int.tryParse(product.vendorId);

      if (vendorId != null && vendorMap.containsKey(vendorId)) {
        final vendor = vendorMap[vendorId]!;
        // Create a new product with populated vendor data
        _allProductsCache[i] = Product(
          id: product.id,
          title: product.title,
          designCode: product.designCode,
          imagePath: product.imagePath,
          subCategoryId: product.subCategoryId,
          salePrice: product.salePrice,
          openingStockQuantity: product.openingStockQuantity,
          vendorId: product.vendorId,
          vendor: ProductVendor(
            id: vendor.id,
            name: vendor.fullName, // Use fullName from Vendor model
            email: null, // Vendor model doesn't have email
            phone: null, // Vendor model doesn't have phone
            address: vendor.address,
            status: vendor.status,
            createdAt: vendor.createdAt,
            updatedAt: vendor.updatedAt,
          ),
          barcode: product.barcode,
          status: product.status,
          createdAt: product.createdAt,
          updatedAt: product.updatedAt,
        );
      } else {
        print(
          '⚠️ No vendor found for product "${product.title}" with vendorId: ${product.vendorId}',
        );
      }
    }

    print('✅ Vendor data populated for products');

    // Re-apply current filters to update the display
    _applyFiltersClientSide();
  }

  // Fetch all products once when page loads
  Future<void> _fetchAllProductsOnInit() async {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );

    if (inventoryProvider.products.isNotEmpty) {
      print('📦 Using pre-fetched products from provider');
      setState(() {
        _allProductsCache = inventoryProvider.products;
      });
      _populateVendorDataForProducts();
      _applyFiltersClientSide();
    } else {
      print('🚀 Pre-fetch not available, fetching products');
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

        // Populate vendor data for all products
        _populateVendorDataForProducts();

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
  }

  // Force refresh products from server after adding new product
  Future<void> _refreshProductsAfterAdd() async {
    try {
      print('🔄 Force refreshing products after add');
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Always fetch fresh data from server, ignore provider cache
      List<Product> allProducts = [];
      int currentFetchPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        print('📄 Force fetching page $currentFetchPage after add');
        final response = await InventoryService.getProducts(
          page: currentFetchPage,
          limit: 100,
        );

        allProducts.addAll(response.data);
        hasMorePages = response.meta.currentPage < response.meta.lastPage;
        currentFetchPage++;
      }

      setState(() {
        _allProductsCache = allProducts;
        print(
          '💾 Refreshed cache with ${_allProductsCache.length} total products',
        );
      });

      // Populate vendor data for all products
      _populateVendorDataForProducts();

      // Reset to page 1 and apply current filters
      setState(() {
        currentPage = 1;
      });
      _applyFiltersClientSide();

      print('✅ Product list refreshed successfully after add');
    } catch (e) {
      print('❌ Error refreshing products after add: $e');
      setState(() {
        errorMessage = 'Failed to refresh products: $e';
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

  Future<void> exportToExcel() async {
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
                  'Generating Excel with ${allProductsForExport.length} products...',
                ),
              ],
            ),
          );
        },
      );

      // Create Excel document
      final excel_pkg.Excel excel = excel_pkg.Excel.createExcel();
      final excel_pkg.Sheet sheet = excel['Products'];

      // Add header row with styling
      final headerStyle = excel_pkg.CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: excel_pkg.HorizontalAlign.Center,
      );

      sheet.appendRow([
        excel_pkg.TextCellValue('Product Code'),
        excel_pkg.TextCellValue('Product Name'),
        excel_pkg.TextCellValue('Barcode'),
        excel_pkg.TextCellValue('Vendor'),
        excel_pkg.TextCellValue('Price'),
        excel_pkg.TextCellValue('Quantity'),
        excel_pkg.TextCellValue('Status'),
      ]);

      // Apply header styling
      for (int i = 0; i < 7; i++) {
        sheet
                .cell(
                  excel_pkg.CellIndex.indexByColumnRow(
                    columnIndex: i,
                    rowIndex: 0,
                  ),
                )
                .cellStyle =
            headerStyle;
      }

      // Add all product data rows
      for (var product in allProductsForExport) {
        sheet.appendRow([
          excel_pkg.TextCellValue(product.designCode),
          excel_pkg.TextCellValue(product.title),
          excel_pkg.TextCellValue(product.barcode),
          excel_pkg.TextCellValue(product.vendor.name ?? 'N/A'),
          excel_pkg.TextCellValue('PKR ${product.salePrice}'),
          excel_pkg.TextCellValue(product.openingStockQuantity),
          excel_pkg.TextCellValue(product.status),
        ]);
      }

      // Save Excel file
      final List<int>? bytes = excel.save();
      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Complete Products Database Excel',
        fileName:
            'complete_products_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Complete Database Exported!\n📊 ${allProductsForExport.length} products exported to Excel\n📄 Spreadsheet format for easy data manipulation',
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

  void addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          onProductAdded: () {
            // Force refresh the product list from server after adding new product
            _refreshProductsAfterAdd();
          },
        ),
      ),
    );
  }

  void viewProduct(Product product) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          product: product,
          subCategories: _subCategories,
          vendors: _vendors,
        ),
      ),
    );
  }

  void editProduct(Product product) async {
    final titleController = TextEditingController(text: product.title);
    final designCodeController = TextEditingController(
      text: product.designCode,
    );
    final subCategoryIdController = TextEditingController(
      text: product.subCategoryId,
    );
    final salePriceController = TextEditingController(text: product.salePrice);
    final openingStockQuantityController = TextEditingController(
      text: product.openingStockQuantity,
    );
    final barcodeController = TextEditingController(text: product.barcode);

    String selectedStatus = product.status;
    int? selectedVendorId = int.tryParse(product.vendorId);

    // Reset image state for editing
    _selectedImage = null;
    _imagePath = product.imagePath;

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF28A745)),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF343A40),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Product Title *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: designCodeController,
                      decoration: InputDecoration(
                        labelText: 'Design Code *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subCategoryIdController,
                      decoration: InputDecoration(
                        labelText: 'Sub Category ID *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: salePriceController,
                      decoration: InputDecoration(
                        labelText: 'Sale Price *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: openingStockQuantityController,
                      decoration: InputDecoration(
                        labelText: 'Opening Stock Quantity *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Image Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Image (optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        SizedBox(height: 8),
                        if (_selectedImage != null)
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFDEE2E6)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else if (_imagePath != null && _imagePath!.isNotEmpty)
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFDEE2E6)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                _imagePath!.startsWith('http') &&
                                    !_imagePath!.contains('zafarcomputers.com')
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _imagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.inventory_2,
                                            color: Color(0xFF6C757D),
                                            size: 48,
                                          ),
                                    ),
                                  )
                                : FutureBuilder<Uint8List?>(
                                    future: _loadProductImage(_imagePath!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      } else if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      } else {
                                        return Icon(
                                          Icons.inventory_2,
                                          color: Color(0xFF6C757D),
                                          size: 48,
                                        );
                                      }
                                    },
                                  ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFDEE2E6)),
                              borderRadius: BorderRadius.circular(8),
                              color: Color(0xFFF8F9FA),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  color: Color(0xFF6C757D),
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No image selected',
                                  style: TextStyle(color: Color(0xFF6C757D)),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (pickedFile != null) {
                              final imageFile = File(pickedFile.path);
                              // Save to local storage
                              try {
                                final directory = Directory(
                                  '${Directory.current.path}/assets/images/products',
                                );
                                if (!await directory.exists()) {
                                  await directory.create(recursive: true);
                                }
                                final fileName =
                                    'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                final savedImage = await imageFile.copy(
                                  '${directory.path}/$fileName',
                                );
                                setState(() {
                                  _selectedImage = savedImage;
                                  _imagePath =
                                      'https://zafarcomputers.com/assets/images/products/$fileName';
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to save image: $e'),
                                    backgroundColor: Color(0xFFDC3545),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.photo_library),
                          label: Text(
                            _selectedImage != null ||
                                    (_imagePath != null &&
                                        _imagePath!.isNotEmpty)
                                ? 'Change Image'
                                : 'Select Image',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0D1845),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedVendorId,
                      decoration: InputDecoration(
                        labelText: 'Vendor',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Select Vendor (optional)'),
                        ),
                        ..._vendors.map(
                          (vendor) => DropdownMenuItem<int>(
                            value: vendor.id,
                            child: Text(vendor.fullName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedVendorId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: ['Active', 'Inactive']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF6C757D)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty ||
                        designCodeController.text.trim().isEmpty ||
                        subCategoryIdController.text.trim().isEmpty ||
                        salePriceController.text.trim().isEmpty ||
                        openingStockQuantityController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Color(0xFFDC3545),
                        ),
                      );
                      return;
                    }

                    try {
                      setState(() => isLoading = true);
                      Navigator.of(context).pop(true); // Close dialog first

                      final updateData = {
                        'title': titleController.text.trim(),
                        'design_code': designCodeController.text.trim(),
                        'image_path': _imagePath,
                        'sub_category_id': int.parse(
                          subCategoryIdController.text.trim(),
                        ),
                        'sale_price': double.parse(
                          salePriceController.text.trim(),
                        ),
                        'opening_stock_quantity': int.parse(
                          openingStockQuantityController.text.trim(),
                        ),
                        'vendor_id': selectedVendorId,
                        'user_id': 1,
                        'barcode': barcodeController.text.trim(),
                        'status': selectedStatus,
                      };

                      await InventoryService.updateProduct(
                        product.id,
                        updateData,
                      );

                      // Refresh the products cache and apply current filters
                      await _fetchAllProductsOnInit();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Product updated successfully'),
                            ],
                          ),
                          backgroundColor: Color(0xFF28A745),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Failed to update product: $e'),
                            ],
                          ),
                          backgroundColor: Color(0xFFDC3545),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
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
                Navigator.of(context).pop(); // Close dialog first

                // Show loading indicator
                if (mounted) {
                  setState(() => isLoading = true);
                }

                try {
                  await InventoryService.deleteProduct(product.id);

                  // Remove from cache and update UI in real-time
                  if (mounted) {
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

                    // Show success message using scaffold key
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
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
                      }
                    });
                  }
                } catch (e) {
                  // Show error message using parent context
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
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
                  });
                } finally {
                  if (mounted) {
                    setState(() => isLoading = false);
                  }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
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
                          Icons.inventory,
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
                              'Products',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage your product inventory and details',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: addNewProduct,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add New Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D1845),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                        Icons.inventory_2,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Active Products',
                        _allProductsCache
                            .where((p) => p.status == 'Active')
                            .length
                            .toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Inactive Products',
                        _allProductsCache
                            .where((p) => p.status != 'Active')
                            .length
                            .toString(),
                        Icons.cancel,
                        Colors.red,
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
                                    hintText:
                                        'Search by title, code, barcode, vendor...',
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
                                  value: selectedStatus,
                                  underline: const SizedBox(),
                                  items: ['All', 'Active', 'Inactive']
                                      .map(
                                        (status) => DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(status),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedStatus = value;
                                      });
                                      _applyFilters();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: exportToPDF,
                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 16,
                                ),
                                label: const Text('Export PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: exportToExcel,
                                icon: const Icon(Icons.table_chart, size: 16),
                                label: const Text('Export Excel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isFilterActive) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1845).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.filter_list,
                                    size: 16,
                                    color: Color(0xFF0D1845),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filters applied',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0D1845),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _searchController.clear();
                                        selectedStatus = 'All';
                                        _isFilterActive = false;
                                      });
                                      _applyFilters();
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Color(0xFF0D1845),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          // Image Column - Fixed width to match body, increased for header text
                          SizedBox(
                            width: 60,
                            child: Text('Image', style: _headerStyle()),
                          ),
                          const SizedBox(
                            width: 100,
                          ), // Maximum extreme spacing between image and product details
                          // Product Details Column
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Product Details',
                              style: _headerStyle(),
                            ),
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
                          // Stock Column - Centered
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Stock', style: _headerStyle()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Status Column - Centered
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Status', style: _headerStyle()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Actions Column - Fixed width to match body
                          SizedBox(
                            width: 120,
                            child: Text('Actions', style: _headerStyle()),
                          ),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : errorMessage != null
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
                                          selectedStatus = 'All';
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
                                      // Image Column - Smaller size, increased width to match header
                                      SizedBox(
                                        width: 60,
                                        height: 40,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF0D1845,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child:
                                              (product.imagePath?.isNotEmpty ??
                                                  false)
                                              ? FutureBuilder<Uint8List?>(
                                                  future: _loadProductImage(
                                                    product.imagePath!,
                                                  ),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData &&
                                                        snapshot.data != null) {
                                                      return ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        child: Image.memory(
                                                          snapshot.data!,
                                                          fit: BoxFit.cover,
                                                          width: 36,
                                                          height: 36,
                                                        ),
                                                      );
                                                    }
                                                    return const Icon(
                                                      Icons.inventory_2,
                                                      color: Color(0xFF0D1845),
                                                      size: 20,
                                                    );
                                                  },
                                                )
                                              : const Icon(
                                                  Icons.inventory_2,
                                                  color: Color(0xFF0D1845),
                                                  size: 20,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 100,
                                      ), // Maximum extreme spacing between image and product details
                                      // Product Details Column
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0D1845),
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Code: ${product.designCode}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              'Barcode: ${product.barcode}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
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
                                          product.vendor.name ?? 'N/A',
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
                                            'Rs. ${product.salePrice}',
                                            style: _cellStyle(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Stock Column - Centered
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Text(
                                            product.openingStockQuantity,
                                            style: _cellStyle(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Status Column - Centered and compact
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 60,
                                            ),
                                            decoration: BoxDecoration(
                                              color: product.status == 'Active'
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              product.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    product.status == 'Active'
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Actions Column
                                      SizedBox(
                                        width: 120,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.visibility,
                                                color: const Color(0xFF0D1845),
                                                size: 16,
                                              ),
                                              onPressed: () =>
                                                  viewProduct(product),
                                              tooltip: 'View Details',
                                              padding: const EdgeInsets.all(4),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                                size: 16,
                                              ),
                                              onPressed: () =>
                                                  editProduct(product),
                                              tooltip: 'Edit',
                                              padding: const EdgeInsets.all(4),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 16,
                                              ),
                                              onPressed: () =>
                                                  deleteProduct(product),
                                              tooltip: 'Delete',
                                              padding: const EdgeInsets.all(4),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
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

            // Pagination Controls
            if (_allFilteredProducts.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
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
                      icon: const Icon(Icons.chevron_left, size: 16),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentPage > 1
                            ? const Color(0xFF0D1845)
                            : Colors.grey.shade300,
                        foregroundColor: currentPage > 1
                            ? Colors.white
                            : Colors.grey.shade600,
                        elevation: currentPage > 1 ? 2 : 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Page info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Page $currentPage of ${(_allFilteredProducts.length / itemsPerPage).ceil()} (${_allFilteredProducts.length} total)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6C757D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Next button
                    ElevatedButton.icon(
                      onPressed:
                          currentPage <
                              (_allFilteredProducts.length / itemsPerPage)
                                  .ceil()
                          ? () => _changePage(currentPage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 16),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            currentPage <
                                (_allFilteredProducts.length / itemsPerPage)
                                    .ceil()
                            ? const Color(0xFF0D1845)
                            : Colors.grey.shade300,
                        foregroundColor:
                            currentPage <
                                (_allFilteredProducts.length / itemsPerPage)
                                    .ceil()
                            ? Colors.white
                            : Colors.grey.shade600,
                        elevation:
                            currentPage <
                                (_allFilteredProducts.length / itemsPerPage)
                                    .ceil()
                            ? 2
                            : 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
}

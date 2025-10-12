import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:provider/provider.dart';
import '../../services/inventory_service.dart';
import '../../models/category.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../../providers/providers.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List<Category> categories = [];
  bool isLoading = false; // Start with false to show UI immediately
  String? errorMessage;
  int currentPage = 1;
  int totalCategories = 0;
  int totalPages = 1;
  final int itemsPerPage = 10;
  Timer? _searchDebounceTimer; // Add debounce timer for search
  bool _isFilterActive = false; // Track if any filter is currently active

  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'All';

  // Cache for all categories to avoid refetching
  List<Category> _allCategoriesCache = [];
  List<Category> _allFilteredCategories =
      []; // Store all filtered categories for local pagination

  // Image-related state variables
  File? _selectedImage;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _fetchAllCategoriesOnInit(); // Fetch all categories once on page load
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _loadCategoryImage(String imagePath) async {
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

      // Check if file exists in local categories directory
      final file = File('assets/images/categories/$filename');
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

  Future<void> _fetchCategories({int page = 1}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await InventoryService.getCategories(
        page: page,
        limit: itemsPerPage,
      );

      setState(() {
        categories = response.data;
        currentPage = response.meta.currentPage;
        totalCategories = response.meta.total;
        totalPages = response.meta.lastPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Fetch all categories once when page loads
  Future<void> _fetchAllCategoriesOnInit() async {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );

    if (inventoryProvider.categories.isNotEmpty) {
      print('� Using pre-fetched categories from provider');
      setState(() {
        _allCategoriesCache = inventoryProvider.categories;
      });
      _applyFiltersClientSide();
    } else {
      print('🚀 Pre-fetch not available, fetching categories');
      try {
        print('�🚀 Initial load: Fetching all categories');
        setState(() {
          errorMessage = null;
        });

        // Fetch all categories from all pages
        List<Category> allCategories = [];
        int currentFetchPage = 1;
        bool hasMorePages = true;

        while (hasMorePages) {
          try {
            print('📡 Fetching page $currentFetchPage');
            final response = await InventoryService.getCategories(
              page: currentFetchPage,
              limit: 50, // Use larger page size for efficiency
            );

            allCategories.addAll(response.data);
            print(
              '📦 Page $currentFetchPage: ${response.data.length} categories (total: ${allCategories.length})',
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

        _allCategoriesCache = allCategories;
        print('💾 Cached ${_allCategoriesCache.length} total categories');

        // Apply initial filters (which will be no filters, showing all categories)
        _applyFiltersClientSide();
      } catch (e) {
        print('❌ Critical error in _fetchAllCategoriesOnInit: $e');
        setState(() {
          errorMessage = 'Failed to load categories. Please refresh the page.';
          isLoading = false;
        });
      }
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

      // Apply filters to cached categories (no API calls)
      _filterCachedCategories(searchText);

      print('🔄 _isFilterActive: $_isFilterActive');
      print('📦 _allCategoriesCache.length: ${_allCategoriesCache.length}');
      print(
        '🎯 _allFilteredCategories.length: ${_allFilteredCategories.length}',
      );
      print('👀 categories.length: ${categories.length}');
    } catch (e) {
      print('❌ Error in _applyFiltersClientSide: $e');
      setState(() {
        errorMessage = 'Search error: Please try a different search term';
        isLoading = false;
        categories = [];
      });
    }
  }

  // Filter cached categories without any API calls
  void _filterCachedCategories(String searchText) {
    try {
      // Apply filters to cached categories with enhanced error handling
      _allFilteredCategories = _allCategoriesCache.where((category) {
        try {
          // Status filter
          if (selectedStatus != 'All' && category.status != selectedStatus) {
            return false;
          }

          // Search filter
          if (searchText.isEmpty) {
            return true;
          }

          // Search in multiple fields with better null safety and error handling
          final categoryTitle = category.title.toLowerCase();
          final categoryCode = category.categoryCode.toLowerCase();

          return categoryTitle.contains(searchText) ||
              categoryCode.contains(searchText);
        } catch (e) {
          // If there's any error during filtering, exclude this category
          print('⚠️ Error filtering category ${category.id}: $e');
          return false;
        }
      }).toList();

      print(
        '🔍 After filtering: ${_allFilteredCategories.length} categories match criteria',
      );
      print('📝 Search text: "$searchText", Status filter: "$selectedStatus"');

      // Apply local pagination to filtered results
      _paginateFilteredCategories();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Critical error in _filterCachedCategories: $e');
      setState(() {
        errorMessage =
            'Search failed. Please try again with a simpler search term.';
        isLoading = false;
        // Fallback: show empty results instead of crashing
        categories = [];
        _allFilteredCategories = [];
      });
    }
  }

  // Apply local pagination to filtered categories
  void _paginateFilteredCategories() {
    try {
      // Handle empty results case
      if (_allFilteredCategories.isEmpty) {
        setState(() {
          categories = [];
          // Update pagination variables for pagination controls
          totalCategories = 0;
          totalPages = 1;
        });
        return;
      }

      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      // Ensure startIndex is not greater than the list length
      if (startIndex >= _allFilteredCategories.length) {
        // Reset to page 1 if current page is out of bounds
        setState(() {
          currentPage = 1;
        });
        _paginateFilteredCategories(); // Recursive call with corrected page
        return;
      }

      setState(() {
        categories = _allFilteredCategories.sublist(
          startIndex,
          endIndex > _allFilteredCategories.length
              ? _allFilteredCategories.length
              : endIndex,
        );

        // Update pagination variables for pagination controls
        final calculatedTotalPages =
            (_allFilteredCategories.length / itemsPerPage).ceil();
        totalCategories = _allFilteredCategories.length;
        totalPages = calculatedTotalPages;

        print('📄 Pagination calculation:');
        print(
          '   📊 _allFilteredCategories.length: ${_allFilteredCategories.length}',
        );
        print('   📝 itemsPerPage: $itemsPerPage');
        print('   🔢 totalPages: $totalPages');
        print('   📍 currentPage: $currentPage');
      });
    } catch (e) {
      print('❌ Error in _paginateFilteredCategories: $e');
      setState(() {
        categories = [];
        currentPage = 1;
        totalCategories = 0;
        totalPages = 1;
      });
    }
  }

  // Handle page changes for both filtered and normal pagination
  Future<void> _changePage(int newPage) async {
    setState(() {
      currentPage = newPage;
    });

    // Always use client-side pagination when we have cached categories
    if (_allCategoriesCache.isNotEmpty) {
      _paginateFilteredCategories();
    } else {
      // Fallback to server pagination only if no cached data
      await _fetchCategories(page: newPage);
    }
  }

  void exportToPDF() async {
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
                Text('Fetching all categories...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL categories from database for export
      List<Category> allCategoriesForExport = [];

      try {
        // Fetch ALL categories with unlimited pagination
        allCategoriesForExport = [];
        int currentPage = 1;
        bool hasMorePages = true;

        while (hasMorePages) {
          final pageResponse = await InventoryService.getCategories(
            page: currentPage,
            limit: 100, // Fetch in chunks of 100
          );

          final categories = pageResponse.data;
          allCategoriesForExport.addAll(categories);

          // Check if there are more pages
          final totalItems = pageResponse.meta.total;
          final fetchedSoFar = allCategoriesForExport.length;

          if (fetchedSoFar >= totalItems) {
            hasMorePages = false;
          } else {
            currentPage++;
          }
        }
      } catch (e) {
        print('Error fetching all categories: $e');
        // Fallback to current data
        allCategoriesForExport = categories.isNotEmpty ? categories : [];
      }

      if (allCategoriesForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No categories to export'),
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
                  'Generating PDF with ${allCategoriesForExport.length} categories...',
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
      ); // Categories theme color
      final PdfColor tableHeaderColor = PdfColor(248, 249, 250);

      // Create table with proper settings for pagination
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 4);

      // Use full page width but account for table borders and padding
      final double pageWidth =
          document.pageSettings.size.width -
          15; // Only 15px left margin, 0px right margin
      final double tableWidth =
          pageWidth *
          0.85; // Use 85% to ensure right boundary is clearly visible

      // Balanced column widths for categories
      grid.columns[0].width = tableWidth * 0.30; // 30% - Category Name
      grid.columns[1].width = tableWidth * 0.25; // 25% - Category Code
      grid.columns[2].width = tableWidth * 0.20; // 20% - Status
      grid.columns[3].width = tableWidth * 0.25; // 25% - Created Date

      // Enable automatic page breaking and row splitting
      grid.allowRowBreakingAcrossPages = true;

      // Set grid style with better padding for readability
      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
        font: smallFont,
      );

      // Add header row
      final PdfGridRow headerRow = grid.headers.add(1)[0];
      headerRow.cells[0].value = 'Category Name';
      headerRow.cells[1].value = 'Category Code';
      headerRow.cells[2].value = 'Status';
      headerRow.cells[3].value = 'Created Date';

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

      // Add all category data rows
      for (var category in allCategoriesForExport) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = category.title;
        row.cells[1].value = category.categoryCode;
        row.cells[2].value = category.status;
        row.cells[3].value = _formatDate(category.createdAt);

        // Style data cells with better text wrapping
        for (int i = 0; i < row.cells.count; i++) {
          row.cells[i].style = PdfGridCellStyle(
            font: smallFont,
            textBrush: PdfSolidBrush(PdfColor(33, 37, 41)),
            format: PdfStringFormat(
              alignment: i == 2
                  ? PdfTextAlignment.center
                  : PdfTextAlignment.left,
              lineAlignment: PdfVerticalAlignment.top,
              wordWrap: PdfWordWrapType.word,
            ),
          );
        }

        // Color code status
        if (category.status == 'Active') {
          row.cells[2].style.backgroundBrush = PdfSolidBrush(
            PdfColor(212, 237, 218),
          );
          row.cells[2].style.textBrush = PdfSolidBrush(PdfColor(21, 87, 36));
        } else {
          row.cells[2].style.backgroundBrush = PdfSolidBrush(
            PdfColor(248, 215, 218),
          );
          row.cells[2].style.textBrush = PdfSolidBrush(PdfColor(114, 28, 36));
        }
      }

      // Set up page template for headers and footers
      final PdfPageTemplateElement headerTemplate = PdfPageTemplateElement(
        Rect.fromLTWH(0, 0, document.pageSettings.size.width, 50),
      );

      // Draw header on template - minimal left margin, full width
      headerTemplate.graphics.drawString(
        'Categories Database Export',
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
        'Total Categories: ${allCategoriesForExport.length} | Generated: ${DateTime.now().toString().substring(0, 19)} | Product Categories Report',
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
        'Page \$PAGE of \$TOTAL | ${allCategoriesForExport.length} Total Categories | Generated from POS System',
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
        'PDF generated with $pageCount page(s) for ${allCategoriesForExport.length} categories',
      );

      // Save PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Categories Database PDF',
        fileName: 'categories_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
                '✅ Categories Exported!\n📊 ${allCategoriesForExport.length} categories across $pageCount pages\n📄 Landscape format for better visibility',
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
                Text('Fetching all categories...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL categories from database for export
      List<Category> allCategoriesForExport = [];

      try {
        // Fetch ALL categories with unlimited pagination
        allCategoriesForExport = [];
        int currentPage = 1;
        bool hasMorePages = true;

        while (hasMorePages) {
          final pageResponse = await InventoryService.getCategories(
            page: currentPage,
            limit: 100, // Fetch in chunks of 100
          );

          final categories = pageResponse.data;
          allCategoriesForExport.addAll(categories);

          // Check if there are more pages
          final totalItems = pageResponse.meta.total;
          final fetchedSoFar = allCategoriesForExport.length;

          if (fetchedSoFar >= totalItems) {
            hasMorePages = false;
          } else {
            currentPage++;
          }
        }
      } catch (e) {
        print('Error fetching all categories: $e');
        // Fallback to current data
        allCategoriesForExport = categories.isNotEmpty ? categories : [];
      }

      if (allCategoriesForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No categories to export'),
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
                  'Generating Excel with ${allCategoriesForExport.length} categories...',
                ),
              ],
            ),
          );
        },
      );

      // Create Excel document
      var excel = excel_pkg.Excel.createExcel();
      var sheet = excel['Categories'];

      // Add header row
      sheet.appendRow([
        excel_pkg.TextCellValue('Category Name'),
        excel_pkg.TextCellValue('Category Code'),
        excel_pkg.TextCellValue('Status'),
        excel_pkg.TextCellValue('Created Date'),
        excel_pkg.TextCellValue('Updated Date'),
      ]);

      // Style header row
      var headerStyle = excel_pkg.CellStyle(bold: true, fontSize: 12);

      for (int i = 0; i < 5; i++) {
        var cell = sheet.cell(
          excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.cellStyle = headerStyle;
      }

      // Add all category data rows
      for (var category in allCategoriesForExport) {
        // Format created date
        String formattedCreatedDate = 'N/A';
        try {
          final date = DateTime.parse(category.createdAt);
          formattedCreatedDate = '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          // Keep default value
        }

        // Format updated date
        String formattedUpdatedDate = 'N/A';
        try {
          final date = DateTime.parse(category.updatedAt);
          formattedUpdatedDate = '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          // Keep default value
        }

        sheet.appendRow([
          excel_pkg.TextCellValue(category.title),
          excel_pkg.TextCellValue(category.categoryCode),
          excel_pkg.TextCellValue(category.status),
          excel_pkg.TextCellValue(formattedCreatedDate),
          excel_pkg.TextCellValue(formattedUpdatedDate),
        ]);
      }

      // Auto-fit columns
      for (int i = 0; i < 5; i++) {
        sheet.setColumnAutoFit(i);
      }

      // Save Excel file
      var fileBytes = excel.save();

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Categories Database Excel',
        fileName: 'categories_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(fileBytes!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Categories Exported!\n📊 ${allCategoriesForExport.length} categories exported to Excel\n📄 File saved successfully',
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
            content: Text('Excel export failed: ${e.toString()}'),
            backgroundColor: Color(0xFFDC3545),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void addNewCategory() async {
    final titleController = TextEditingController();
    String selectedStatus = 'Active';

    // Reset image state
    _selectedImage = null;
    _imagePath = null;

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
                  Icon(Icons.add_circle, color: Color(0xFF17A2B8)),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Category',
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
                        labelText: 'Category Title *',
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
                          'Category Image (optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFDEE2E6)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: Color(0xFF6C757D),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No image selected',
                                      style: TextStyle(
                                        color: Color(0xFF6C757D),
                                      ),
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
                                  '${Directory.current.path}/assets/images/categories',
                                );
                                if (!await directory.exists()) {
                                  await directory.create(recursive: true);
                                }
                                final fileName =
                                    'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                final savedImage = await imageFile.copy(
                                  '${directory.path}/$fileName',
                                );
                                setState(() {
                                  _selectedImage = savedImage;
                                  _imagePath =
                                      'https://zafarcomputers.com/assets/images/categories/$fileName';
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
                            _selectedImage == null
                                ? 'Select Image'
                                : 'Change Image',
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
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a category title'),
                          backgroundColor: Color(0xFFDC3545),
                        ),
                      );
                      return;
                    }

                    try {
                      setState(() => isLoading = true);
                      Navigator.of(context).pop(true); // Close dialog first

                      final createData = {
                        'title': titleController.text.trim(),
                        'status': selectedStatus,
                        if (_imagePath != null) 'img_path': _imagePath,
                      };

                      await InventoryService.createCategory(createData);

                      // Refresh the categories cache and apply current filters
                      await _fetchAllCategoriesOnInit();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Category created successfully'),
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
                              Text('Failed to create category: $e'),
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
                    backgroundColor: Color(0xFF17A2B8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void editCategory(Category category) async {
    final titleController = TextEditingController(text: category.title);
    final categoryCodeController = TextEditingController(
      text: category.categoryCode,
    );
    String selectedStatus = category.status;

    // Reset image state for editing
    _selectedImage = null;
    _imagePath = category.imgPath;

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
                    'Edit Category',
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
                        labelText: 'Category Title',
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
                      controller: categoryCodeController,
                      decoration: InputDecoration(
                        labelText: 'Category Code',
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
                          'Category Image (optional)',
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
                                            Icons.category,
                                            color: Color(0xFF6C757D),
                                            size: 48,
                                          ),
                                    ),
                                  )
                                : FutureBuilder<Uint8List?>(
                                    future: _loadCategoryImage(_imagePath!),
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
                                          Icons.category,
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
                                  '${Directory.current.path}/assets/images/categories',
                                );
                                if (!await directory.exists()) {
                                  await directory.create(recursive: true);
                                }
                                final fileName =
                                    'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                final savedImage = await imageFile.copy(
                                  '${directory.path}/$fileName',
                                );
                                setState(() {
                                  _selectedImage = savedImage;
                                  _imagePath =
                                      'https://zafarcomputers.com/assets/images/categories/$fileName';
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
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
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
                        categoryCodeController.text.trim().isEmpty) {
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
                        'category_code': categoryCodeController.text.trim(),
                        'status': selectedStatus,
                        if (_imagePath != null) 'img_path': _imagePath,
                      };

                      await InventoryService.updateCategory(
                        category.id,
                        updateData,
                      );

                      // Refresh the categories cache and apply current filters
                      await _fetchAllCategoriesOnInit();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Category updated successfully'),
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
                              Text('Failed to update category: $e'),
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

  void deleteCategory(Category category) {
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
              Text('Delete Category'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${category.title}"?\n\nThis will also remove all associated products and sub-categories.',
            style: TextStyle(color: Color(0xFF6C757D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF6C757D))),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  setState(() => isLoading = true);
                  Navigator.of(context).pop(); // Close dialog first

                  await InventoryService.deleteCategory(category.id);

                  // Refresh the categories cache and apply current filters
                  await _fetchAllCategoriesOnInit();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Category "${category.title}" deleted successfully',
                          ),
                        ],
                      ),
                      backgroundColor: Color(0xFFDC3545),
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
                          Text('Failed to delete category: $e'),
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

  void viewCategoryDetails(Category category) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<Category>(
              future: InventoryService.getCategory(category.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category.title),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getCategoryIcon(category.title),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading Category Details...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0D1845),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Fetching category information...',
                          style: TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.error, color: Color(0xFFDC3545)),
                        const SizedBox(width: 12),
                        Text(
                          'Error Loading Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      'Failed to load category details: ${snapshot.error}',
                      style: TextStyle(color: Color(0xFF6C757D)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          viewCategoryDetails(category); // Retry
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0D1845),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  );
                } else if (snapshot.hasData) {
                  final categoryDetails = snapshot.data!;
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(categoryDetails.title),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getCategoryIcon(categoryDetails.title),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Category Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Title', categoryDetails.title),
                        _buildDetailRow(
                          'Category Code',
                          categoryDetails.categoryCode,
                        ),
                        _buildDetailRow('Status', categoryDetails.status),
                        _buildDetailRow(
                          'Created',
                          _formatDate(categoryDetails.createdAt),
                        ),
                        _buildDetailRow(
                          'Updated',
                          _formatDate(categoryDetails.updatedAt),
                        ),
                        if (categoryDetails.imgPath != null)
                          _buildDetailRow(
                            'Image Path',
                            categoryDetails.imgPath!,
                          ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      ),
                    ],
                  );
                } else {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text('Unknown Error'),
                    content: Text('An unexpected error occurred.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close'),
                      ),
                    ],
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF495057),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return dateString; // Fallback to original string if parsing fails
    }
  }

  List<Widget> _buildPageButtons() {
    List<Widget> buttons = [];
    int startPage = 1;
    int endPage = totalPages;

    // Show max 5 page buttons
    if (totalPages > 5) {
      if (currentPage <= 3) {
        endPage = 5;
      } else if (currentPage >= totalPages - 2) {
        startPage = totalPages - 4;
      } else {
        startPage = currentPage - 2;
        endPage = currentPage + 2;
      }
    }

    for (int i = startPage; i <= endPage; i++) {
      buttons.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            onPressed: () => _changePage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor: i == currentPage
                  ? Color(0xFF0D1845)
                  : Colors.white,
              foregroundColor: i == currentPage
                  ? Colors.white
                  : Color(0xFF6C757D),
              elevation: i == currentPage ? 2 : 0,
              side: i == currentPage
                  ? null
                  : BorderSide(color: Color(0xFFDEE2E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(36, 36),
            ),
            child: Text(
              i.toString(),
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
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
                          Icons.category,
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
                              'Categories',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Organize and manage your product categories efficiently',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: addNewCategory,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Category'),
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
                        'Total Categories',
                        categories.length.toString(),
                        Icons.category,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Active Categories',
                        categories
                            .where((c) => c.status == 'Active')
                            .length
                            .toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Inactive Categories',
                        categories
                            .where((c) => c.status != 'Active')
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
                                    hintText: 'Search categories...',
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
                          // Image Column - Fixed width to match body
                          SizedBox(
                            width: 60,
                            child: Text('Image', style: _headerStyle()),
                          ),
                          const SizedBox(width: 100),
                          // Category Name Column
                          Expanded(
                            flex: 2,
                            child: Text('Category Name', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          // Category Code Column
                          Expanded(
                            flex: 2,
                            child: Text('Category Code', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          // Created Date Column
                          Expanded(
                            flex: 2,
                            child: Text('Created Date', style: _headerStyle()),
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
                          // Actions Column - Fixed width
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
                                    onPressed: () =>
                                        _fetchCategories(page: currentPage),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : categories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No categories found',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
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
                                      // Image Column - Fixed width
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
                                              category.imgPath != null &&
                                                  category.imgPath!.isNotEmpty
                                              ? (category.imgPath!.startsWith(
                                                          'http',
                                                        ) &&
                                                        !category.imgPath!
                                                            .contains(
                                                              'zafarcomputers.com',
                                                            ))
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        child: Image.network(
                                                          category.imgPath!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                context,
                                                                error,
                                                                stackTrace,
                                                              ) => Icon(
                                                                _getCategoryIcon(
                                                                  category
                                                                      .title,
                                                                ),
                                                                color:
                                                                    const Color(
                                                                      0xFF0D1845,
                                                                    ),
                                                                size: 20,
                                                              ),
                                                        ),
                                                      )
                                                    : FutureBuilder<Uint8List?>(
                                                        future:
                                                            _loadCategoryImage(
                                                              category.imgPath!,
                                                            ),
                                                        builder: (context, snapshot) {
                                                          if (snapshot
                                                                  .hasData &&
                                                              snapshot.data !=
                                                                  null) {
                                                            return ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                              child:
                                                                  Image.memory(
                                                                    snapshot
                                                                        .data!,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  ),
                                                            );
                                                          }
                                                          return Icon(
                                                            _getCategoryIcon(
                                                              category.title,
                                                            ),
                                                            color: const Color(
                                                              0xFF0D1845,
                                                            ),
                                                            size: 20,
                                                          );
                                                        },
                                                      )
                                              : Icon(
                                                  _getCategoryIcon(
                                                    category.title,
                                                  ),
                                                  color: const Color(
                                                    0xFF0D1845,
                                                  ),
                                                  size: 20,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 100),
                                      // Category Name Column
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          category.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0D1845),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Category Code Column
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            category.categoryCode,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              color: Color(0xFF6C757D),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Created Date Column
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatDate(category.createdAt),
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Status Column - Centered
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: category.status == 'Active'
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              category.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    category.status == 'Active'
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
                                                color: const Color(0xFF17A2B8),
                                                size: 16,
                                              ),
                                              onPressed: () =>
                                                  viewCategoryDetails(category),
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
                                                  editCategory(category),
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
                                                  deleteCategory(category),
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
            if (categories.isNotEmpty) ...[
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
                        'Page $currentPage of $totalPages (${categories.length} total)',
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
                      onPressed: currentPage < totalPages
                          ? () => _changePage(currentPage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 16),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentPage < totalPages
                            ? const Color(0xFF0D1845)
                            : Colors.grey.shade300,
                        foregroundColor: currentPage < totalPages
                            ? Colors.white
                            : Colors.grey.shade600,
                        elevation: currentPage < totalPages ? 2 : 0,
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

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'computers':
        return Color(0xFF17A2B8);
      case 'electronics':
        return Color(0xFF28A745);
      case 'shoe':
        return Color(0xFFDC3545);
      case 'cosmetics':
        return Color(0xFFE83E8C);
      case 'groceries':
        return Color(0xFFFD7E14);
      case 'fashion':
        return Color(0xFF6F42C1);
      case 'bridal':
        return Color(0xFFE91E63);
      case 'fancy':
        return Color(0xFF9C27B0);
      case 'casual':
        return Color(0xFF2196F3);
      default:
        return Color(0xFF6C757D);
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'computers':
        return Icons.computer;
      case 'electronics':
        return Icons.electrical_services;
      case 'shoe':
        return Icons.shopping_bag;
      case 'cosmetics':
        return Icons.brush;
      case 'groceries':
        return Icons.shopping_cart;
      case 'fashion':
        return Icons.style;
      case 'bridal':
        return Icons.diamond;
      case 'fancy':
        return Icons.star;
      case 'casual':
        return Icons.accessibility;
      default:
        return Icons.category;
    }
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

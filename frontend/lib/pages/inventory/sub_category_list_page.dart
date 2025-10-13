import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../../services/inventory_service.dart';
import '../../models/sub_category.dart';
import '../../models/category.dart';
import 'add_sub_category_page.dart';
import 'sub_category_detail_page.dart';
import 'edit_sub_category_page.dart';

class SubCategoryListPage extends StatefulWidget {
  const SubCategoryListPage({super.key});

  @override
  State<SubCategoryListPage> createState() => _SubCategoryListPageState();
}

class _SubCategoryListPageState extends State<SubCategoryListPage> {
  List<SubCategory> subCategories = [];
  bool isLoading = false;
  bool isPaginationLoading = false;
  String? errorMessage;
  int currentPage = 1;
  int totalSubCategories = 0;
  int totalPages = 1;
  final int itemsPerPage = 10;

  // Caching for real-time search and filter
  List<SubCategory> _allSubCategoriesCache = [];
  List<SubCategory> _allFilteredSubCategories = [];

  String selectedCategory = 'All';
  String selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchAllSubCategoriesOnInit();
    _fetchCategories();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubCategories({int page = 1}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await InventoryService.getSubCategories(
        page: page,
        limit: itemsPerPage,
      );

      setState(() {
        subCategories = response.data;
        currentPage = response.meta.currentPage;
        totalSubCategories = response.meta.total;
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

  Future<void> _fetchAllSubCategoriesOnInit() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Fetch ALL sub categories for client-side filtering
      List<SubCategory> allSubCategories = [];
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        final pageResponse = await InventoryService.getSubCategories(
          page: currentPage,
          limit: 100, // Fetch in larger chunks for efficiency
        );

        final subCategories = pageResponse.data;
        allSubCategories.addAll(subCategories);

        // Check if there are more pages
        final totalItems = pageResponse.meta.total;
        final fetchedSoFar = allSubCategories.length;

        if (fetchedSoFar >= totalItems) {
          hasMorePages = false;
        } else {
          currentPage++;
        }
      }

      setState(() {
        _allSubCategoriesCache = allSubCategories;
        _allFilteredSubCategories = List.from(allSubCategories);
        totalSubCategories = allSubCategories.length;
        totalPages = (allSubCategories.length / itemsPerPage).ceil();
        currentPage = 1;
        isLoading = false;
      });

      // Apply initial pagination
      _paginateFilteredSubCategories();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _applyFiltersClientSide();
      });
    });
  }

  void _applyFiltersClientSide() {
    final searchQuery = _searchController.text.toLowerCase().trim();

    setState(() {
      // Apply filters to cached sub categories
      _allFilteredSubCategories = _allSubCategoriesCache.where((subCategory) {
        // Apply search filter
        final matchesSearch =
            searchQuery.isEmpty ||
            subCategory.title.toLowerCase().contains(searchQuery) ||
            subCategory.subCategoryCode.toLowerCase().contains(searchQuery) ||
            (subCategory.category?.title.toLowerCase().contains(searchQuery) ??
                false);

        // Apply status filter
        final matchesStatus =
            selectedStatus == 'All' ||
            subCategory.status.toLowerCase() == selectedStatus.toLowerCase();

        // Apply category filter
        final matchesCategory =
            selectedCategory == 'All' ||
            (subCategory.category?.title == selectedCategory);

        return matchesSearch && matchesStatus && matchesCategory;
      }).toList();

      // Reset to first page when filters change
      currentPage = 1;
      totalPages = (_allFilteredSubCategories.length / itemsPerPage).ceil();
      totalSubCategories = _allFilteredSubCategories.length;
    });

    _paginateFilteredSubCategories();
  }

  void _paginateFilteredSubCategories() {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;

    setState(() {
      subCategories = _allFilteredSubCategories.sublist(
        startIndex,
        endIndex > _allFilteredSubCategories.length
            ? _allFilteredSubCategories.length
            : endIndex,
      );
    });
  }

  void _changePage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
      _paginateFilteredSubCategories();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await InventoryService.getCategories(limit: 100);
      setState(() {
        categories = response.data;
      });
    } catch (e) {
      // Handle error silently for categories
      categories = [];
    }
  }

  Future<Uint8List?> _loadSubCategoryImage(String imagePath) async {
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

      // Check if file exists in local subcategories directory
      final file = File('assets/images/subcategories/$filename');
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
                Text('Fetching all sub-categories...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL sub-categories from database for export
      List<SubCategory> allSubCategoriesForExport = [];

      try {
        // Use the current filtered sub categories for export
        allSubCategoriesForExport = List.from(_allFilteredSubCategories);

        // If no filters are applied, fetch fresh data from server
        if (_allFilteredSubCategories.length == _allSubCategoriesCache.length &&
            _searchController.text.trim().isEmpty &&
            selectedStatus == 'All' &&
            selectedCategory == 'All') {
          // Fetch ALL sub-categories with unlimited pagination
          allSubCategoriesForExport = [];
          int currentPage = 1;
          bool hasMorePages = true;

          while (hasMorePages) {
            final pageResponse = await InventoryService.getSubCategories(
              page: currentPage,
              limit: 100, // Fetch in chunks of 100
            );

            allSubCategoriesForExport.addAll(pageResponse.data);

            // Check if there are more pages
            if (pageResponse.meta.currentPage >= pageResponse.meta.lastPage) {
              hasMorePages = false;
            } else {
              currentPage++;
            }
          }
        }
      } catch (e) {
        print('Error fetching all sub-categories: $e');
        // Fallback to current data
        allSubCategoriesForExport = subCategories.isNotEmpty
            ? subCategories
            : [];
      }

      if (allSubCategoriesForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No sub-categories to export'),
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
                  'Generating PDF with ${allSubCategoriesForExport.length} sub-categories...',
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
        111,
        66,
        193,
      ); // Sub-category theme color
      final PdfColor tableHeaderColor = PdfColor(248, 249, 250);

      // Create table with proper settings for pagination
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 5);

      // Use full page width but account for table borders and padding
      final double pageWidth =
          document.pageSettings.size.width -
          15; // Only 15px left margin, 0px right margin
      final double tableWidth =
          pageWidth *
          0.85; // Use 85% to ensure right boundary is clearly visible

      // Balanced column widths for sub-categories
      grid.columns[0].width = tableWidth * 0.15; // 15% - Sub Category Code
      grid.columns[1].width = tableWidth * 0.25; // 25% - Sub Category Name
      grid.columns[2].width = tableWidth * 0.20; // 20% - Category
      grid.columns[3].width = tableWidth * 0.15; // 15% - Status
      grid.columns[4].width = tableWidth * 0.25; // 25% - Created Date

      // Enable automatic page breaking and row splitting
      grid.allowRowBreakingAcrossPages = true;

      // Set grid style with better padding for readability
      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
        font: smallFont,
      );

      // Add header row
      final PdfGridRow headerRow = grid.headers.add(1)[0];
      headerRow.cells[0].value = 'Sub Category Code';
      headerRow.cells[1].value = 'Sub Category Name';
      headerRow.cells[2].value = 'Category';
      headerRow.cells[3].value = 'Status';
      headerRow.cells[4].value = 'Created Date';

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

      // Add all sub-category data rows
      for (var subCategory in allSubCategoriesForExport) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = subCategory.subCategoryCode;
        row.cells[1].value = subCategory.title;
        row.cells[2].value = subCategory.category?.title ?? 'N/A';
        row.cells[3].value = subCategory.status;

        // Format created date
        String formattedDate = 'N/A';
        try {
          final date = DateTime.parse(subCategory.createdAt);
          formattedDate = '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          // Keep default value
        }
        row.cells[4].value = formattedDate;

        // Style data cells with better text wrapping
        for (int i = 0; i < row.cells.count; i++) {
          row.cells[i].style = PdfGridCellStyle(
            font: smallFont,
            textBrush: PdfSolidBrush(PdfColor(33, 37, 41)),
            format: PdfStringFormat(
              alignment: i == 3
                  ? PdfTextAlignment.center
                  : PdfTextAlignment.left,
              lineAlignment: PdfVerticalAlignment.top,
              wordWrap: PdfWordWrapType.word,
            ),
          );
        }

        // Color code status
        if (subCategory.status == 'active') {
          row.cells[3].style.backgroundBrush = PdfSolidBrush(
            PdfColor(212, 237, 218),
          );
          row.cells[3].style.textBrush = PdfSolidBrush(PdfColor(21, 87, 36));
        } else {
          row.cells[3].style.backgroundBrush = PdfSolidBrush(
            PdfColor(248, 215, 218),
          );
          row.cells[3].style.textBrush = PdfSolidBrush(PdfColor(114, 28, 36));
        }
      }

      // Set up page template for headers and footers
      final PdfPageTemplateElement headerTemplate = PdfPageTemplateElement(
        Rect.fromLTWH(0, 0, document.pageSettings.size.width, 50),
      );

      // Draw header on template - minimal left margin, full width
      headerTemplate.graphics.drawString(
        'Complete Sub Categories Database Export',
        titleFont,
        brush: PdfSolidBrush(headerColor),
        bounds: Rect.fromLTWH(
          15,
          10,
          document.pageSettings.size.width - 15,
          25,
        ),
      );

      String filterInfo = 'Filters: ';
      List<String> filters = [];
      if (selectedStatus != 'All') filters.add('Status=$selectedStatus');
      if (selectedCategory != 'All') filters.add('Category=$selectedCategory');
      if (_searchController.text.isNotEmpty)
        filters.add('Search="${_searchController.text}"');
      if (filters.isEmpty) filters.add('All');

      headerTemplate.graphics.drawString(
        'Total Sub Categories: ${allSubCategoriesForExport.length} | Generated: ${DateTime.now().toString().substring(0, 19)} | $filterInfo${filters.join(', ')}',
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
        'Page \$PAGE of \$TOTAL | ${allSubCategoriesForExport.length} Total Sub Categories | Generated from POS System',
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
        'PDF generated with $pageCount page(s) for ${allSubCategoriesForExport.length} sub-categories',
      );

      // Save PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Complete Sub Categories Database PDF',
        fileName:
            'complete_sub_categories_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
                '✅ Complete Database Exported!\n📊 ${allSubCategoriesForExport.length} sub-categories across $pageCount pages\n📄 Landscape format for better visibility',
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
                Text('Fetching all sub-categories...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL sub-categories from database for export
      List<SubCategory> allSubCategoriesForExport = [];

      try {
        // Use the current filtered sub categories for export
        allSubCategoriesForExport = List.from(_allFilteredSubCategories);

        // If no filters are applied, fetch fresh data from server
        if (_allFilteredSubCategories.length == _allSubCategoriesCache.length &&
            _searchController.text.trim().isEmpty &&
            selectedStatus == 'All' &&
            selectedCategory == 'All') {
          // Fetch ALL sub-categories with unlimited pagination
          allSubCategoriesForExport = [];
          int currentPage = 1;
          bool hasMorePages = true;

          while (hasMorePages) {
            final pageResponse = await InventoryService.getSubCategories(
              page: currentPage,
              limit: 100, // Fetch in chunks of 100
            );

            allSubCategoriesForExport.addAll(pageResponse.data);

            // Check if there are more pages
            if (pageResponse.meta.currentPage >= pageResponse.meta.lastPage) {
              hasMorePages = false;
            } else {
              currentPage++;
            }
          }
        }
      } catch (e) {
        print('Error fetching all sub-categories: $e');
        // Fallback to current data
        allSubCategoriesForExport = subCategories.isNotEmpty
            ? subCategories
            : [];
      }

      if (allSubCategoriesForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No sub-categories to export'),
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
                  'Generating Excel with ${allSubCategoriesForExport.length} sub-categories...',
                ),
              ],
            ),
          );
        },
      );

      // Create Excel document
      final excel_pkg.Excel excel = excel_pkg.Excel.createExcel();
      final excel_pkg.Sheet sheet = excel['Sub Categories'];

      // Add header row with styling
      final headerStyle = excel_pkg.CellStyle(bold: true, fontSize: 12);

      sheet.appendRow([
        excel_pkg.TextCellValue('Sub Category Code'),
        excel_pkg.TextCellValue('Sub Category Name'),
        excel_pkg.TextCellValue('Category'),
        excel_pkg.TextCellValue('Status'),
        excel_pkg.TextCellValue('Created Date'),
      ]);

      // Apply header styling
      for (int i = 0; i < 5; i++) {
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

      // Add all sub-category data rows
      for (var subCategory in allSubCategoriesForExport) {
        // Format created date
        String formattedDate = 'N/A';
        try {
          final date = DateTime.parse(subCategory.createdAt);
          formattedDate = '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          // Keep default value
        }

        sheet.appendRow([
          excel_pkg.TextCellValue(subCategory.subCategoryCode),
          excel_pkg.TextCellValue(subCategory.title),
          excel_pkg.TextCellValue(subCategory.category?.title ?? 'N/A'),
          excel_pkg.TextCellValue(subCategory.status),
          excel_pkg.TextCellValue(formattedDate),
        ]);
      }

      // Auto-fit columns
      for (int i = 0; i < 5; i++) {
        sheet.setColumnAutoFit(i);
      }

      // Save Excel file
      final List<int>? bytes = excel.save();
      if (bytes == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate Excel file'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
        return;
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Complete Sub Categories Database Excel',
        fileName:
            'complete_sub_categories_${DateTime.now().millisecondsSinceEpoch}.xlsx',
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
                '✅ Complete Database Exported!\n📊 ${allSubCategoriesForExport.length} sub-categories exported to Excel\n📄 Ready for data analysis',
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

  void addNewSubCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSubCategoryPage()),
    );

    if (result == true) {
      // Refresh the sub categories list
      await _fetchAllSubCategoriesOnInit();
      await _fetchSubCategories(page: currentPage);
    }
  }

  void editSubCategory(SubCategory subCategory) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSubCategoryPage(subCategory: subCategory),
      ),
    );

    if (result == true) {
      // Refresh the subcategories list
      await _fetchAllSubCategoriesOnInit();
    }
  }

  void deleteSubCategory(SubCategory subCategory) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Color(0xFFDC3545)),
              SizedBox(width: 8),
              Text('Delete Sub Category'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${subCategory.title}"?\n\nThis will also remove all associated products.',
            style: TextStyle(color: Color(0xFF6C757D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF6C757D))),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close dialog first
                Navigator.of(dialogContext).pop();

                try {
                  setState(() => isLoading = true);

                  final response = await InventoryService.deleteSubCategory(
                    subCategory.id,
                  );

                  // Check if the response indicates success
                  if (response['status'] == true) {
                    // Remove the deleted subcategory from local cache immediately
                    setState(() {
                      _allSubCategoriesCache.removeWhere((item) => item.id == subCategory.id);
                      _allFilteredSubCategories.removeWhere((item) => item.id == subCategory.id);
                      subCategories.removeWhere((item) => item.id == subCategory.id);
                      totalSubCategories = _allFilteredSubCategories.length;
                      totalPages = (totalSubCategories / itemsPerPage).ceil();

                      // Adjust current page if necessary
                      if (currentPage > totalPages && totalPages > 0) {
                        currentPage = totalPages;
                      } else if (totalPages == 0) {
                        currentPage = 1;
                      }

                      // Re-apply pagination
                      _paginateFilteredSubCategories();
                    });

                    // Refresh from server in background (don't await)
                    _fetchAllSubCategoriesOnInit();

                    // Show success snackbar after the frame is built
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  response['message'] ??
                                      'Sub category deleted successfully',
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFF28A745),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    });
                  } else {
                    // API returned status: false
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  response['message'] ??
                                      'Failed to delete sub category',
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
                      }
                    });
                  }
                } catch (e) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Failed to delete sub category: ${e.toString()}',
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
                    }
                  });
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
  }  void viewSubCategoryDetails(SubCategory subCategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubCategoryDetailPage(subCategoryId: subCategory.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sub Categories'),
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
                          Icons.category_outlined,
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
                              'Sub Categories',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Organize products within categories for better management',
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
                        onPressed: addNewSubCategory,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Sub Category'),
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
                        'Total Sub Categories',
                        totalSubCategories.toString(),
                        Icons.category,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Active Sub Categories',
                        subCategories
                            .where((s) => s.status == 'active')
                            .length
                            .toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Inactive Sub Categories',
                        subCategories
                            .where((s) => s.status != 'active')
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
                                        'Search by sub category name, code...',
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
                                      _applyFiltersClientSide();
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
                                  value: selectedStatus,
                                  underline: const SizedBox(),
                                  items: ['All', 'active', 'inactive']
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
                                      _applyFiltersClientSide();
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
                          const SizedBox(
                            width: 100,
                          ), // Maximum extreme spacing between image and product details
                          // Sub Category Details Column
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Sub Category Details',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Category Column
                          Expanded(
                            flex: 2,
                            child: Text('Category', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          // Code Column - Centered
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Code', style: _headerStyle()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Products Column - Centered
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Products', style: _headerStyle()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Description Column
                          Expanded(
                            flex: 2,
                            child: Text('Description', style: _headerStyle()),
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
                                    onPressed: _fetchSubCategories,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : subCategories.isEmpty
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
                                  const Text(
                                    'No sub categories found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: subCategories.length,
                              itemBuilder: (context, index) {
                                final subCategory = subCategories[index];
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
                                          child: FutureBuilder<Uint8List?>(
                                            future: _loadSubCategoryImage(
                                              'subcategory_${subCategory.id}.jpg',
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Color(0xFF6F42C1)),
                                                    ),
                                                  ),
                                                );
                                              } else if (snapshot.hasData &&
                                                  snapshot.data != null) {
                                                return ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Image.memory(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                    width: 36,
                                                    height: 36,
                                                  ),
                                                );
                                              } else {
                                                return Icon(
                                                  _getSubCategoryIcon(
                                                    subCategory.title,
                                                  ),
                                                  color: const Color(
                                                    0xFF0D1845,
                                                  ),
                                                  size: 20,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 100,
                                      ), // Maximum extreme spacing between image and product details
                                      // Sub Category Details Column
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              subCategory.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0D1845),
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID: ${subCategory.id}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Category Column
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(
                                              subCategory.category?.title ??
                                                  'N/A',
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          child: Text(
                                            subCategory.category?.title ??
                                                'N/A',
                                            style: _cellStyle(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Code Column - Centered
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
                                            child: Text(
                                              subCategory.subCategoryCode,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0D1845),
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Products Column - Centered
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE7F3FF),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              '0', // Placeholder for products count
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0066CC),
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Description Column
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'No description', // Placeholder for description
                                          style: _cellStyle(),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
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
                                              color:
                                                  subCategory.status == 'active'
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              subCategory.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    subCategory.status ==
                                                        'active'
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
                                                  viewSubCategoryDetails(
                                                    subCategory,
                                                  ),
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
                                                  editSubCategory(subCategory),
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
                                                  deleteSubCategory(
                                                    subCategory,
                                                  ),
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
            if (subCategories.isNotEmpty) ...[
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
                        'Page $currentPage of $totalPages (${totalSubCategories} total)',
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

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'computers':
        return Color(0xFF17A2B8);
      case 'electronics':
        return Color(0xFF28A745);
      case 'shoe':
        return Color(0xFFDC3545);
      default:
        return Color(0xFF6C757D);
    }
  }

  IconData _getSubCategoryIcon(String subCategoryName) {
    switch (subCategoryName.toLowerCase()) {
      case 'laptop':
        return Icons.laptop;
      case 'desktop':
        return Icons.desktop_windows;
      case 'sneakers':
        return Icons.directions_run;
      case 'formals':
        return Icons.business_center;
      case 'smartphone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      default:
        return Icons.inventory;
    }
  }
}

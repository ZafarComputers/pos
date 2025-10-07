import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../../services/inventory_service.dart';
import '../../models/sub_category.dart';
import '../../models/category.dart';

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

  // Image-related state variables
  File? _selectedImage;
  String? _imagePath;

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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F42C1)),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F42C1)),
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
        if (subCategory.status == 'Active') {
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F42C1)),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F42C1)),
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
    final titleController = TextEditingController();
    int? selectedCategoryId;
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
                    'Add New Sub Category',
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
                        labelText: 'Sub Category Title *',
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
                          'Sub Category Image (optional)',
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
                                  '${Directory.current.path}/assets/images/subcategories',
                                );
                                if (!await directory.exists()) {
                                  await directory.create(recursive: true);
                                }
                                final fileName =
                                    'subcategory_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                final savedImage = await imageFile.copy(
                                  '${directory.path}/$fileName',
                                );
                                setState(() {
                                  _selectedImage = savedImage;
                                  _imagePath =
                                      'https://zafarcomputers.com/assets/images/subcategories/$fileName';
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
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Parent Category *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCategoryId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a parent category';
                        }
                        return null;
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
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a sub category title'),
                          backgroundColor: Color(0xFFDC3545),
                        ),
                      );
                      return;
                    }

                    if (selectedCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select a parent category'),
                          backgroundColor: Color(0xFFDC3545),
                        ),
                      );
                      return;
                    }

                    try {
                      setState(() => isLoading = true);
                      Navigator.of(context).pop(true); // Close dialog first

                      // First create the subcategory without image
                      final createData = {
                        'title': titleController.text.trim(),
                        'category_id': selectedCategoryId,
                        'status': selectedStatus,
                      };

                      final createdResponse =
                          await InventoryService.createSubCategory(createData);
                      final createdSubCategory = SubCategory.fromJson(
                        createdResponse,
                      );

                      // If we have an image, rename it to use the subcategory ID
                      if (_selectedImage != null && _imagePath != null) {
                        try {
                          final directory = Directory(
                            '${Directory.current.path}/assets/images/subcategories',
                          );
                          final oldFileName = _imagePath!.split('/').last;
                          final newFileName =
                              'subcategory_${createdSubCategory.id}.jpg';
                          final oldFile = File(
                            '${directory.path}/$oldFileName',
                          );
                          final newFile = File(
                            '${directory.path}/$newFileName',
                          );

                          if (await oldFile.exists()) {
                            await oldFile.rename(newFile.path);

                            // Update the subcategory with the correct image path
                            final updateData = {
                              'title': createdSubCategory.title,
                              'category_id': createdSubCategory.categoryId,
                              'status': createdSubCategory.status,
                              'img_path':
                                  'https://zafarcomputers.com/assets/images/subcategories/$newFileName',
                            };

                            await InventoryService.updateSubCategory(
                              createdSubCategory.id,
                              updateData,
                            );
                          }
                        } catch (e) {
                          // Handle file operation errors silently or log them
                          print('Error handling image file: $e');
                        }
                      }

                      // Refresh the subcategories list
                      await _fetchAllSubCategoriesOnInit();
                      await _fetchSubCategories(page: currentPage);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Sub category created successfully'),
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
                              Text('Failed to create sub category: $e'),
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

  void editSubCategory(SubCategory subCategory) async {
    final titleController = TextEditingController(text: subCategory.title);
    int? selectedCategoryId = subCategory.categoryId;
    String selectedStatus = subCategory.status;

    // Reset image state
    _selectedImage = null;
    _imagePath = subCategory.imgPath;

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
                    'Edit Sub Category',
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
                        labelText: 'Sub Category Title *',
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
                          'Sub Category Image (optional)',
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
                              : _imagePath != null && _imagePath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _imagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: Color(0xFF6C757D),
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image not available',
                                            style: TextStyle(
                                              color: Color(0xFF6C757D),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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
                                  '${Directory.current.path}/assets/images/subcategories',
                                );
                                if (!await directory.exists()) {
                                  await directory.create(recursive: true);
                                }
                                final fileName =
                                    'subcategory_${subCategory.id}.jpg';
                                final savedImage = await imageFile.copy(
                                  '${directory.path}/$fileName',
                                );
                                setState(() {
                                  _selectedImage = savedImage;
                                  _imagePath =
                                      'https://zafarcomputers.com/assets/images/subcategories/$fileName';
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
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Parent Category *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCategoryId = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a parent category';
                        }
                        return null;
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
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a sub category title'),
                          backgroundColor: Color(0xFFDC3545),
                        ),
                      );
                      return;
                    }

                    if (selectedCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please select a parent category'),
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
                        'category_id': selectedCategoryId,
                        'status': selectedStatus,
                        if (_imagePath != null) 'img_path': _imagePath,
                      };

                      await InventoryService.updateSubCategory(
                        subCategory.id,
                        updateData,
                      );

                      // Refresh the subcategories list
                      await _fetchAllSubCategoriesOnInit();
                      await _fetchSubCategories(page: currentPage);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Sub category updated successfully'),
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
                              Text('Failed to update sub category: $e'),
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

  void deleteSubCategory(SubCategory subCategory) {
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
              Text('Delete Sub Category'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${subCategory.title}"?\n\nThis will also remove all associated products.',
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
                  Navigator.of(context).pop(); // Close dialog first
                  setState(() => isLoading = true);

                  await InventoryService.deleteSubCategory(subCategory.id);

                  // Refresh the subcategories list
                  await _fetchAllSubCategoriesOnInit();
                  await _fetchSubCategories(page: currentPage);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Sub category deleted successfully'),
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
                          Text('Failed to delete sub category: $e'),
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

  void viewSubCategoryDetails(SubCategory subCategory) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<SubCategory>(
              future: InventoryService.getSubCategory(subCategory.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.visibility, color: Color(0xFF17A2B8)),
                        SizedBox(width: 12),
                        Text(
                          'Sub Category Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Container(
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6F42C1),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading sub category details...',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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
                } else if (snapshot.hasError) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.error, color: Color(0xFFDC3545)),
                        SizedBox(width: 12),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Container(
                      width: 400,
                      child: Text(
                        'Failed to load sub category details: ${snapshot.error}',
                        style: TextStyle(color: Color(0xFF6C757D)),
                      ),
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
                } else if (snapshot.hasData) {
                  final details = snapshot.data!;
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.visibility, color: Color(0xFF17A2B8)),
                        SizedBox(width: 12),
                        Text(
                          'Sub Category Details',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Section
                          Container(
                            width: 300,
                            height: 150,
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFDEE2E6)),
                            ),
                            child: FutureBuilder<Uint8List?>(
                              future: _loadSubCategoryImage(
                                'subcategory_${details.id}.jpg',
                              ),
                              builder: (context, imageSnapshot) {
                                if (imageSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF6F42C1),
                                      ),
                                    ),
                                  );
                                } else if (imageSnapshot.hasData &&
                                    imageSnapshot.data != null) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      imageSnapshot.data!,
                                      fit: BoxFit.cover,
                                      width: 300,
                                      height: 150,
                                    ),
                                  );
                                } else {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: Color(0xFF6C757D),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image available',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ),

                          // Details
                          _buildDetailRow('Title', details.title),
                          _buildDetailRow('Code', details.subCategoryCode),
                          _buildDetailRow(
                            'Category',
                            details.category?.title ?? 'N/A',
                          ),
                          _buildDetailRow('Status', details.status),
                          _buildDetailRow(
                            'Created',
                            _formatDate(details.createdAt),
                          ),
                          _buildDetailRow(
                            'Updated',
                            _formatDate(details.updatedAt),
                          ),
                        ],
                      ),
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
                    title: Row(
                      children: [
                        Icon(Icons.error, color: Color(0xFFDC3545)),
                        SizedBox(width: 12),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                      ],
                    ),
                    content: Container(
                      width: 400,
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Color(0xFF6C757D)),
                      ),
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
                }
              },
            );
          },
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
                  colors: [Color(0xFF6F42C1), Color(0xFF8A2BE2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6F42C1).withOpacity(0.3),
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
                      Icons.category_outlined,
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
                          'Sub Categories',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Organize products within categories for better management',
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
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: ElevatedButton.icon(
                          onPressed: exportToExcel,
                          icon: Icon(Icons.table_chart, size: 16),
                          label: Text('Export Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF28A745),
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
                        onPressed: addNewSubCategory,
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Add Sub Category'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF17A2B8),
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
                              hintText: 'Search sub-categories...',
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
                                  color: Color(0xFF6F42C1),
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
                                  Icons.category,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Category',
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
                                value: selectedCategory,
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
                                      color: Color(0xFF6F42C1),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                                items:
                                    ['All', 'Computers', 'Electronics', 'Shoe']
                                        .map(
                                          (category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(
                                              category,
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
                                      selectedCategory = value;
                                    });
                                    _applyFiltersClientSide();
                                  }
                                },
                              ),
                            ),
                          ],
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
                                      color: Color(0xFF6F42C1),
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
                                    });
                                    _applyFiltersClientSide();
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
                          Icons.list_alt,
                          color: Color(0xFF6F42C1),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sub Categories List',
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
                            color: Color(0xFFE7F3FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                color: Color(0xFF0066CC),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '$totalSubCategories Sub Categories',
                                style: TextStyle(
                                  color: Color(0xFF0066CC),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: errorMessage != null
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFDC3545),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load sub categories',
                                    style: TextStyle(
                                      color: Color(0xFFDC3545),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _fetchSubCategories,
                                    child: Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF6F42C1),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Color(0xFFF8F9FA),
                            ),
                            dataRowColor:
                                MaterialStateProperty.resolveWith<Color>((
                                  Set<MaterialState> states,
                                ) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Color(0xFF6F42C1).withOpacity(0.1);
                                  }
                                  return Colors.white;
                                }),
                            columns: const [
                              DataColumn(label: Text('Image')),
                              DataColumn(label: Text('Sub Category Name')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Code')),
                              DataColumn(label: Text('Products')),
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: subCategories.map((subCategory) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Color(0xFFDEE2E6),
                                        ),
                                      ),
                                      child: FutureBuilder<Uint8List?>(
                                        future: _loadSubCategoryImage(
                                          'subcategory_${subCategory.id}.jpg',
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
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
                                                width: 32,
                                                height: 32,
                                              ),
                                            );
                                          } else {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: _getSubCategoryColor(
                                                  subCategory.category?.title ??
                                                      'N/A',
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Icon(
                                                _getSubCategoryIcon(
                                                  subCategory.title,
                                                ),
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            subCategory.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF343A40),
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            subCategory.subCategoryCode,
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
                                        color: _getCategoryColor(
                                          subCategory.category?.title ?? 'N/A',
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        subCategory.category?.title ?? 'N/A',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
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
                                        color: Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        subCategory.subCategoryCode,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6F42C1),
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
                                        color: Color(0xFFE7F3FF),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        '0',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0066CC),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'No description',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                                        color: subCategory.status == 'Active'
                                            ? Color(0xFFD4EDDA)
                                            : Color(0xFFF8D7DA),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            subCategory.status == 'Active'
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color:
                                                subCategory.status == 'Active'
                                                ? Color(0xFF28A745)
                                                : Color(0xFFDC3545),
                                            size: 10,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            subCategory.status,
                                            style: TextStyle(
                                              color:
                                                  subCategory.status == 'Active'
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
                                          onPressed: () =>
                                              viewSubCategoryDetails(
                                                subCategory,
                                              ),
                                          icon: Icon(
                                            Icons.visibility,
                                            color: Color(0xFF17A2B8),
                                            size: 16,
                                          ),
                                          tooltip: 'View Details',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                        SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () =>
                                              editSubCategory(subCategory),
                                          icon: Icon(
                                            Icons.edit,
                                            color: Color(0xFF28A745),
                                            size: 16,
                                          ),
                                          tooltip: 'Edit Sub Category',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                        SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () =>
                                              deleteSubCategory(subCategory),
                                          icon: Icon(
                                            Icons.delete,
                                            color: Color(0xFFDC3545),
                                            size: 16,
                                          ),
                                          tooltip: 'Delete Sub Category',
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
                  ElevatedButton.icon(
                    onPressed: currentPage > 1
                        ? () => _fetchSubCategories(page: currentPage - 1)
                        : null,
                    icon: Icon(Icons.chevron_left, size: 14),
                    label: Text('Previous', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: currentPage > 1
                          ? Color(0xFF6C757D)
                          : Color(0xFFADB5BD),
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
                  // Dynamic page buttons based on total pages
                  ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
                    int pageNumber;
                    if (totalPages <= 5) {
                      pageNumber = index + 1;
                    } else if (currentPage <= 3) {
                      pageNumber = index + 1;
                    } else if (currentPage >= totalPages - 2) {
                      pageNumber = totalPages - 4 + index;
                    } else {
                      pageNumber = currentPage - 2 + index;
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      child: ElevatedButton(
                        onPressed: () => _fetchSubCategories(page: pageNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pageNumber == currentPage
                              ? Color(0xFF6F42C1)
                              : Colors.white,
                          foregroundColor: pageNumber == currentPage
                              ? Colors.white
                              : Color(0xFF6C757D),
                          elevation: pageNumber == currentPage ? 2 : 0,
                          side: pageNumber == currentPage
                              ? null
                              : BorderSide(color: Color(0xFFDEE2E6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size(32, 32),
                        ),
                        child: Text(
                          pageNumber.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: currentPage < totalPages
                        ? () => _fetchSubCategories(page: currentPage + 1)
                        : null,
                    icon: Icon(Icons.chevron_right, size: 14),
                    label: Text('Next', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: currentPage < totalPages
                          ? Color(0xFF6C757D)
                          : Color(0xFFADB5BD),
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
                  // Page info
                  const SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Page $currentPage of $totalPages (${totalSubCategories} total)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6C757D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      default:
        return Color(0xFF6C757D);
    }
  }

  Color _getSubCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'computers':
        return Color(0xFF17A2B8);
      case 'electronics':
        return Color(0xFF28A745);
      case 'shoe':
        return Color(0xFFDC3545);
      default:
        return Color(0xFF6F42C1);
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF343A40),
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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

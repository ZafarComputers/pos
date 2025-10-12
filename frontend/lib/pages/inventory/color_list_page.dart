import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import '../../services/inventory_service.dart';
import '../../models/color.dart' as color_model;

class ColorListPage extends StatefulWidget {
  const ColorListPage({super.key});

  @override
  State<ColorListPage> createState() => _ColorListPageState();
}

class _ColorListPageState extends State<ColorListPage> {
  List<color_model.Color> colors = [];
  List<color_model.Color> _filteredColors = [];
  List<color_model.Color> _allFilteredColors =
      []; // Store all filtered colors for local pagination
  List<color_model.Color> _allColorsCache =
      []; // Cache for all colors to avoid refetching
  bool isLoading = false;
  bool isPaginationLoading = false;
  String? errorMessage;
  int currentPage = 1;
  int totalColors = 0;
  int totalPages = 1;
  final int itemsPerPage = 10;
  Timer? _searchDebounceTimer; // Add debounce timer for search
  bool _isFilterActive = false; // Track if any filter is currently active

  String selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Predefined color options
  final List<String> predefinedColors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Black',
    'White',
    'Orange',
    'Purple',
    'Pink',
    'Brown',
    'Grey',
    'Navy',
    'Maroon',
    'Teal',
    'Olive',
    'Lime',
    'Aqua',
    'Silver',
    'Gold',
    'Beige',
    'Coral',
    'Crimson',
    'Indigo',
    'Violet',
    'Turquoise',
    'Magenta',
    'Cyan',
    'Lavender',
    'Salmon',
    'Khaki',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllColorsOnInit(); // Fetch all colors once on page load
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  void refreshColors() {
    _fetchAllColorsOnInit();
  }

  // Fetch all colors once when page loads
  Future<void> _fetchAllColorsOnInit() async {
    try {
      print('🚀 Initial load: Fetching all colors');
      setState(() {
        errorMessage = null;
      });

      // Fetch all colors from all pages
      List<color_model.Color> allColors = [];
      int currentFetchPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          print('📡 Fetching page $currentFetchPage');
          final response = await InventoryService.getColors(
            page: currentFetchPage,
            limit: 50, // Use larger page size for efficiency
          );

          allColors.addAll(response.data);
          print(
            '📦 Page $currentFetchPage: ${response.data.length} colors (total: ${allColors.length})',
          );

          // Check if there are more pages
          if (response.currentPage >= response.lastPage) {
            hasMorePages = false;
          } else {
            currentFetchPage++;
          }
        } catch (e) {
          print('❌ Error fetching page $currentFetchPage: $e');
          hasMorePages = false; // Stop fetching on error
        }
      }

      _allColorsCache = allColors;
      print('💾 Cached ${_allColorsCache.length} total colors');

      // Apply initial filters (which will be no filters, showing all colors)
      _applyFiltersClientSide();
    } catch (e) {
      print('❌ Critical error in _fetchAllColorsOnInit: $e');
      setState(() {
        errorMessage = 'Failed to load colors. Please refresh the page.';
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

      // Apply filters to cached colors (no API calls)
      _filterCachedColors(searchText);

      print('🔄 _isFilterActive: $_isFilterActive');
      print('📦 _allColorsCache.length: ${_allColorsCache.length}');
      print('🎯 _allFilteredColors.length: ${_allFilteredColors.length}');
      print('👀 _filteredColors.length: ${_filteredColors.length}');
    } catch (e) {
      print('❌ Error in _applyFiltersClientSide: $e');
      setState(() {
        errorMessage = 'Search error: Please try a different search term';
        isLoading = false;
        _filteredColors = [];
      });
    }
  }

  // Filter cached colors without any API calls
  void _filterCachedColors(String searchText) {
    try {
      // Apply filters to cached colors with enhanced error handling
      _allFilteredColors = _allColorsCache.where((color) {
        try {
          // Status filter
          if (selectedStatus != 'All' && color.status != selectedStatus) {
            return false;
          }

          // Search filter
          if (searchText.isEmpty) {
            return true;
          }

          // Search in color title
          final colorTitle = color.title.toLowerCase();
          return colorTitle.contains(searchText);
        } catch (e) {
          // If there's any error during filtering, exclude this color
          print('⚠️ Error filtering color ${color.id}: $e');
          return false;
        }
      }).toList();

      print(
        '🔍 After filtering: ${_allFilteredColors.length} colors match criteria',
      );
      print('📝 Search text: "$searchText", Status filter: "$selectedStatus"');

      // Apply local pagination to filtered results
      _paginateFilteredColors();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Critical error in _filterCachedColors: $e');
      setState(() {
        errorMessage =
            'Search failed. Please try again with a simpler search term.';
        isLoading = false;
        // Fallback: show empty results instead of crashing
        _filteredColors = [];
        _allFilteredColors = [];
      });
    }
  }

  // Apply local pagination to filtered colors
  void _paginateFilteredColors() {
    try {
      // Handle empty results case
      if (_allFilteredColors.isEmpty) {
        setState(() {
          _filteredColors = [];
          totalColors = 0;
          totalPages = 1;
          currentPage = 1;
        });
        return;
      }

      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      // Ensure startIndex is not greater than the list length
      if (startIndex >= _allFilteredColors.length) {
        // Reset to page 1 if current page is out of bounds
        setState(() {
          currentPage = 1;
        });
        _paginateFilteredColors(); // Recursive call with corrected page
        return;
      }

      setState(() {
        _filteredColors = _allFilteredColors.sublist(
          startIndex,
          endIndex > _allFilteredColors.length
              ? _allFilteredColors.length
              : endIndex,
        );

        totalColors = _allFilteredColors.length;
        totalPages = (totalColors / itemsPerPage).ceil();
        print('📄 Pagination calculation:');
        print('   📊 _allFilteredColors.length: ${_allFilteredColors.length}');
        print('   📝 itemsPerPage: $itemsPerPage');
        print('   🔢 totalPages: $totalPages');
        print('   📍 currentPage: $currentPage');
      });
    } catch (e) {
      print('❌ Error in _paginateFilteredColors: $e');
      setState(() {
        _filteredColors = [];
        currentPage = 1;
      });
    }
  }

  // Handle page changes for both filtered and normal pagination
  Future<void> _changePage(int newPage) async {
    setState(() {
      currentPage = newPage;
    });

    // Always use client-side pagination when we have cached colors
    if (_allColorsCache.isNotEmpty) {
      _paginateFilteredColors();
    } else {
      // Fallback to server pagination only if no cached data
      await _fetchColors(page: newPage);
    }
  }

  Future<void> _fetchColors({int page = 1}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await InventoryService.getColors(
        page: page,
        limit: itemsPerPage,
      );

      setState(() {
        colors = response.data;
        currentPage = response.currentPage;
        totalColors = response.total;
        totalPages = response.lastPage;
        isLoading = false;
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F42C1)),
                ),
                SizedBox(width: 16),
                Text('Fetching all colors...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL colors from database for export
      List<color_model.Color> allColorsForExport = [];

      try {
        // Use the current filtered colors for export
        allColorsForExport = List.from(colors);

        // If no filters are applied, fetch fresh data from server
        if (colors.length == totalColors &&
            _searchController.text.trim().isEmpty &&
            selectedStatus == 'All') {
          // Fetch ALL colors with unlimited pagination
          allColorsForExport = [];
          int currentPage = 1;
          bool hasMorePages = true;

          while (hasMorePages) {
            final pageResponse = await InventoryService.getColors(
              page: currentPage,
              limit: 100, // Fetch in chunks of 100
            );

            allColorsForExport.addAll(pageResponse.data);

            // Check if there are more pages
            if (pageResponse.currentPage >= pageResponse.lastPage) {
              hasMorePages = false;
            } else {
              currentPage++;
            }
          }
        }
      } catch (e) {
        print('Error fetching all colors: $e');
        // Fallback to current data
        allColorsForExport = colors.isNotEmpty ? colors : [];
      }

      if (allColorsForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No colors to export'),
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
                  'Generating PDF with ${allColorsForExport.length} colors...',
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
      final PdfColor headerColor = PdfColor(111, 66, 193); // Color theme color
      final PdfColor tableHeaderColor = PdfColor(248, 249, 250);

      // Create table with proper settings for pagination
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 3);

      // Use full page width but account for table borders and padding
      final double pageWidth =
          document.pageSettings.size.width -
          15; // Only 15px left margin, 0px right margin
      final double tableWidth =
          pageWidth *
          0.85; // Use 85% to ensure right boundary is clearly visible

      // Balanced column widths for colors
      grid.columns[0].width = tableWidth * 0.40; // 40% - Color Name
      grid.columns[1].width = tableWidth * 0.25; // 25% - Status
      grid.columns[2].width = tableWidth * 0.35; // 35% - Created Date

      // Enable automatic page breaking and row splitting
      grid.allowRowBreakingAcrossPages = true;

      // Set grid style with better padding for readability
      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
        font: smallFont,
      );

      // Add header row
      final PdfGridRow headerRow = grid.headers.add(1)[0];
      headerRow.cells[0].value = 'Color Name';
      headerRow.cells[1].value = 'Status';
      headerRow.cells[2].value = 'Created Date';

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

      // Add all color data rows
      for (var color in allColorsForExport) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = color.title;
        row.cells[1].value = color.status;

        // Format created date
        String formattedDate = 'N/A';
        try {
          final date = DateTime.parse(color.createdAt);
          formattedDate = '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          // Keep default value
        }
        row.cells[2].value = formattedDate;

        // Style data cells with better text wrapping
        for (int i = 0; i < row.cells.count; i++) {
          row.cells[i].style = PdfGridCellStyle(
            font: smallFont,
            textBrush: PdfSolidBrush(PdfColor(33, 37, 41)),
            format: PdfStringFormat(
              alignment: i == 1
                  ? PdfTextAlignment.center
                  : PdfTextAlignment.left,
              lineAlignment: PdfVerticalAlignment.top,
              wordWrap: PdfWordWrapType.word,
            ),
          );
        }

        // Color code status
        if (color.status == 'Active') {
          row.cells[1].style.backgroundBrush = PdfSolidBrush(
            PdfColor(212, 237, 218),
          );
          row.cells[1].style.textBrush = PdfSolidBrush(PdfColor(21, 87, 36));
        } else {
          row.cells[1].style.backgroundBrush = PdfSolidBrush(
            PdfColor(248, 215, 218),
          );
          row.cells[1].style.textBrush = PdfSolidBrush(PdfColor(114, 28, 36));
        }
      }

      // Set up page template for headers and footers
      final PdfPageTemplateElement headerTemplate = PdfPageTemplateElement(
        Rect.fromLTWH(0, 0, document.pageSettings.size.width, 50),
      );

      // Draw header on template - minimal left margin, full width
      headerTemplate.graphics.drawString(
        'Complete Colors Database Export',
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
      if (_searchController.text.isNotEmpty)
        filters.add('Search="${_searchController.text}"');
      if (filters.isEmpty) filters.add('All');

      headerTemplate.graphics.drawString(
        'Total Colors: ${allColorsForExport.length} | Generated: ${DateTime.now().toString().substring(0, 19)} | $filterInfo${filters.join(', ')}',
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
        'Page \$PAGE of \$TOTAL | ${allColorsForExport.length} Total Colors | Generated from POS System',
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
        'PDF generated with $pageCount page(s) for ${allColorsForExport.length} colors',
      );

      // Save PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Complete Colors Database PDF',
        fileName:
            'complete_colors_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
                '✅ Complete Database Exported!\n🎨 ${allColorsForExport.length} colors across $pageCount pages\n📄 Landscape format for better visibility',
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
                Text('Fetching all colors...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL colors from database for export
      List<color_model.Color> allColorsForExport = [];

      try {
        // Use the current filtered colors for export
        allColorsForExport = List.from(colors);

        // If no filters are applied, fetch fresh data from server
        if (colors.length == totalColors &&
            _searchController.text.trim().isEmpty &&
            selectedStatus == 'All') {
          // Fetch ALL colors with unlimited pagination
          allColorsForExport = [];
          int currentPage = 1;
          bool hasMorePages = true;

          while (hasMorePages) {
            final pageResponse = await InventoryService.getColors(
              page: currentPage,
              limit: 100, // Fetch in chunks of 100
            );

            allColorsForExport.addAll(pageResponse.data);

            // Check if there are more pages
            if (pageResponse.currentPage >= pageResponse.lastPage) {
              hasMorePages = false;
            } else {
              currentPage++;
            }
          }
        }
      } catch (e) {
        print('Error fetching all colors: $e');
        // Fallback to current data
        allColorsForExport = colors.isNotEmpty ? colors : [];
      }

      if (allColorsForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No colors to export'),
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
                  'Generating Excel with ${allColorsForExport.length} colors...',
                ),
              ],
            ),
          );
        },
      );

      // Create a new Excel document
      final excel_pkg.Excel excel = excel_pkg.Excel.createExcel();
      final excel_pkg.Sheet sheet = excel['Colors'];

      // Add header row with styling
      sheet.appendRow([
        excel_pkg.TextCellValue('Color Name'),
        excel_pkg.TextCellValue('Status'),
        excel_pkg.TextCellValue('Created Date'),
      ]);

      // Style header row
      final headerStyle = excel_pkg.CellStyle(bold: true, fontSize: 12);

      for (int i = 0; i < 3; i++) {
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

      // Add all color data rows
      for (var color in allColorsForExport) {
        // Format created date
        String formattedDate = 'N/A';
        try {
          final date = DateTime.parse(color.createdAt);
          formattedDate = '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          // Keep default value
        }

        sheet.appendRow([
          excel_pkg.TextCellValue(color.title),
          excel_pkg.TextCellValue(color.status),
          excel_pkg.TextCellValue(formattedDate),
        ]);
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
        dialogTitle: 'Save Complete Colors Database Excel',
        fileName:
            'complete_colors_${DateTime.now().millisecondsSinceEpoch}.xlsx',
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
                '✅ Complete Database Exported!\n🎨 ${allColorsForExport.length} colors exported to Excel\n📊 Ready for analysis',
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

  void addNewColor() async {
    String selectedColor = predefinedColors[0]; // Default to first color
    String selectedStatus = 'Active';

    final parentContext = context; // Store parent context

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
                  Icon(Icons.color_lens, color: Color(0xFF17A2B8)),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Color',
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
                    // Color Preview
                    Container(
                      width: 80,
                      height: 60,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _getColorFromName(selectedColor),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFDEE2E6)),
                      ),
                      child: Center(
                        child: Text(
                          selectedColor,
                          style: TextStyle(
                            color: _getContrastColor(
                              _getColorFromName(selectedColor),
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedColor,
                      decoration: InputDecoration(
                        labelText: 'Select Color *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: predefinedColors
                          .map(
                            (color) => DropdownMenuItem(
                              value: color,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: _getColorFromName(color),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Color(0xFFDEE2E6),
                                      ),
                                    ),
                                  ),
                                  Text(color),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedColor = value);
                        }
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
                    try {
                      Navigator.of(context).pop(true); // Close dialog first
                      if (mounted) setState(() => isLoading = true);

                      final createData = {
                        'title': selectedColor,
                        'status': selectedStatus,
                      };

                      await InventoryService.createColor(createData);

                      // Refresh the colors cache and apply current filters
                      await _fetchAllColorsOnInit();

                      if (!mounted) return;
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Color created successfully'),
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
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Failed to create color: $e'),
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

  void editColor(color_model.Color color) async {
    String selectedColor = color.title;
    String selectedStatus = color.status;

    final parentContext = context; // Store parent context

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
                    'Edit Color',
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
                    // Color Preview
                    Container(
                      width: 80,
                      height: 60,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _getColorFromName(selectedColor),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFDEE2E6)),
                      ),
                      child: Center(
                        child: Text(
                          selectedColor,
                          style: TextStyle(
                            color: _getContrastColor(
                              _getColorFromName(selectedColor),
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedColor,
                      decoration: InputDecoration(
                        labelText: 'Select Color *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: predefinedColors
                          .map(
                            (colorOption) => DropdownMenuItem(
                              value: colorOption,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: _getColorFromName(colorOption),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Color(0xFFDEE2E6),
                                      ),
                                    ),
                                  ),
                                  Text(colorOption),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedColor = value);
                        }
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
                    try {
                      Navigator.of(context).pop(true); // Close dialog first
                      if (mounted) setState(() => isLoading = true);

                      final updateData = {
                        'title': selectedColor,
                        'status': selectedStatus,
                      };

                      await InventoryService.updateColor(color.id, updateData);

                      // Refresh the colors cache and apply current filters
                      await _fetchAllColorsOnInit();

                      if (!mounted) return;
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Color updated successfully'),
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
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Failed to update color: $e'),
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

  void deleteColor(color_model.Color color) {
    final parentContext = context; // Store parent context

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
              Text('Delete Color'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${color.title}"?\n\nThis will also remove all associated products.',
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
                  if (mounted) setState(() => isLoading = true);

                  await InventoryService.deleteColor(color.id);

                  // Remove from cache and update UI in real-time
                  setState(() {
                    _allColorsCache.removeWhere((c) => c.id == color.id);
                  });

                  // Re-apply current filters to update the display
                  _applyFiltersClientSide();

                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Color deleted successfully'),
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
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Failed to delete color: $e'),
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

  void viewColorDetails(color_model.Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<color_model.Color>(
              future: InventoryService.getColor(color.id),
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
                          'Color Details',
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
                            'Loading color details...',
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
                        'Failed to load color details: ${snapshot.error}',
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
                          'Color Details',
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
                          // Color Preview
                          Container(
                            width: 100,
                            height: 100,
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: _getColorFromName(details.title),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFDEE2E6)),
                            ),
                            child: Center(
                              child: Text(
                                details.title,
                                style: TextStyle(
                                  color: _getContrastColor(
                                    _getColorFromName(details.title),
                                  ),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                          // Details
                          _buildDetailRow('Title', details.title),
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

  Color _getColorFromName(String name) {
    // Map color names to actual Color objects
    final colorMap = {
      'Red': Colors.red,
      'Blue': Colors.blue,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Black': Colors.black,
      'White': Colors.white,
      'Orange': Colors.orange,
      'Purple': Colors.purple,
      'Pink': Colors.pink,
      'Brown': const Color(0xFF8B4513),
      'Grey': Colors.grey,
      'Navy': const Color(0xFF000080),
      'Maroon': const Color(0xFF800000),
    };

    return colorMap[name] ?? Colors.grey;
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if text should be black or white
    final luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1845),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF6C757D)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colors'),
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
                          Icons.color_lens,
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
                              'Colors',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage your color inventory and details',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: addNewColor,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add New Color'),
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
                        'Total Colors',
                        _allFilteredColors.length.toString(),
                        Icons.color_lens,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Active Colors',
                        _allFilteredColors
                            .where((c) => c.status == 'Active')
                            .length
                            .toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Inactive Colors',
                        _allFilteredColors
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
                                    hintText: 'Search by name, code...',
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
                          // Color Preview Column
                          SizedBox(
                            width: 80,
                            child: Text('Color', style: _headerStyle()),
                          ),
                          const SizedBox(width: 50),
                          // Name Column
                          Expanded(
                            flex: 2,
                            child: Text('Name', style: _headerStyle()),
                          ),
                          const SizedBox(width: 20),
                          // Code Column
                          Expanded(
                            flex: 1,
                            child: Text('Code', style: _headerStyle()),
                          ),
                          const SizedBox(width: 20),
                          // Status Column
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text('Status', style: _headerStyle()),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Actions Column
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
                                    onPressed: _fetchColors,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _filteredColors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.color_lens_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isFilterActive
                                        ? 'No colors match your filters'
                                        : 'No colors found',
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
                              itemCount: _filteredColors.length,
                              itemBuilder: (context, index) {
                                final colorItem = _filteredColors[index];
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
                                      // Color Preview Column
                                      SizedBox(
                                        width: 80,
                                        height: 40,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _getColorFromName(
                                              colorItem.title,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              colorItem.title.length > 3
                                                  ? colorItem.title
                                                        .substring(0, 3)
                                                        .toUpperCase()
                                                  : colorItem.title
                                                        .toUpperCase(),
                                              style: TextStyle(
                                                color: _getContrastColor(
                                                  _getColorFromName(
                                                    colorItem.title,
                                                  ),
                                                ),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 50),
                                      // Name Column
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          colorItem.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0D1845),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      // Code Column - Placeholder since model doesn't have code
                                      Expanded(
                                        flex: 1,
                                        child: Text('N/A', style: _cellStyle()),
                                      ),
                                      const SizedBox(width: 20),
                                      // Status Column
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
                                                  colorItem.status == 'Active'
                                                  ? Colors.green.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              colorItem.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    colorItem.status == 'Active'
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
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
                                                  viewColorDetails(colorItem),
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
                                                  editColor(colorItem),
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
                                                  deleteColor(colorItem),
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
            if (_allFilteredColors.isNotEmpty) ...[
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
                        'Page $currentPage of ${(_allFilteredColors.length / itemsPerPage).ceil()} (${_allFilteredColors.length} total)',
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
                              (_allFilteredColors.length / itemsPerPage).ceil()
                          ? () => _changePage(currentPage + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 16),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            currentPage <
                                (_allFilteredColors.length / itemsPerPage)
                                    .ceil()
                            ? const Color(0xFF0D1845)
                            : Colors.grey.shade300,
                        foregroundColor:
                            currentPage <
                                (_allFilteredColors.length / itemsPerPage)
                                    .ceil()
                            ? Colors.white
                            : Colors.grey.shade600,
                        elevation:
                            currentPage <
                                (_allFilteredColors.length / itemsPerPage)
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
}

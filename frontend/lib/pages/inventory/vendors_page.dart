import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../../services/inventory_service.dart';
import '../../models/vendor.dart' as vendor;

class VendorsPage extends StatefulWidget {
  const VendorsPage({super.key});

  @override
  State<VendorsPage> createState() => _VendorsPageState();
}

class _VendorsPageState extends State<VendorsPage> {
  vendor.VendorResponse? vendorResponse;
  List<vendor.Vendor> _filteredVendors = [];
  List<vendor.Vendor> _allFilteredVendors =
      []; // Store all filtered vendors for local pagination
  List<vendor.Vendor> _allVendorsCache =
      []; // Cache for all vendors to avoid refetching
  bool isLoading = false; // Start with false to show UI immediately
  String? errorMessage;
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool _isDeletingVendor = false; // Add this flag for delete loading state
  Timer? _searchDebounceTimer; // Add debounce timer for search
  bool _isFilterActive = false; // Track if any filter is currently active

  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAllVendorsOnInit(); // Fetch all vendors once on page load
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  // Fetch all vendors once when page loads
  Future<void> _fetchAllVendorsOnInit() async {
    try {
      print('🚀 Initial load: Fetching all vendors');
      setState(() {
        errorMessage = null;
      });

      // Fetch all vendors from all pages
      List<vendor.Vendor> allVendors = [];
      int currentFetchPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          print('📡 Fetching page $currentFetchPage');
          final response = await InventoryService.getVendors(
            page: currentFetchPage,
            limit: 50, // Use larger page size for efficiency
          );

          allVendors.addAll(response.data);
          print(
            '📦 Page $currentFetchPage: ${response.data.length} vendors (total: ${allVendors.length})',
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

      _allVendorsCache = allVendors;
      print('💾 Cached ${_allVendorsCache.length} total vendors');

      // Apply initial filters (which will be no filters, showing all vendors)
      _applyFiltersClientSide();
    } catch (e) {
      print('❌ Critical error in _fetchAllVendorsOnInit: $e');
      setState(() {
        errorMessage = 'Failed to load vendors. Please refresh the page.';
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

      // Apply filters to cached vendors (no API calls)
      _filterCachedVendors(searchText);

      print('🔄 _isFilterActive: $_isFilterActive');
      print('📦 _allVendorsCache.length: ${_allVendorsCache.length}');
      print('🎯 _allFilteredVendors.length: ${_allFilteredVendors.length}');
      print('👀 _filteredVendors.length: ${_filteredVendors.length}');
    } catch (e) {
      print('❌ Error in _applyFiltersClientSide: $e');
      setState(() {
        errorMessage = 'Search error: Please try a different search term';
        isLoading = false;
        _filteredVendors = [];
      });
    }
  }

  // Filter cached vendors without any API calls
  void _filterCachedVendors(String searchText) {
    try {
      // Apply filters to cached vendors with enhanced error handling
      _allFilteredVendors = _allVendorsCache.where((vendor) {
        try {
          // Status filter
          if (selectedStatus != 'All' && vendor.status != selectedStatus) {
            return false;
          }

          // Search filter
          if (searchText.isEmpty) {
            return true;
          }

          // Search in multiple fields with better null safety and error handling
          final vendorFullName = vendor.fullName.toLowerCase();
          final vendorCode = vendor.vendorCode.toLowerCase();
          final vendorFirstName = vendor.firstName.toLowerCase();
          final vendorLastName = vendor.lastName.toLowerCase();
          final vendorCnic = vendor.cnic.toLowerCase();
          final vendorAddress = vendor.address?.toLowerCase() ?? '';
          final vendorCity = vendor.city.title.toLowerCase();

          return vendorFullName.contains(searchText) ||
              vendorCode.contains(searchText) ||
              vendorFirstName.contains(searchText) ||
              vendorLastName.contains(searchText) ||
              vendorCnic.contains(searchText) ||
              vendorAddress.contains(searchText) ||
              vendorCity.contains(searchText);
        } catch (e) {
          // If there's any error during filtering, exclude this vendor
          print('⚠️ Error filtering vendor ${vendor.id}: $e');
          return false;
        }
      }).toList();

      print(
        '🔍 After filtering: ${_allFilteredVendors.length} vendors match criteria',
      );
      print('📝 Search text: "$searchText", Status filter: "$selectedStatus"');

      // Apply local pagination to filtered results
      _paginateFilteredVendors();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ Critical error in _filterCachedVendors: $e');
      setState(() {
        errorMessage =
            'Search failed. Please try again with a simpler search term.';
        isLoading = false;
        // Fallback: show empty results instead of crashing
        _filteredVendors = [];
        _allFilteredVendors = [];
      });
    }
  }

  // Apply local pagination to filtered vendors
  void _paginateFilteredVendors() {
    try {
      // Handle empty results case
      if (_allFilteredVendors.isEmpty) {
        setState(() {
          _filteredVendors = [];
          // Update vendorResponse meta for pagination controls
          vendorResponse = vendor.VendorResponse(
            data: [],
            links: vendor.Links(),
            meta: vendor.Meta(
              currentPage: 1,
              lastPage: 1,
              links: [],
              path: "/vendors",
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
      if (startIndex >= _allFilteredVendors.length) {
        // Reset to page 1 if current page is out of bounds
        setState(() {
          currentPage = 1;
        });
        _paginateFilteredVendors(); // Recursive call with corrected page
        return;
      }

      setState(() {
        _filteredVendors = _allFilteredVendors.sublist(
          startIndex,
          endIndex > _allFilteredVendors.length
              ? _allFilteredVendors.length
              : endIndex,
        );

        // Update vendorResponse meta for pagination controls
        final totalPages = (_allFilteredVendors.length / itemsPerPage).ceil();
        print('📄 Pagination calculation:');
        print(
          '   📊 _allFilteredVendors.length: ${_allFilteredVendors.length}',
        );
        print('   📝 itemsPerPage: $itemsPerPage');
        print('   🔢 totalPages: $totalPages');
        print('   📍 currentPage: $currentPage');

        vendorResponse = vendor.VendorResponse(
          data: _filteredVendors,
          links: vendor.Links(), // Empty links for local pagination
          meta: vendor.Meta(
            currentPage: currentPage,
            lastPage: totalPages,
            links: [], // Empty links array for local pagination
            path: "/vendors", // Default path
            perPage: itemsPerPage,
            total: _allFilteredVendors.length,
          ),
        );
      });
    } catch (e) {
      print('❌ Error in _paginateFilteredVendors: $e');
      setState(() {
        _filteredVendors = [];
        currentPage = 1;
      });
    }
  }

  // Handle page changes for both filtered and normal pagination
  Future<void> _changePage(int newPage) async {
    setState(() {
      currentPage = newPage;
    });

    // Always use client-side pagination when we have cached vendors
    if (_allVendorsCache.isNotEmpty) {
      _paginateFilteredVendors();
    } else {
      // Fallback to server pagination only if no cached data
      await _fetchVendors(page: newPage);
    }
  }

  Future<void> _fetchVendors({int page = 1}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await InventoryService.getVendors(
        page: page,
        limit: itemsPerPage,
      );
      setState(() {
        vendorResponse = response;
        currentPage = page;
        isLoading = false;
        _filteredVendors = response.data;
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF17A2B8)),
                ),
                SizedBox(width: 16),
                Text('Preparing export...'),
              ],
            ),
          );
        },
      );

      // Use cached vendors for export, apply current filters
      List<vendor.Vendor> allVendorsForExport = List.from(_allVendorsCache);

      // Apply filters if any are active
      if (_searchController.text.isNotEmpty || selectedStatus != 'All') {
        final searchText = _searchController.text.toLowerCase().trim();
        allVendorsForExport = allVendorsForExport.where((vendor) {
          // Status filter
          if (selectedStatus != 'All' && vendor.status != selectedStatus) {
            return false;
          }

          // Search filter
          if (searchText.isEmpty) {
            return true;
          }

          // Search in multiple fields
          return vendor.fullName.toLowerCase().contains(searchText) ||
              vendor.vendorCode.toLowerCase().contains(searchText) ||
              vendor.firstName.toLowerCase().contains(searchText) ||
              vendor.lastName.toLowerCase().contains(searchText) ||
              vendor.cnic.toLowerCase().contains(searchText) ||
              (vendor.address?.toLowerCase().contains(searchText) ?? false) ||
              vendor.city.title.toLowerCase().contains(searchText);
        }).toList();
      }

      if (allVendorsForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No vendors to export'),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF17A2B8)),
                ),
                SizedBox(width: 16),
                Text(
                  'Generating PDF with ${allVendorsForExport.length} vendors...',
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
      final PdfColor headerColor = PdfColor(23, 162, 184);
      final PdfColor tableHeaderColor = PdfColor(248, 249, 250);

      // Create table with proper settings for pagination
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 6);

      // Use full page width but account for table borders and padding
      final double pageWidth =
          document.pageSettings.size.width -
          15; // Only 15px left margin, 0px right margin
      final double tableWidth =
          pageWidth *
          0.85; // Use 85% to ensure right boundary is clearly visible

      // Balanced column widths - reduce address width to prevent cutoff
      grid.columns[0].width = tableWidth * 0.12; // 12% - Vendor Code
      grid.columns[1].width = tableWidth * 0.22; // 22% - Vendor Name
      grid.columns[2].width = tableWidth * 0.16; // 16% - CNIC
      grid.columns[3].width = tableWidth * 0.14; // 14% - City
      grid.columns[4].width = tableWidth * 0.10; // 10% - Status
      grid.columns[5].width =
          tableWidth * 0.26; // 26% - Address (with truncation)

      // Enable automatic page breaking and row splitting
      grid.allowRowBreakingAcrossPages = true;

      // Set grid style with better padding for readability
      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 4, right: 4, top: 4, bottom: 4),
        font: smallFont,
      );

      // Add header row
      final PdfGridRow headerRow = grid.headers.add(1)[0];
      headerRow.cells[0].value = 'Vendor Code';
      headerRow.cells[1].value = 'Vendor Name';
      headerRow.cells[2].value = 'CNIC';
      headerRow.cells[3].value = 'City';
      headerRow.cells[4].value = 'Status';
      headerRow.cells[5].value = 'Address';

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

      // Add all vendor data rows
      for (var vendorItem in allVendorsForExport) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = vendorItem.vendorCode;
        row.cells[1].value = vendorItem.fullName;
        row.cells[2].value = vendorItem.cnic;
        row.cells[3].value = vendorItem.city.title;
        row.cells[4].value = vendorItem.status;

        // Handle address with better formatting and truncation if needed
        String addressText = vendorItem.address ?? 'N/A';
        // Limit address length to prevent excessive width
        if (addressText.length > 80) {
          addressText = '${addressText.substring(0, 77)}...';
        }
        row.cells[5].value = addressText;

        // Style data cells with better text wrapping
        for (int i = 0; i < row.cells.count; i++) {
          // Special formatting for address column to ensure proper wrapping
          if (i == 5) {
            row.cells[i].style = PdfGridCellStyle(
              font: smallFont,
              textBrush: PdfSolidBrush(PdfColor(33, 37, 41)),
              format: PdfStringFormat(
                alignment: PdfTextAlignment.left,
                lineAlignment: PdfVerticalAlignment.top,
                wordWrap: PdfWordWrapType.wordOnly,
              ),
            );
          } else {
            row.cells[i].style = PdfGridCellStyle(
              font: smallFont,
              textBrush: PdfSolidBrush(PdfColor(33, 37, 41)),
              format: PdfStringFormat(
                alignment: i == 4
                    ? PdfTextAlignment.center
                    : PdfTextAlignment.left,
                lineAlignment: PdfVerticalAlignment.top,
                wordWrap: PdfWordWrapType.word,
              ),
            );
          }
        }

        // Color code status
        if (vendorItem.status == 'Active') {
          row.cells[4].style.backgroundBrush = PdfSolidBrush(
            PdfColor(212, 237, 218),
          );
          row.cells[4].style.textBrush = PdfSolidBrush(PdfColor(21, 87, 36));
        } else {
          row.cells[4].style.backgroundBrush = PdfSolidBrush(
            PdfColor(248, 215, 218),
          );
          row.cells[4].style.textBrush = PdfSolidBrush(PdfColor(114, 28, 36));
        }
      }

      // Set up page template for headers and footers
      final PdfPageTemplateElement headerTemplate = PdfPageTemplateElement(
        Rect.fromLTWH(0, 0, document.pageSettings.size.width, 50),
      );

      // Draw header on template - minimal left margin, full width
      headerTemplate.graphics.drawString(
        'Complete Vendors Database Export',
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
        'Total Vendors: ${allVendorsForExport.length} | Generated: ${DateTime.now().toString().substring(0, 19)} | Filters: ${selectedStatus != 'All' ? 'Status=$selectedStatus' : 'All'} ${_searchController.text.isNotEmpty ? ', Search="${_searchController.text}"' : ''}',
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
        'Page \$PAGE of \$TOTAL | ${allVendorsForExport.length} Total Vendors | Generated from POS System',
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
        'PDF generated with $pageCount page(s) for ${allVendorsForExport.length} vendors',
      );

      // Save PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Complete Vendors Database PDF',
        fileName:
            'complete_vendors_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
                '✅ Complete Database Exported!\n📊 ${allVendorsForExport.length} vendors across $pageCount pages\n📄 Landscape format for better visibility',
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF17A2B8)),
                ),
                SizedBox(width: 16),
                Text('Preparing export...'),
              ],
            ),
          );
        },
      );

      // Use cached vendors for export, apply current filters
      List<vendor.Vendor> allVendorsForExport = List.from(_allVendorsCache);

      // Apply filters if any are active
      if (_searchController.text.isNotEmpty || selectedStatus != 'All') {
        final searchText = _searchController.text.toLowerCase().trim();
        allVendorsForExport = allVendorsForExport.where((vendor) {
          // Status filter
          if (selectedStatus != 'All' && vendor.status != selectedStatus) {
            return false;
          }

          // Search filter
          if (searchText.isEmpty) {
            return true;
          }

          // Search in multiple fields
          return vendor.fullName.toLowerCase().contains(searchText) ||
              vendor.vendorCode.toLowerCase().contains(searchText) ||
              vendor.firstName.toLowerCase().contains(searchText) ||
              vendor.lastName.toLowerCase().contains(searchText) ||
              vendor.cnic.toLowerCase().contains(searchText) ||
              (vendor.address?.toLowerCase().contains(searchText) ?? false) ||
              vendor.city.title.toLowerCase().contains(searchText);
        }).toList();
      }

      if (allVendorsForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No vendors to export'),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF17A2B8)),
                ),
                SizedBox(width: 16),
                Text(
                  'Generating Excel with ${allVendorsForExport.length} vendors...',
                ),
              ],
            ),
          );
        },
      );

      // Create Excel document
      final excel_pkg.Excel excel = excel_pkg.Excel.createExcel();
      final excel_pkg.Sheet sheet = excel['Vendors'];

      // Add header row
      sheet.appendRow([
        excel_pkg.TextCellValue('Vendor Code'),
        excel_pkg.TextCellValue('Vendor Name'),
        excel_pkg.TextCellValue('CNIC'),
        excel_pkg.TextCellValue('City'),
        excel_pkg.TextCellValue('Status'),
        excel_pkg.TextCellValue('Address'),
      ]);

      // Add data rows
      for (var vendorItem in allVendorsForExport) {
        sheet.appendRow([
          excel_pkg.TextCellValue(vendorItem.vendorCode),
          excel_pkg.TextCellValue(vendorItem.fullName),
          excel_pkg.TextCellValue(vendorItem.cnic),
          excel_pkg.TextCellValue(vendorItem.city.title),
          excel_pkg.TextCellValue(vendorItem.status),
          excel_pkg.TextCellValue(vendorItem.address ?? 'N/A'),
        ]);
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'vendors_export_$timestamp.xlsx';

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Vendors Excel Export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        // Save Excel file
        final List<int>? bytes = excel.encode();
        if (bytes != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Excel Export Complete!\n📊 ${allVendorsForExport.length} vendors exported\n📄 File saved as: ${fileName.split('_').last}',
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

  void addNewVendor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddVendorDialog(
          onVendorAdded: () {
            // Refresh the vendor cache after adding
            _fetchAllVendorsOnInit();
          },
        );
      },
    );
  }

  void viewVendor(vendor.Vendor vendor) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.business, color: Color(0xFF17A2B8), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vendor Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF343A40),
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF17A2B8)),
                ),
                SizedBox(height: 16),
                Text(
                  'Fetching vendor details...',
                  style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF17A2B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(24),
        );
      },
    );

    // Fetch vendor details asynchronously
    try {
      final vendorDetails = await InventoryService.getVendor(vendor.id);

      // Close loading dialog and show success dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.business, color: Color(0xFF17A2B8), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vendor Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF343A40),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Basic Information
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17A2B8),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow(
                            'Vendor ID',
                            vendorDetails.id.toString(),
                          ),
                          _buildDetailRow(
                            'First Name',
                            vendorDetails.firstName,
                          ),
                          _buildDetailRow('Last Name', vendorDetails.lastName),
                          _buildDetailRow('Full Name', vendorDetails.fullName),
                          _buildDetailRow('CNIC', vendorDetails.cnic),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Address Information
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17A2B8),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow(
                            'Address',
                            vendorDetails.address ?? 'N/A',
                            isMultiline: true,
                          ),
                          _buildDetailRow('City ID', vendorDetails.cityId),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // City Information
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17A2B8),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow(
                            'City ID',
                            vendorDetails.city.id.toString(),
                          ),
                          _buildDetailRow(
                            'City Name',
                            vendorDetails.city.title,
                          ),
                          _buildDetailRow(
                            'State ID',
                            vendorDetails.city.stateId,
                          ),
                          _buildDetailRow(
                            'City Status',
                            vendorDetails.city.status,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Status & Timestamps
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status & Timestamps',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17A2B8),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow('Status', vendorDetails.status),
                          _buildDetailRow(
                            'Created At',
                            _formatDateTime(vendorDetails.createdAt),
                          ),
                          _buildDetailRow(
                            'Updated At',
                            _formatDateTime(vendorDetails.updatedAt),
                          ),
                          _buildDetailRow(
                            'City Created At',
                            _formatDateTime(vendorDetails.city.createdAt),
                          ),
                          _buildDetailRow(
                            'City Updated At',
                            _formatDateTime(vendorDetails.city.updatedAt),
                          ),
                        ],
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
                    style: TextStyle(
                      color: Color(0xFF17A2B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.all(24),
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog and show error dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFDC3545), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF343A40),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Failed to load vendor details: $e',
                style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF17A2B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.all(24),
            );
          },
        );
      }
    }
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C757D),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Color(0xFF343A40),
                fontSize: 12,
                fontFamily:
                    label == 'CNIC' ||
                        label == 'Vendor ID' ||
                        label.contains('ID')
                    ? 'monospace'
                    : null,
              ),
              maxLines: isMultiline ? null : 1,
              overflow: isMultiline
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  void editVendor(vendor.Vendor vendor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditVendorDialog(
          vendorData: vendor,
          onVendorUpdated: () {
            // Refresh the vendor cache after updating, staying on current page
            _fetchAllVendorsOnInit();
          },
        );
      },
    );
  }

  void deleteVendor(vendor.Vendor vendor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Color(0xFFDC3545), size: 24),
              SizedBox(width: 8),
              Text(
                'Delete Vendor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF343A40),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${vendor.fullName}"?\n\nThis action cannot be undone.',
            style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close confirmation dialog

                // Set loading state
                setState(() {
                  _isDeletingVendor = true;
                });

                try {
                  await InventoryService.deleteVendor(vendor.id);

                  if (mounted) {
                    // Remove from cache and update UI in real-time
                    setState(() {
                      _allVendorsCache.removeWhere((v) => v.id == vendor.id);
                    });

                    // Re-apply current filters to update the display
                    _applyFiltersClientSide();

                    // If current page is now empty and we're not on page 1, go to previous page
                    if (_filteredVendors.isEmpty && currentPage > 1) {
                      setState(() {
                        currentPage = currentPage - 1;
                      });
                      _paginateFilteredVendors();
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Vendor "${vendor.fullName}" deleted successfully',
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
                } catch (e) {
                  if (mounted) {
                    // Error occurred, but we'll just refresh the cache to show current state
                    _fetchAllVendorsOnInit();
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isDeletingVendor = false;
                    });
                  }
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFDC3545),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(24),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                        colors: [Color(0xFF17A2B8), Color(0xFF20B2AA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF17A2B8).withOpacity(0.3),
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
                            Icons.business,
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
                                'Vendors',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your supplier relationships and vendor information',
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
                              onPressed: addNewVendor,
                              icon: Icon(Icons.add, size: 16),
                              label: Text('Add Vendor'),
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
                                    hintText: 'Search vendors...',
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
                                        color: Color(0xFF17A2B8),
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF17A2B8),
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
                                Icons.business,
                                color: Color(0xFF17A2B8),
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Vendors List',
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
                                      Icons.business_center,
                                      color: Color(0xFF1976D2),
                                      size: 12,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      '${_filteredVendors.length} Vendors',
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
                        SingleChildScrollView(
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
                                    return Color(0xFF17A2B8).withOpacity(0.1);
                                  }
                                  return Colors.white;
                                }),
                            columns: const [
                              DataColumn(label: Text('Image')),
                              DataColumn(label: Text('Vendor Code')),
                              DataColumn(label: Text('Vendor Name')),
                              DataColumn(label: Text('Address')),
                              DataColumn(label: Text('CNIC')),
                              DataColumn(label: Text('City')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _filteredVendors.map((vendor) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _getVendorColor(
                                          vendor.city.title,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Color(0xFFDEE2E6),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.business,
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
                                        vendor.vendorCode,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF17A2B8),
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
                                            vendor.fullName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF343A40),
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            vendor.vendorCode,
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
                                    SizedBox(
                                      width: 160,
                                      child: Text(
                                        vendor.address ?? 'N/A',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
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
                                        vendor.cnic,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1976D2),
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
                                        color: Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        vendor.city.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1976D2),
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
                                        color: vendor.status == 'Active'
                                            ? Color(0xFFD4EDDA)
                                            : Color(0xFFF8D7DA),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            vendor.status == 'Active'
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: vendor.status == 'Active'
                                                ? Color(0xFF28A745)
                                                : Color(0xFFDC3545),
                                            size: 10,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            vendor.status,
                                            style: TextStyle(
                                              color: vendor.status == 'Active'
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
                                          onPressed: () => viewVendor(vendor),
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
                                          onPressed: () => editVendor(vendor),
                                          icon: Icon(
                                            Icons.edit,
                                            color: Color(0xFF28A745),
                                            size: 16,
                                          ),
                                          tooltip: 'Edit Vendor',
                                          padding: EdgeInsets.all(4),
                                          constraints: BoxConstraints(),
                                        ),
                                        SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () => deleteVendor(vendor),
                                          icon: Icon(
                                            Icons.delete,
                                            color: Color(0xFFDC3545),
                                            size: 16,
                                          ),
                                          tooltip: 'Delete Vendor',
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
                          label: Text(
                            'Previous',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: currentPage > 1
                                ? Color(0xFF17A2B8)
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
                              (vendorResponse?.meta != null &&
                                  currentPage < vendorResponse!.meta.lastPage)
                              ? () => _changePage(currentPage + 1)
                              : null,
                          icon: Icon(Icons.chevron_right, size: 14),
                          label: Text('Next', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (vendorResponse?.meta != null &&
                                    currentPage < vendorResponse!.meta.lastPage)
                                ? Color(0xFF17A2B8)
                                : Colors.grey.shade300,
                            foregroundColor:
                                (vendorResponse?.meta != null &&
                                    currentPage < vendorResponse!.meta.lastPage)
                                ? Colors.white
                                : Colors.grey.shade600,
                            elevation:
                                (vendorResponse?.meta != null &&
                                    currentPage < vendorResponse!.meta.lastPage)
                                ? 2
                                : 0,
                            side:
                                (vendorResponse?.meta != null &&
                                    currentPage < vendorResponse!.meta.lastPage)
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
                        if (vendorResponse != null) ...[
                          const SizedBox(width: 16),
                          Builder(
                            builder: (context) {
                              final meta = vendorResponse!.meta;
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
          ),

          // Loading overlay for delete operation
          if (_isDeletingVendor)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF17A2B8),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Deleting vendor...',
                        style: TextStyle(
                          color: Color(0xFF343A40),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    if (vendorResponse?.meta == null) {
      return [];
    }

    final meta = vendorResponse!.meta;
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
              backgroundColor: i == current ? Color(0xFF17A2B8) : Colors.white,
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

  Color _getVendorColor(String city) {
    // Use city name for color mapping instead of hardcoded countries
    final cityHash = city.toLowerCase().hashCode;
    final colors = [
      Color(0xFF17A2B8),
      Color(0xFF28A745),
      Color(0xFFDC3545),
      Color(0xFF6F42C1),
      Color(0xFFFFA500),
      Color(0xFF20B2AA),
      Color(0xFF8A2BE2),
      Color(0xFF32CD32),
      Color(0xFFFF6347),
      Color(0xFF4169E1),
    ];
    return colors[cityHash % colors.length];
  }
}

class EditVendorDialog extends StatefulWidget {
  final vendor.Vendor vendorData;
  final VoidCallback onVendorUpdated;

  const EditVendorDialog({
    super.key,
    required this.vendorData,
    required this.onVendorUpdated,
  });

  @override
  State<EditVendorDialog> createState() => _EditVendorDialogState();
}

class _EditVendorDialogState extends State<EditVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedStatus = 'Active';
  int _selectedCityId = 1; // Default city ID
  bool _isLoading = false;
  Map<String, String> _fieldErrors = {}; // Store field-specific errors

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing vendor data
    _firstNameController.text = widget.vendorData.firstName;
    _lastNameController.text = widget.vendorData.lastName;
    _cnicController.text = widget.vendorData.cnic;
    _emailController.text = ''; // Email not available in current model
    _phoneController.text = ''; // Phone not available in current model
    _addressController.text = widget.vendorData.address ?? '';
    _selectedStatus = widget.vendorData.status;
    _selectedCityId = int.tryParse(widget.vendorData.cityId) ?? 1;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _fieldErrors.clear(); // Clear previous field errors
    });

    try {
      final vendorData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'city_id': _selectedCityId,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'status': _selectedStatus,
      };

      // Remove null values
      vendorData.removeWhere((key, value) => value == null);

      await InventoryService.updateVendor(widget.vendorData.id, vendorData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor updated successfully!'),
            backgroundColor: Color(0xFF28A745),
            duration: Duration(seconds: 2),
          ),
        );
        widget.onVendorUpdated();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update vendor';
        bool hasFieldErrors = false;

        // Try to parse validation errors from the API response
        if (e.toString().contains('Inventory API failed')) {
          try {
            // Extract the response body from the error message
            final errorParts = e.toString().split(' - ');
            if (errorParts.length >= 2) {
              final responseBody = errorParts[1];
              final errorData = jsonDecode(responseBody);

              if (errorData is Map<String, dynamic>) {
                // Check for Laravel validation errors
                if (errorData.containsKey('errors') &&
                    errorData['errors'] is Map) {
                  final errors = errorData['errors'] as Map<String, dynamic>;
                  setState(() {
                    _fieldErrors.clear();
                    errors.forEach((field, messages) {
                      if (messages is List && messages.isNotEmpty) {
                        // Map API field names to form field names
                        String formField = field;
                        if (field == 'city_id') formField = 'city';
                        _fieldErrors[formField] = messages.first.toString();
                      }
                    });
                  });
                  hasFieldErrors = true;

                  // Clear CNIC field if there's a CNIC validation error
                  if (_fieldErrors.containsKey('cnic')) {
                    _cnicController.clear();
                  }

                  // Re-validate form to show field errors
                  _formKey.currentState!.validate();
                } else if (errorData.containsKey('message')) {
                  errorMessage = errorData['message'].toString();
                }
              }
            }
          } catch (parseError) {
            // If parsing fails, use the original error
            errorMessage = e.toString();
          }
        } else {
          errorMessage = e.toString();
        }

        // Only show snackbar if there are no field-specific errors
        if (!hasFieldErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Color(0xFFDC3545),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF28A745).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: Color(0xFF28A745), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edit Vendor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF343A40),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Color(0xFF6C757D), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Name and Last Name Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'First Name *',
                              hintText: 'Enter first name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('first_name')) {
                                setState(() {
                                  _fieldErrors.remove('first_name');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('first_name')) {
                                return _fieldErrors['first_name'];
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Last Name *',
                              hintText: 'Enter last name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('last_name')) {
                                setState(() {
                                  _fieldErrors.remove('last_name');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('last_name')) {
                                return _fieldErrors['last_name'];
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CNIC and Email Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cnicController,
                            decoration: InputDecoration(
                              labelText: 'CNIC *',
                              hintText: '12345-1234567-1',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('cnic')) {
                                setState(() {
                                  _fieldErrors.remove('cnic');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('cnic')) {
                                return _fieldErrors['cnic'];
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'CNIC is required';
                              }
                              // Basic CNIC format validation
                              final cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
                              if (!cnicRegex.hasMatch(value.trim())) {
                                return 'Invalid CNIC format';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'vendor@example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('email')) {
                                setState(() {
                                  _fieldErrors.remove('email');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('email')) {
                                return _fieldErrors['email'];
                              }
                              if (value != null && value.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Invalid email format';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone and Status Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              hintText: '+923001234567',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('phone')) {
                                setState(() {
                                  _fieldErrors.remove('phone');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('phone')) {
                                return _fieldErrors['phone'];
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
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
                            items: ['Active', 'Inactive'].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStatus = value;
                                  if (_fieldErrors.containsKey('status')) {
                                    _fieldErrors.remove('status');
                                  }
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('status')) {
                                return _fieldErrors['status'];
                              }
                              if (value == null || value.isEmpty) {
                                return 'Status is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter vendor address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        if (_fieldErrors.containsKey('address')) {
                          setState(() {
                            _fieldErrors.remove('address');
                          });
                        }
                      },
                      validator: (value) {
                        if (_fieldErrors.containsKey('address')) {
                          return _fieldErrors['address'];
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF28A745),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text('Update Vendor'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddVendorDialog extends StatefulWidget {
  final VoidCallback onVendorAdded;

  const AddVendorDialog({super.key, required this.onVendorAdded});

  @override
  State<AddVendorDialog> createState() => _AddVendorDialogState();
}

class _AddVendorDialogState extends State<AddVendorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedStatus = 'Active';
  int _selectedCityId = 1; // Default city ID
  bool _isLoading = false;
  Map<String, String> _fieldErrors = {}; // Store field-specific errors

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cnicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _fieldErrors.clear(); // Clear previous field errors
    });

    try {
      final vendorData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'city_id': _selectedCityId,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'status': _selectedStatus,
      };

      // Remove null values
      vendorData.removeWhere((key, value) => value == null);

      await InventoryService.createVendor(vendorData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor added successfully!'),
            backgroundColor: Color(0xFF28A745),
            duration: Duration(seconds: 2),
          ),
        );
        widget.onVendorAdded();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to add vendor';
        bool hasFieldErrors = false;

        // Try to parse validation errors from the API response
        if (e.toString().contains('Inventory API failed')) {
          try {
            // Extract the response body from the error message
            final errorParts = e.toString().split(' - ');
            if (errorParts.length >= 2) {
              final responseBody = errorParts[1];
              final errorData = jsonDecode(responseBody);

              if (errorData is Map<String, dynamic>) {
                // Check for Laravel validation errors
                if (errorData.containsKey('errors') &&
                    errorData['errors'] is Map) {
                  final errors = errorData['errors'] as Map<String, dynamic>;
                  setState(() {
                    _fieldErrors.clear();
                    errors.forEach((field, messages) {
                      if (messages is List && messages.isNotEmpty) {
                        // Map API field names to form field names
                        String formField = field;
                        if (field == 'city_id') formField = 'city';
                        _fieldErrors[formField] = messages.first.toString();
                      }
                    });
                  });
                  hasFieldErrors = true;

                  // Clear CNIC field if there's a CNIC validation error
                  if (_fieldErrors.containsKey('cnic')) {
                    _cnicController.clear();
                  }

                  // Re-validate form to show field errors
                  _formKey.currentState!.validate();
                } else if (errorData.containsKey('message')) {
                  errorMessage = errorData['message'].toString();
                }
              }
            }
          } catch (parseError) {
            // If parsing fails, use the original error
            errorMessage = e.toString();
          }
        } else {
          errorMessage = e.toString();
        }

        // Only show snackbar if there are no field-specific errors
        if (!hasFieldErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Color(0xFFDC3545),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF17A2B8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business,
                    color: Color(0xFF17A2B8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add New Vendor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF343A40),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Color(0xFF6C757D), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Name and Last Name Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'First Name *',
                              hintText: 'Enter first name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('first_name')) {
                                setState(() {
                                  _fieldErrors.remove('first_name');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('first_name')) {
                                return _fieldErrors['first_name'];
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Last Name *',
                              hintText: 'Enter last name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('last_name')) {
                                setState(() {
                                  _fieldErrors.remove('last_name');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('last_name')) {
                                return _fieldErrors['last_name'];
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CNIC and Email Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cnicController,
                            decoration: InputDecoration(
                              labelText: 'CNIC *',
                              hintText: '12345-1234567-1',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('cnic')) {
                                setState(() {
                                  _fieldErrors.remove('cnic');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('cnic')) {
                                return _fieldErrors['cnic'];
                              }
                              if (value == null || value.trim().isEmpty) {
                                return 'CNIC is required';
                              }
                              // Basic CNIC format validation
                              final cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
                              if (!cnicRegex.hasMatch(value.trim())) {
                                return 'Invalid CNIC format';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'vendor@example.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('email')) {
                                setState(() {
                                  _fieldErrors.remove('email');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('email')) {
                                return _fieldErrors['email'];
                              }
                              if (value != null && value.trim().isNotEmpty) {
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Invalid email format';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone and Status Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              hintText: '+923001234567',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              if (_fieldErrors.containsKey('phone')) {
                                setState(() {
                                  _fieldErrors.remove('phone');
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('phone')) {
                                return _fieldErrors['phone'];
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
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
                            items: ['Active', 'Inactive'].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStatus = value;
                                  if (_fieldErrors.containsKey('status')) {
                                    _fieldErrors.remove('status');
                                  }
                                });
                              }
                            },
                            validator: (value) {
                              if (_fieldErrors.containsKey('status')) {
                                return _fieldErrors['status'];
                              }
                              if (value == null || value.isEmpty) {
                                return 'Status is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter vendor address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        if (_fieldErrors.containsKey('address')) {
                          setState(() {
                            _fieldErrors.remove('address');
                          });
                        }
                      },
                      validator: (value) {
                        if (_fieldErrors.containsKey('address')) {
                          return _fieldErrors['address'];
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF17A2B8),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text('Add Vendor'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

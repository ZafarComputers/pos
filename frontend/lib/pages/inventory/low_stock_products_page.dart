import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../../services/inventory_service.dart';
import '../../models/product.dart';

class LowStockProductsPage extends StatefulWidget {
  const LowStockProductsPage({super.key});

  @override
  State<LowStockProductsPage> createState() => _LowStockProductsPageState();
}

class _LowStockProductsPageState extends State<LowStockProductsPage> {
  List<Product> lowStockProducts = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int totalProducts = 0;
  int totalPages = 1;
  final int itemsPerPage = 10;

  String selectedProduct = 'All';
  String selectedSortBy = 'Lowest Stock First';

  // Computed property for filtered and sorted products
  List<Product> get filteredAndSortedProducts {
    List<Product> filtered = lowStockProducts;

    // Apply product filter
    if (selectedProduct != 'All') {
      filtered = filtered
          .where((product) => product.title == selectedProduct)
          .toList();
    }

    // Apply sorting based on selectedSortBy
    switch (selectedSortBy) {
      case 'Lowest Stock First':
        filtered.sort((a, b) {
          int stockA = int.tryParse(a.openingStockQuantity) ?? 0;
          int stockB = int.tryParse(b.openingStockQuantity) ?? 0;
          return stockA.compareTo(stockB);
        });
        break;
      case 'Highest Stock First':
        filtered.sort((a, b) {
          int stockA = int.tryParse(a.openingStockQuantity) ?? 0;
          int stockB = int.tryParse(b.openingStockQuantity) ?? 0;
          return stockB.compareTo(stockA);
        });
        break;
      case 'Product Name A-Z':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Product Name Z-A':
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'Highest Price First':
        filtered.sort((a, b) {
          double priceA = double.tryParse(a.salePrice) ?? 0;
          double priceB = double.tryParse(b.salePrice) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Lowest Price First':
        filtered.sort((a, b) {
          double priceA = double.tryParse(a.salePrice) ?? 0;
          double priceB = double.tryParse(b.salePrice) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      default:
        // Default to lowest stock first
        filtered.sort((a, b) {
          int stockA = int.tryParse(a.openingStockQuantity) ?? 0;
          int stockB = int.tryParse(b.openingStockQuantity) ?? 0;
          return stockA.compareTo(stockB);
        });
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _fetchLowStockProducts();
  }

  Future<void> _fetchLowStockProducts({int page = 1}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await InventoryService.getLowStockProducts(
        page: page,
        limit: itemsPerPage,
      );

      final products = (response['data'] as List)
          .map((item) => Product.fromJson(item))
          .toList();

      setState(() {
        lowStockProducts = products;
        currentPage = page;
        totalProducts = response['total'] ?? products.length;
        totalPages = (totalProducts / itemsPerPage).ceil();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
                SizedBox(width: 16),
                Text('Fetching all low stock products...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL low stock products from database for export
      List<Product> allLowStockProductsForExport = [];

      try {
        // Fetch ALL low stock products with unlimited pagination
        int currentPage = 1;
        bool hasMorePages = true;

        while (hasMorePages) {
          final pageResponse = await InventoryService.getLowStockProducts(
            page: currentPage,
            limit: 100, // Fetch in chunks of 100
          );

          final products = (pageResponse['data'] as List)
              .map((item) => Product.fromJson(item))
              .toList();

          allLowStockProductsForExport.addAll(products);

          // Check if there are more pages
          final totalItems = pageResponse['total'] ?? 0;
          final fetchedSoFar = allLowStockProductsForExport.length;

          if (fetchedSoFar >= totalItems) {
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
                        Color(0xFFFF6B35),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Fetched ${allLowStockProductsForExport.length} low stock products...',
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Apply filters if any are active (Note: Low stock products page doesn't have search/status filters like products page)
        // Add any filtering logic here if needed in the future
      } catch (e) {
        print('Error fetching all low stock products: $e');
        // Fallback to current data
        allLowStockProductsForExport = lowStockProducts.isNotEmpty
            ? lowStockProducts
            : [];
      }

      if (allLowStockProductsForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No low stock products to export'),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
                SizedBox(width: 16),
                Text(
                  'Generating PDF with ${allLowStockProductsForExport.length} low stock products...',
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
        255,
        107,
        53,
      ); // Low stock theme color
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

      // Balanced column widths for low stock products
      grid.columns[0].width = tableWidth * 0.15; // 15% - Product Code
      grid.columns[1].width = tableWidth * 0.25; // 25% - Product Name
      grid.columns[2].width = tableWidth * 0.15; // 15% - Stock Quantity
      grid.columns[3].width = tableWidth * 0.15; // 15% - Sale Price
      grid.columns[4].width = tableWidth * 0.15; // 15% - Vendor
      grid.columns[5].width = tableWidth * 0.15; // 15% - Status

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
      headerRow.cells[2].value = 'Stock Quantity';
      headerRow.cells[3].value = 'Sale Price';
      headerRow.cells[4].value = 'Vendor';
      headerRow.cells[5].value = 'Status';

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

      // Add all low stock product data rows
      for (var product in allLowStockProductsForExport) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = product.designCode;
        row.cells[1].value = product.title;
        row.cells[2].value = product.openingStockQuantity;
        row.cells[3].value = 'PKR ${product.salePrice}';
        row.cells[4].value = product.vendor.name ?? 'N/A';
        row.cells[5].value = product.status;

        // Style data cells with better text wrapping
        for (int i = 0; i < row.cells.count; i++) {
          row.cells[i].style = PdfGridCellStyle(
            font: smallFont,
            textBrush: PdfSolidBrush(PdfColor(33, 37, 41)),
            format: PdfStringFormat(
              alignment: i == 2 || i == 3 || i == 5
                  ? PdfTextAlignment.center
                  : PdfTextAlignment.left,
              lineAlignment: PdfVerticalAlignment.top,
              wordWrap: PdfWordWrapType.word,
            ),
          );
        }

        // Color code status
        if (product.status == 'Active') {
          row.cells[5].style.backgroundBrush = PdfSolidBrush(
            PdfColor(212, 237, 218),
          );
          row.cells[5].style.textBrush = PdfSolidBrush(PdfColor(21, 87, 36));
        } else {
          row.cells[5].style.backgroundBrush = PdfSolidBrush(
            PdfColor(248, 215, 218),
          );
          row.cells[5].style.textBrush = PdfSolidBrush(PdfColor(114, 28, 36));
        }
      }

      // Set up page template for headers and footers
      final PdfPageTemplateElement headerTemplate = PdfPageTemplateElement(
        Rect.fromLTWH(0, 0, document.pageSettings.size.width, 50),
      );

      // Draw header on template - minimal left margin, full width
      headerTemplate.graphics.drawString(
        'Low Stock Products Database Export',
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
        'Total Low Stock Products: ${allLowStockProductsForExport.length} | Generated: ${DateTime.now().toString().substring(0, 19)} | Low Stock Alert Report',
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
        'Page \$PAGE of \$TOTAL | ${allLowStockProductsForExport.length} Total Low Stock Products | Generated from POS System',
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
        'PDF generated with $pageCount page(s) for ${allLowStockProductsForExport.length} low stock products',
      );

      // Save PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Close loading dialog
      Navigator.of(context).pop();

      // Let user choose save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Low Stock Products Database PDF',
        fileName:
            'low_stock_products_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
                '✅ Low Stock Products Exported!\n📊 ${allLowStockProductsForExport.length} products across $pageCount pages\n📄 Landscape format for better visibility',
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
                SizedBox(width: 16),
                Text('Fetching all low stock products...'),
              ],
            ),
          );
        },
      );

      // Always fetch ALL low stock products from database for export
      List<Product> allLowStockProductsForExport = [];

      try {
        // Fetch ALL low stock products with unlimited pagination
        int currentPage = 1;
        bool hasMorePages = true;

        while (hasMorePages) {
          final pageResponse = await InventoryService.getLowStockProducts(
            page: currentPage,
            limit: 100, // Fetch in chunks of 100
          );

          final products = (pageResponse['data'] as List)
              .map((item) => Product.fromJson(item))
              .toList();

          allLowStockProductsForExport.addAll(products);

          // Check if there are more pages
          final totalItems = pageResponse['total'] ?? 0;
          final fetchedSoFar = allLowStockProductsForExport.length;

          if (fetchedSoFar >= totalItems) {
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
                        Color(0xFFFF6B35),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Fetched ${allLowStockProductsForExport.length} low stock products...',
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Apply filters if any are active (Note: Low stock products page doesn't have search/status filters like products page)
        // Add any filtering logic here if needed in the future
      } catch (e) {
        print('Error fetching all low stock products: $e');
        // Fallback to current data
        allLowStockProductsForExport = lowStockProducts.isNotEmpty
            ? lowStockProducts
            : [];
      }

      if (allLowStockProductsForExport.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No low stock products to export'),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
                SizedBox(width: 16),
                Text(
                  'Generating Excel with ${allLowStockProductsForExport.length} low stock products...',
                ),
              ],
            ),
          );
        },
      );

      // Create a new Excel document
      final excel_pkg.Excel excel = excel_pkg.Excel.createExcel();
      final excel_pkg.Sheet sheet = excel['Low Stock Products'];

      // Add header row with styling
      sheet.appendRow([
        excel_pkg.TextCellValue('Product Code'),
        excel_pkg.TextCellValue('Product Name'),
        excel_pkg.TextCellValue('Stock Quantity'),
        excel_pkg.TextCellValue('Sale Price'),
        excel_pkg.TextCellValue('Vendor'),
        excel_pkg.TextCellValue('Status'),
      ]);

      // Style header row
      final headerStyle = excel_pkg.CellStyle(bold: true, fontSize: 12);

      for (int i = 0; i < 6; i++) {
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

      // Add all low stock product data rows
      for (var product in allLowStockProductsForExport) {
        sheet.appendRow([
          excel_pkg.TextCellValue(product.designCode),
          excel_pkg.TextCellValue(product.title),
          excel_pkg.TextCellValue(product.openingStockQuantity),
          excel_pkg.TextCellValue('PKR ${product.salePrice}'),
          excel_pkg.TextCellValue(product.vendor.name ?? 'N/A'),
          excel_pkg.TextCellValue(product.status),
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
        dialogTitle: 'Save Low Stock Products Database Excel',
        fileName:
            'low_stock_products_${DateTime.now().millisecondsSinceEpoch}.xlsx',
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
                '✅ Low Stock Products Exported!\n📊 ${allLowStockProductsForExport.length} products exported to Excel\n📈 Ready for inventory analysis',
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
                  colors: [Color(0xFFFF6B35), Color(0xFFE55A2B)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF6B35).withOpacity(0.3),
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
                      Icons.warning_amber,
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
                          'Low Stock Products',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor and manage products that are running low on stock',
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
                            foregroundColor: Color(0xFFFF6B35),
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
                      Icon(Icons.filter_list, color: Color(0xFF6C757D)),
                      SizedBox(width: 8),
                      Text(
                        'Filters & Sorting',
                        style: TextStyle(
                          fontSize: 18,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Product',
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
                                value: selectedProduct,
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
                                      color: Color(0xFFFF6B35),
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
                                    [
                                          'All',
                                          ...lowStockProducts
                                              .map((product) => product.title)
                                              .toSet(),
                                        ]
                                        .map(
                                          (product) => DropdownMenuItem(
                                            value: product,
                                            child: Text(
                                              product,
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
                                      selectedProduct = value;
                                    });
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
                                  Icons.sort,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Sort By',
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
                                value: selectedSortBy,
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
                                      color: Color(0xFFFF6B35),
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
                                    [
                                          'Lowest Stock First',
                                          'Highest Stock First',
                                          'Product Name A-Z',
                                          'Product Name Z-A',
                                          'Highest Price First',
                                          'Lowest Price First',
                                        ]
                                        .map(
                                          (sort) => DropdownMenuItem(
                                            value: sort,
                                            child: Text(
                                              sort,
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
                                      selectedSortBy = value;
                                    });
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

            // Error State
            if (errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Color(0xFFDC3545),
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error loading low stock products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF343A40),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          _fetchLowStockProducts(page: currentPage),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            else
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
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Color(0xFFFF6B35),
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Low Stock Products List',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF343A40),
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: Color(0xFF856404),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${filteredAndSortedProducts.length} Low Stock',
                                  style: TextStyle(
                                    color: Color(0xFF856404),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
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
                        dataRowColor: MaterialStateProperty.resolveWith<Color>((
                          Set<MaterialState> states,
                        ) {
                          if (states.contains(MaterialState.selected)) {
                            return Color(0xFFFF6B35).withOpacity(0.1);
                          }
                          return Colors.white;
                        }),
                        columns: const [
                          DataColumn(label: Text('Product Code')),
                          DataColumn(label: Text('Product Name')),
                          DataColumn(label: Text('Stock Quantity')),
                          DataColumn(label: Text('Sale Price')),
                          DataColumn(label: Text('Vendor')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: filteredAndSortedProducts.map((product) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.designCode,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF6B35),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 160,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFFF3CD),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Color(0xFFFFEAA7),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.inventory_2,
                                          color: Color(0xFF856404),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
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
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              product.designCode,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6C757D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFF3CD),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.openingStockQuantity,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF856404),
                                      fontSize: 12,
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
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  product.vendor.name ?? 'N/A',
                                  style: TextStyle(
                                    color: Color(0xFF6C757D),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF8D7DA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Color(0xFFFF6B35),
                                        size: 12,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Low Stock',
                                        style: TextStyle(
                                          color: Color(0xFFFF6B35),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
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
            if (errorMessage == null) const SizedBox(height: 24),
            if (errorMessage == null)
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: currentPage > 1
                          ? () => _fetchLowStockProducts(page: currentPage - 1)
                          : null,
                      icon: Icon(Icons.chevron_left, size: 16),
                      label: Text('Previous', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF6C757D),
                        elevation: 0,
                        side: BorderSide(color: Color(0xFFDEE2E6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    for (int i = 1; i <= totalPages; i++)
                      if (i == 1 ||
                          i == totalPages ||
                          (i >= currentPage - 1 && i <= currentPage + 1))
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          child: ElevatedButton(
                            onPressed: () => _fetchLowStockProducts(page: i),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: i == currentPage
                                  ? Color(0xFFFF6B35)
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size(36, 36),
                            ),
                            child: Text(
                              i.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      else if (i == currentPage - 2 || i == currentPage + 2)
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            '...',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: currentPage < totalPages
                          ? () => _fetchLowStockProducts(page: currentPage + 1)
                          : null,
                      icon: Icon(Icons.chevron_right, size: 16),
                      label: Text('Next', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF6C757D),
                        elevation: 0,
                        side: BorderSide(color: Color(0xFFDEE2E6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
}

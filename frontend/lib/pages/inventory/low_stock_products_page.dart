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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Products'),
        backgroundColor: const Color(0xFF0D1845),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
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
                          Icons.warning_amber,
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
                              'Low Stock Products',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Monitor and manage products that are running low on stock',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Summary Cards
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Total Low Stock',
                        lowStockProducts.length.toString(),
                        Icons.warning_amber,
                        Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Critical Stock',
                        lowStockProducts
                            .where(
                              (p) =>
                                  (int.tryParse(p.openingStockQuantity) ?? 0) <=
                                  5,
                            )
                            .length
                            .toString(),
                        Icons.error,
                        Colors.red,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Low Stock',
                        lowStockProducts
                            .where(
                              (p) =>
                                  (int.tryParse(p.openingStockQuantity) ?? 0) >
                                  5,
                            )
                            .length
                            .toString(),
                        Icons.warning,
                        Colors.yellow,
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
                                  decoration: InputDecoration(
                                    hintText: 'Search low stock products...',
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
                                  value: selectedProduct,
                                  underline: const SizedBox(),
                                  items:
                                      [
                                            'All',
                                            ...lowStockProducts
                                                .map((product) => product.title)
                                                .toSet(),
                                          ]
                                          .map(
                                            (product) =>
                                                DropdownMenuItem<String>(
                                                  value: product,
                                                  child: Text(product),
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
                                  value: selectedSortBy,
                                  underline: const SizedBox(),
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
                                            (sort) => DropdownMenuItem<String>(
                                              value: sort,
                                              child: Text(sort),
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
                                    onPressed: () => _fetchLowStockProducts(
                                      page: currentPage,
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : filteredAndSortedProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.warning_amber_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No low stock products found',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredAndSortedProducts.length,
                              itemBuilder: (context, index) {
                                final product =
                                    filteredAndSortedProducts[index];
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
                                          child: const Icon(
                                            Icons.warning_amber,
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
                                            'PKR ${product.salePrice}',
                                            style: _cellStyle(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Stock Column - Centered
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF3CD),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              product.openingStockQuantity,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF856404),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
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
            if (filteredAndSortedProducts.isNotEmpty) ...[
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
                          ? () => _fetchLowStockProducts(page: currentPage - 1)
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
                        'Page $currentPage of $totalPages (${lowStockProducts.length} total)',
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
                          ? () => _fetchLowStockProducts(page: currentPage + 1)
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
}

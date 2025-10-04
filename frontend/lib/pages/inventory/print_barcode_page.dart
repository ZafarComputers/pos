import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/inventory_service.dart';
import '../../models/product.dart';

class PrintBarcodePage extends StatefulWidget {
  const PrintBarcodePage({super.key});

  @override
  State<PrintBarcodePage> createState() => _PrintBarcodePageState();
}

class _PrintBarcodePageState extends State<PrintBarcodePage> {
  ProductResponse? productResponse;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  final int itemsPerPage = 10; // Load 10 products per page for better performance

  String selectedCategory = 'All';
  String selectedVendor = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Selection state
  Set<int> selectedProductIds = {};
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts({int page = 1}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
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
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void toggleSelectAll() {
    if (productResponse == null) return;

    setState(() {
      if (selectAll) {
        selectedProductIds.clear();
        selectAll = false;
      } else {
        selectedProductIds = productResponse!.data.map((product) => product.id).toSet();
        selectAll = true;
      }
    });
  }

  void toggleProductSelection(int productId) {
    setState(() {
      if (selectedProductIds.contains(productId)) {
        selectedProductIds.remove(productId);
      } else {
        selectedProductIds.add(productId);
      }
      selectAll = selectedProductIds.length == productResponse?.data.length;
    });
  }

  List<Product> getSelectedProducts() {
    if (productResponse == null) return [];
    return productResponse!.data.where((product) => selectedProductIds.contains(product.id)).toList();
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
    final isAllProductsSelected = selectAll || selectedProductIds.length == productResponse?.data.length;

    // Show barcode generation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isAllProductsSelected ? 'Generate Single Barcode (All Products)' : 'Generate Barcodes'),
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
                          'All Products Barcode',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        QrImageView(
                          data: _generateAllProductsBarcodeData(selectedProducts),
                          version: QrVersions.auto,
                          size: 120.0,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contains all ${selectedProducts.length} products',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      const Text(
                        'Individual barcodes will be generated for each selected product.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selected products: ${selectedProducts.map((p) => p.designCode).join(", ")}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
                backgroundColor: Color(0xFF17A2B8),
              ),
              child: Text(isAllProductsSelected ? 'Generate Single Barcode' : 'Generate & Print'),
            ),
          ],
        );
      },
    );
  }

  String _generateAllProductsBarcodeData(List<Product> products) {
    // Create a structured data format for all products
    final productData = products.map((product) => {
      'id': product.id.toString(),
      'code': product.designCode,
      'name': product.title,
      'price': product.salePrice,
      'category': product.subCategoryId,
      'vendor': product.vendor.name ?? 'Vendor ${product.vendorId}',
      'quantity': product.openingStockQuantity,
    }).toList();

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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        QrImageView(
                          data: selectedProducts[0].barcode,
                          version: QrVersions.auto,
                          size: 120.0,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code: ${selectedProducts[0].designCode}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'QR code generation feature coming soon!',
                  style: TextStyle(color: Colors.grey),
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
                backgroundColor: Color(0xFF17A2B8),
              ),
              child: const Text('Generate'),
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
                  colors: [Color(0xFF17A2B8), Color(0xFF20B2AA)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF17A2B8).withValues(alpha: 0.3),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
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
                          'Print Barcode',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate barcodes and QR codes for your products',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: generateAndPrintBarcode,
                    icon: Icon(Icons.qr_code_scanner, size: 16),
                    label: Text('Generate & Print Barcode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF0D1845),
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
                    color: Colors.black.withValues(alpha: 0.08),
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
                                color: Colors.black.withValues(alpha: 0.05),
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
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedCategory,
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
                                  Icons.business,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Vendor',
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
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedVendor,
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
                                          (brand) => DropdownMenuItem(
                                            value: brand,
                                            child: Text(
                                              brand,
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
                                      selectedVendor = value;
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

            // Selection Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: selectAll,
                    onChanged: (value) => toggleSelectAll(),
                    activeColor: Color(0xFF17A2B8),
                  ),
                  Text(
                    'Select All',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF343A40),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                          Icons.check_circle,
                          color: Color(0xFF1976D2),
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${getSelectedProducts().length} product(s) selected',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
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
            const SizedBox(height: 24),

            // Enhanced Products Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                          Icons.table_chart,
                          color: Color(0xFF17A2B8),
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
                                Icons.inventory_2,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${productResponse?.meta.total ?? 0} Products',
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
                    child: isLoading
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF17A2B8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading products...',
                                    style: TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : errorMessage != null
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
                                    'Failed to load products',
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
                                    onPressed: _fetchProducts,
                                    child: Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF17A2B8),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : productResponse == null || productResponse!.data.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: Color(0xFF6C757D),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create your first product to get started',
                                    style: TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Color(0xFFF8F9FA),
                            ),
                            dataRowColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Color(0xFF17A2B8).withValues(alpha: 0.1);
                              }
                              return Colors.white;
                            }),
                            columns: const [
                              DataColumn(label: Text('Select')),
                              DataColumn(label: Text('Product Code')),
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Vendor')),
                              DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Unit')),
                              DataColumn(label: Text('Qty')),
                            ],
                            rows: productResponse!.data.map((product) {
                              final quantity = int.tryParse(product.openingStockQuantity) ?? 0;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: selectedProductIds.contains(product.id),
                                      onChanged: (value) => toggleProductSelection(product.id),
                                      activeColor: Color(0xFF17A2B8),
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
                                          color: Color(0xFF17A2B8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF8F9FA),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Color(0xFFDEE2E6),
                                              ),
                                            ),
                                            child: product.imagePath != null && product.imagePath!.isNotEmpty
                                                ? (product.imagePath!.startsWith('http') && !product.imagePath!.contains('zafarcomputers.com'))
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: Image.network(
                                                          product.imagePath!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => Icon(
                                                            Icons.inventory_2,
                                                            color: Color(0xFF6C757D),
                                                            size: 16,
                                                          ),
                                                        ),
                                                      )
                                                    : FutureBuilder<Uint8List?>(
                                                        future: _loadProductImage(product.imagePath!),
                                                        builder: (context, snapshot) {
                                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                                            return Center(
                                                              child: SizedBox(
                                                                width: 16,
                                                                height: 16,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth: 2,
                                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF17A2B8)),
                                                                ),
                                                              ),
                                                            );
                                                          } else if (snapshot.hasData && snapshot.data != null) {
                                                            return ClipRRect(
                                                              borderRadius: BorderRadius.circular(4),
                                                              child: Image.memory(
                                                                snapshot.data!,
                                                                fit: BoxFit.cover,
                                                              ),
                                                            );
                                                          } else {
                                                            return Icon(
                                                              Icons.inventory_2,
                                                              color: Color(0xFF6C757D),
                                                              size: 16,
                                                            );
                                                          }
                                                        },
                                                      )
                                                : Icon(
                                                    Icons.inventory_2,
                                                    color: Color(0xFF6C757D),
                                                    size: 16,
                                                  ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
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
                                                  'Code: ${product.designCode}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF6C757D),
                                                    fontFamily: 'monospace',
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
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(product.subCategoryId),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'Category ${product.subCategoryId}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      product.vendor.name ?? 'Vendor ${product.vendorId}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF343A40),
                                        fontSize: 12,
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
                                        'Pc',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6C757D),
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
                                        color: quantity < 50
                                            ? Color(0xFFFFF3CD)
                                            : Color(0xFFD4EDDA),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        quantity.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: quantity < 50
                                              ? Color(0xFF856404)
                                              : Color(0xFF155724),
                                          fontSize: 11,
                                        ),
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

            const SizedBox(height: 24),

            // Generate QR Code Button at Bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: generateQRCode,
                  icon: Icon(Icons.qr_code, size: 18),
                  label: Text('Generate QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
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
}
import 'package:flutter/material.dart';
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
  String selectedSortBy = 'Last 7 Days';

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

  void exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Exporting low stock products to PDF... (Feature coming soon)',
            ),
          ],
        ),
        backgroundColor: Color(0xFFDC3545),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.file_download, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Exporting low stock products to Excel... (Feature coming soon)',
            ),
          ],
        ),
        backgroundColor: Color(0xFF28A745),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
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
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: exportToPDF,
                          icon: Icon(Icons.picture_as_pdf, size: 16),
                          label: Text('PDF'),
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
                          icon: Icon(Icons.file_download, size: 16),
                          label: Text('Excel'),
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
                                          'Last 7 Days',
                                          'Last 30 Days',
                                          'Last 3 Months',
                                          'Last 6 Months',
                                          'Last Year',
                                        ]
                                        .map(
                                          (sort) => DropdownMenuItem(
                                            value: sort,
                                            child: Text(
                                              'Sort By: $sort',
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

            // Loading and Error States
            if (isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                ),
              )
            else if (errorMessage != null)
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
                                  '$totalProducts Low Stock',
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
                        rows: lowStockProducts.map((product) {
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
            if (!isLoading && errorMessage == null) const SizedBox(height: 24),
            if (!isLoading && errorMessage == null)
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

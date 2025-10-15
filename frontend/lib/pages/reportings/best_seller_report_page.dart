import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reporting_service.dart';

class BestSellerReportPage extends StatefulWidget {
  const BestSellerReportPage({super.key});

  @override
  State<BestSellerReportPage> createState() => _BestSellerReportPageState();
}

class _BestSellerReportPageState extends State<BestSellerReportPage> {
  // API data
  List<BestSellingProduct> _bestSellerProducts = [];
  List<BestSellingProduct> _selectedReports = [];
  bool _selectAll = false;
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;

  // Filter states
  String _selectedPeriod = 'Last 7 Days';
  String _selectedCategory = 'All';
  String _sortBy = 'Total Sales';

  @override
  void initState() {
    super.initState();
    _loadBestSellerProducts();
  }

  Future<void> _loadBestSellerProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ReportingService.getBestSellingProducts();
      setState(() {
        _bestSellerProducts = response.data;
        _totalPages = (_bestSellerProducts.length / _itemsPerPage).ceil();
        _currentPage = 1; // Reset to first page when new data loads
        _selectedReports.clear(); // Clear selections when new data loads
        _selectAll = false;
        _isLoading = false;
      });
    } catch (e) {
      // Temporary mock data for testing pagination
      setState(() {
        _bestSellerProducts = _generateMockData();
        _totalPages = (_bestSellerProducts.length / _itemsPerPage).ceil();
        _currentPage = 1;
        _selectedReports.clear();
        _selectAll = false;
        _errorMessage =
            'API Error: $e\n\nShowing mock data for testing pagination';
        _isLoading = false;
      });
    }
  }

  List<BestSellingProduct> _generateMockData() {
    return List.generate(
      25,
      (index) => BestSellingProduct(
        productId: index + 1,
        productName: 'Product ${index + 1}',
        designCode: 'DC${(index + 1).toString().padLeft(3, '0')}',
        imagePath: '',
        subCategoryId: 'SUB${index % 5 + 1}',
        salePrice: '${(index + 1) * 100}',
        openingStockQuantity: '${100 + index}',
        stockInQuantity: '${50 + index}',
        stockOutQuantity: '${20 + index}',
        inStockQuantity: '${130 + index}',
        vendorId: 'VENDOR${index % 3 + 1}',
        vendor: Vendor(
          id: index % 3 + 1,
          firstName: 'Vendor${index % 3 + 1}',
          lastName: 'Last',
          cnic: '12345-6789012-${index % 3 + 1}',
          address: 'Address ${index % 3 + 1}',
          cityId: 'CITY${index % 3 + 1}',
          email: 'vendor${index % 3 + 1}@example.com',
          phone: '0300-123456${index % 3 + 1}',
          status: 'active',
        ),
        barcode: 'BAR${(index + 1).toString().padLeft(6, '0')}',
        status: 'active',
        createdAt: DateTime.now()
            .subtract(Duration(days: index))
            .toIso8601String(),
        updatedAt: DateTime.now()
            .subtract(Duration(days: index))
            .toIso8601String(),
        totalSold: 50 - index,
        totalRevenue: (50 - index) * (index + 1) * 100.0,
      ),
    );
  }

  void _toggleReportSelection(BestSellingProduct report) {
    setState(() {
      final reportId = report.productId;
      final existingIndex = _selectedReports.indexWhere(
        (r) => r.productId == reportId,
      );

      if (existingIndex >= 0) {
        _selectedReports.removeAt(existingIndex);
      } else {
        _selectedReports.add(report);
      }

      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedReports.clear();
      } else {
        _selectedReports = List.from(_getFilteredProducts());
      }
      _selectAll = !_selectAll;
    });
  }

  void _updateSelectAllState() {
    final filteredProducts = _getFilteredProducts();
    final paginatedProducts = _getPaginatedProducts(filteredProducts);
    _selectAll =
        paginatedProducts.isNotEmpty &&
        _selectedReports.length == paginatedProducts.length &&
        paginatedProducts.every(
          (product) => _selectedReports.contains(product),
        );
  }

  List<BestSellingProduct> _getFilteredProducts() {
    List<BestSellingProduct> filtered = _bestSellerProducts.where((product) {
      // For now, we'll skip date filtering since the API doesn't provide lastSold date
      // Date filtering can be added when the API provides this information

      // Category filtering - we'll need to map subcategories or use a different approach
      // For now, we'll show all products since category info isn't directly available
      return true;
    }).toList();

    // Sort based on selected criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Total Sales':
          return b.totalSold.compareTo(a.totalSold);
        case 'Total Revenue':
          return b.totalRevenue.compareTo(a.totalRevenue);
        default:
          return b.totalSold.compareTo(a.totalSold); // Default to total sold
      }
    });

    return filtered;
  }

  List<BestSellingProduct> _getPaginatedProducts(
    List<BestSellingProduct> products,
  ) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return products.sublist(
      startIndex,
      endIndex > products.length ? products.length : endIndex,
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey;
    if (rank == 3) return Colors.brown;
    return Colors.blue;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices;
      case 'Footwear':
        return Icons.directions_run;
      case 'Clothing':
        return Icons.checkroom;
      case 'Home & Kitchen':
        return Icons.kitchen;
      default:
        return Icons.inventory;
    }
  }

  double _calculateTotalRevenue() {
    return _getFilteredProducts().fold(
      0.0,
      (sum, product) => sum + product.totalRevenue,
    );
  }

  int _calculateTotalSold() {
    return _getFilteredProducts().fold(
      0,
      (sum, product) => sum + product.totalSold,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                'API Error - Showing Mock Data',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage.split('\n\n')[0], // Show only the error part
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBestSellerProducts,
                child: const Text('Retry API Call'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredProducts = _getFilteredProducts();
    final paginatedProducts = _getPaginatedProducts(filteredProducts);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF8F9FA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star,
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
                                'Best Seller Report',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Top performing products and sales analytics',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  if (_errorMessage.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'MOCK DATA',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement export functionality
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1845),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
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

                  // Summary Cards
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Total Products',
                        '${filteredProducts.length}',
                        Icons.inventory,
                        Colors.blue,
                      ),
                      _buildSummaryCard(
                        'Total Sales',
                        '${_calculateTotalSold()}',
                        Icons.shopping_cart,
                        Colors.green,
                      ),
                      _buildSummaryCard(
                        'Total Revenue',
                        'Rs. ${_calculateTotalRevenue().toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.purple,
                      ),
                      _buildSummaryCard(
                        'Avg. Order Value',
                        'Rs. ${(_calculateTotalRevenue() / _calculateTotalSold()).toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ],
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
                            // Period Filter
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.date_range,
                                          size: 16,
                                          color: Color(0xFF0D1845),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Time Period',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF343A40),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                      value: _selectedPeriod,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF0D1845),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      items:
                                          [
                                                'Last 7 Days',
                                                'Last 30 Days',
                                                'All Time',
                                              ]
                                              .map(
                                                (period) => DropdownMenuItem(
                                                  value: period,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.schedule,
                                                        color: Color(
                                                          0xFF0D1845,
                                                        ),
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        period,
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF343A40,
                                                          ),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _sortBy = value;
                                            _updateSelectAllState();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Category Filter
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          size: 16,
                                          color: Color(0xFF0D1845),
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
                                  ),
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
                                      value: _selectedCategory,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF0D1845),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      items:
                                          [
                                                'All',
                                                'Electronics',
                                                'Footwear',
                                                'Clothing',
                                                'Home & Kitchen',
                                              ]
                                              .map(
                                                (category) => DropdownMenuItem(
                                                  value: category,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        category == 'All'
                                                            ? Icons.inventory_2
                                                            : _getCategoryIcon(
                                                                category,
                                                              ),
                                                        color: category == 'All'
                                                            ? Color(0xFF6C757D)
                                                            : Color(0xFF0D1845),
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        category,
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF343A40,
                                                          ),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedCategory = value;
                                            _updateSelectAllState();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Sort By Filter
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.sort,
                                          size: 16,
                                          color: Color(0xFF0D1845),
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
                                  ),
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
                                      value: _sortBy,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFFDEE2E6),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF0D1845),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      items:
                                          [
                                                'Total Sales',
                                                'Total Revenue',
                                                'Total Quantity',
                                                'Rank',
                                              ]
                                              .map(
                                                (sort) => DropdownMenuItem(
                                                  value: sort,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.trending_up,
                                                        color: Color(
                                                          0xFF0D1845,
                                                        ),
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        sort,
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF343A40,
                                                          ),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _sortBy = value;
                                            _updateSelectAllState();
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

                  // Enhanced Table Section
                  Container(
                    constraints: const BoxConstraints(maxHeight: 600),
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
                              Checkbox(
                                value: _selectAll,
                                onChanged: (value) => _toggleSelectAll(),
                                activeColor: Color(0xFF0D1845),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.star,
                                color: Color(0xFF0D1845),
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Best Seller Products',
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
                                      Icons.inventory,
                                      color: Color(0xFF1976D2),
                                      size: 12,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      '${paginatedProducts.length} Products',
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
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  Color(0xFFF8F9FA),
                                ),
                                dataRowColor:
                                    MaterialStateProperty.resolveWith<Color>((
                                      Set<MaterialState> states,
                                    ) {
                                      if (states.contains(
                                        MaterialState.selected,
                                      )) {
                                        return Color(
                                          0xFF0D1845,
                                        ).withOpacity(0.1);
                                      }
                                      return Colors.white;
                                    }),
                                columns: const [
                                  DataColumn(label: Text('Select')),
                                  DataColumn(label: Text('Rank')),
                                  DataColumn(label: Text('Product')),
                                  DataColumn(label: Text('Code')),
                                  DataColumn(label: Text('Category')),
                                  DataColumn(label: Text('Total Sold')),
                                  DataColumn(label: Text('Quantity')),
                                  DataColumn(label: Text('Total Revenue')),
                                  DataColumn(label: Text('Avg. Price')),
                                  DataColumn(label: Text('Stock Left')),
                                  DataColumn(label: Text('Last Sold')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: paginatedProducts.map((product) {
                                  final isSelected = _selectedReports.any(
                                    (r) => r.productId == product.productId,
                                  );
                                  final rank =
                                      paginatedProducts.indexOf(product) +
                                      1 +
                                      ((_currentPage - 1) * _itemsPerPage);
                                  return DataRow(
                                    selected: isSelected,
                                    cells: [
                                      DataCell(
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (value) =>
                                              _toggleReportSelection(product),
                                          activeColor: Color(0xFF0D1845),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRankColor(
                                              rank,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                rank <= 3
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: _getRankColor(rank),
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '#$rank',
                                                style: TextStyle(
                                                  color: _getRankColor(rank),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Color(
                                                  0xFF0D1845,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                Icons.inventory,
                                                color: Color(0xFF0D1845),
                                                size: 16,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              product.productName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(product.designCode)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            product.subCategoryId,
                                            style: TextStyle(
                                              color: Color(0xFF1976D2),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          product.totalSold.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(product.totalSold.toString()),
                                      ), // Using totalSold as quantity for now
                                      DataCell(
                                        Text(
                                          'Rs. ${product.totalRevenue.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF28A745),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          'Rs. ${(product.totalRevenue / product.totalSold).toStringAsFixed(2)}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          product.inStockQuantity,
                                          style: TextStyle(
                                            color:
                                                int.tryParse(
                                                          product
                                                              .inStockQuantity,
                                                        ) !=
                                                        null &&
                                                    int.parse(
                                                          product
                                                              .inStockQuantity,
                                                        ) <
                                                        10
                                                ? Colors.red
                                                : Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          DateFormat('dd MMM yyyy').format(
                                            DateTime.parse(product.updatedAt),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.visibility,
                                                color: Color(0xFF0D1845),
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                // TODO: Implement view details
                                              },
                                              tooltip: 'View Details',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.analytics,
                                                color: Color(0xFF007BFF),
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                // TODO: Implement analytics
                                              },
                                              tooltip: 'View Analytics',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        // Pagination Controls
                        _buildPaginationControls(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    // Show pagination controls even with 1 page for testing
    // if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                      _updateSelectAllState();
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            color: _currentPage > 1 ? Color(0xFF0D1845) : Colors.grey,
            tooltip: 'Previous Page',
          ),

          // Page numbers
          ..._buildPageNumbers(),

          // Next button
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                      _updateSelectAllState();
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            color: _currentPage < _totalPages ? Color(0xFF0D1845) : Colors.grey,
            tooltip: 'Next Page',
          ),

          // Page info
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF0D1845).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: TextStyle(
                color: Color(0xFF0D1845),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];
    int startPage = 1;
    int endPage = _totalPages;

    // Show max 5 page numbers at a time
    if (_totalPages > 5) {
      if (_currentPage <= 3) {
        endPage = 5;
      } else if (_currentPage >= _totalPages - 2) {
        startPage = _totalPages - 4;
      } else {
        startPage = _currentPage - 2;
        endPage = _currentPage + 2;
      }
    }

    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(
        InkWell(
          onTap: () {
            setState(() {
              _currentPage = i;
              _updateSelectAllState();
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _currentPage == i ? Color(0xFF0D1845) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _currentPage == i
                    ? Color(0xFF0D1845)
                    : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Text(
              i.toString(),
              style: TextStyle(
                color: _currentPage == i ? Colors.white : Color(0xFF0D1845),
                fontWeight: _currentPage == i
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return pageNumbers;
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEE2E6), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF343A40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/sales_report_service.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  // API data
  List<SalesReport> _salesReport = [];
  List<SalesReport> _selectedReports = [];
  bool _selectAll = false;
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;

  // Filter states
  String _selectedPeriod = 'All Time';
  String _selectedVendor = 'All';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadSalesReport();
  }

  Future<void> _loadSalesReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await SalesReportService.getSalesReport();
      setState(() {
        _salesReport = response.data;
        _selectedReports.clear(); // Clear selections when new data loads
        _selectAll = false;
        _currentPage = 1; // Reset to first page
        _isLoading = false;
      });
    } catch (e) {
      // Temporary mock data for testing pagination
      setState(() {
        _salesReport = _generateMockData();
        _selectedReports.clear();
        _selectAll = false;
        _currentPage = 1; // Reset to first page
        _errorMessage = 'API Error: $e\n\nShowing mock data for testing';
        _isLoading = false;
      });
    }
  }

  List<SalesReport> _generateMockData() {
    return [
      SalesReport(
        posInvNo: 1,
        productName: 'Product A',
        vendor: 'Carl Evans',
        category: 'Electronics',
        qty: '5',
        salePrice: '220.00',
        amount: 1100.0,
        openingStockQty: '10',
        newStockQty: '5',
        soldStockQty: '2',
        instockQty: '13',
      ),
      SalesReport(
        posInvNo: 2,
        productName: 'Product B',
        vendor: 'Minerva Rameriz',
        category: 'Clothing',
        qty: '3',
        salePrice: '160.00',
        amount: 480.0,
        openingStockQty: '20',
        newStockQty: '8',
        soldStockQty: '1',
        instockQty: '27',
      ),
      SalesReport(
        posInvNo: 3,
        productName: 'Product C',
        vendor: 'Robert Lamon',
        category: 'Home & Kitchen',
        qty: '7',
        salePrice: '290.00',
        amount: 2030.0,
        openingStockQty: '15',
        newStockQty: '3',
        soldStockQty: '4',
        instockQty: '14',
      ),
      SalesReport(
        posInvNo: 4,
        productName: 'Product D',
        vendor: 'Mark Joslyn',
        category: 'Footwear',
        qty: '2',
        salePrice: '135.00',
        amount: 270.0,
        openingStockQty: '8',
        newStockQty: '6',
        soldStockQty: '0',
        instockQty: '14',
      ),
      SalesReport(
        posInvNo: 5,
        productName: 'Product E',
        vendor: 'Patricia Lewis',
        category: 'Electronics',
        qty: '4',
        salePrice: '85.00',
        amount: 340.0,
        openingStockQty: '12',
        newStockQty: '2',
        soldStockQty: '3',
        instockQty: '11',
      ),
    ];
  }

  void _toggleReportSelection(SalesReport report) {
    setState(() {
      final reportId = report.posInvNo;
      final existingIndex = _selectedReports.indexWhere(
        (r) => r.posInvNo == reportId,
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
      final currentPageReports = _getPaginatedReports();
      if (_selectAll) {
        // Remove all current page items from selection
        for (final report in currentPageReports) {
          _selectedReports.removeWhere((r) => r.posInvNo == report.posInvNo);
        }
      } else {
        // Add all current page items to selection (avoiding duplicates)
        for (final report in currentPageReports) {
          if (!_selectedReports.any((r) => r.posInvNo == report.posInvNo)) {
            _selectedReports.add(report);
          }
        }
      }
      _updateSelectAllState();
    });
  }

  void _updateSelectAllState() {
    final currentPageReports = _getPaginatedReports();
    _selectAll =
        currentPageReports.isNotEmpty &&
        currentPageReports.every(
          (report) =>
              _selectedReports.any((r) => r.posInvNo == report.posInvNo),
        );
  }

  List<SalesReport> _getFilteredReports() {
    return _salesReport.where((report) {
      final vendorMatch =
          _selectedVendor == 'All' || report.vendor == _selectedVendor;
      final categoryMatch =
          _selectedCategory == 'All' || report.category == _selectedCategory;

      return vendorMatch && categoryMatch;
    }).toList();
  }

  List<SalesReport> _getPaginatedReports() {
    final filteredReports = _getFilteredReports();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    _totalPages = (filteredReports.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;

    return filteredReports.sublist(
      startIndex,
      endIndex > filteredReports.length ? filteredReports.length : endIndex,
    );
  }

  double _calculateTotal(String field) {
    return _getFilteredReports().fold(0.0, (sum, report) {
      switch (field) {
        case 'totalAmount':
          return sum + report.amount;
        case 'totalQty':
          return sum + int.tryParse(report.qty)!.toDouble();
        default:
          return sum;
      }
    });
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
                onPressed: _loadSalesReport,
                child: const Text('Retry API Call'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredReports = _getFilteredReports();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF8F9FA)],
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
                      Icons.bar_chart,
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
                          'Sales Report',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comprehensive sales analytics and reporting',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
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
                  ElevatedButton.icon(
                    onPressed: () {
                      _loadSalesReport();
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
                  'Total Sales',
                  'Rs. ${_calculateTotal('totalAmount').toStringAsFixed(2)}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Total Items',
                  '${_calculateTotal('totalQty').toInt()}',
                  Icons.inventory,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Records',
                  '${filteredReports.length}',
                  Icons.receipt,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Avg. Sale Value',
                  filteredReports.isNotEmpty
                      ? 'Rs. ${(_calculateTotal('totalAmount') / filteredReports.length).toStringAsFixed(2)}'
                      : 'Rs. 0.00',
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
                      // Period Filter (placeholder for now since API doesn't have date)
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
                                    'Period',
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
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                                items: ['All Time']
                                    .map(
                                      (period) => DropdownMenuItem(
                                        value: period,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              color: Color(0xFF0D1845),
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              period,
                                              style: TextStyle(
                                                color: Color(0xFF343A40),
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
                                      _selectedPeriod = value;
                                      _currentPage = 1; // Reset to first page
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
                      // Vendor Filter
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
                                    Icons.person,
                                    size: 16,
                                    color: Color(0xFF0D1845),
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
                                value: _selectedVendor,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                                          ..._salesReport
                                              .map((r) => r.vendor)
                                              .toSet()
                                              .toList(),
                                        ]
                                        .map(
                                          (vendor) => DropdownMenuItem(
                                            value: vendor,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  vendor == 'All'
                                                      ? Icons.group
                                                      : Icons.person,
                                                  color: vendor == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : Color(0xFF0D1845),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  vendor,
                                                  style: TextStyle(
                                                    color: Color(0xFF343A40),
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
                                      _selectedVendor = value;
                                      _currentPage = 1; // Reset to first page
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
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                                          ..._salesReport
                                              .map((r) => r.category)
                                              .toSet()
                                              .toList(),
                                        ]
                                        .map(
                                          (category) => DropdownMenuItem(
                                            value: category,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  category == 'All'
                                                      ? Icons.inventory_2
                                                      : Icons.category,
                                                  color: category == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : Color(0xFF0D1845),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  category,
                                                  style: TextStyle(
                                                    color: Color(0xFF343A40),
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
                                      _currentPage = 1; // Reset to first page
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
                          Icons.bar_chart,
                          color: Color(0xFF0D1845),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sales Report Details',
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
                                Icons.receipt,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${filteredReports.length} Records',
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
                      dataRowColor: MaterialStateProperty.resolveWith<Color>((
                        Set<MaterialState> states,
                      ) {
                        if (states.contains(MaterialState.selected)) {
                          return Color(0xFF0D1845).withOpacity(0.1);
                        }
                        return Colors.white;
                      }),
                      columns: const [
                        DataColumn(label: Text('Select')),
                        DataColumn(label: Text('Invoice No')),
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Sale Price')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Opening Stock')),
                        DataColumn(label: Text('New Stock')),
                        DataColumn(label: Text('Sold Stock')),
                        DataColumn(label: Text('In Stock')),
                      ],
                      rows: _getPaginatedReports().map((report) {
                        final isSelected = _selectedReports.any(
                          (r) => r.posInvNo == report.posInvNo,
                        );
                        return DataRow(
                          selected: isSelected,
                          cells: [
                            DataCell(
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _toggleReportSelection(report),
                                activeColor: Color(0xFF0D1845),
                              ),
                            ),
                            DataCell(Text(report.posInvNo.toString())),
                            DataCell(Text(report.productName)),
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF0D1845).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Color(0xFF0D1845),
                                      size: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(report.vendor),
                                ],
                              ),
                            ),
                            DataCell(Text(report.category)),
                            DataCell(Text(report.qty.toString())),
                            DataCell(
                              Text(
                                'Rs. ${double.parse(report.salePrice).toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report.amount.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(Text(report.openingStockQty.toString())),
                            DataCell(Text(report.newStockQty.toString())),
                            DataCell(Text(report.soldStockQty.toString())),
                            DataCell(Text(report.instockQty.toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pagination Controls
            _buildPaginationControls(),
          ],
        ),
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

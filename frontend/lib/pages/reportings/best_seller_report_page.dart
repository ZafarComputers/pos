import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BestSellerReportPage extends StatefulWidget {
  const BestSellerReportPage({super.key});

  @override
  State<BestSellerReportPage> createState() => _BestSellerReportPageState();
}

class _BestSellerReportPageState extends State<BestSellerReportPage> {
  // Mock data for best seller report
  List<Map<String, dynamic>> _bestSellerReport = [];
  List<Map<String, dynamic>> _selectedReports = [];
  bool _selectAll = false;

  // Filter states
  String _selectedPeriod = 'Last 7 Days';
  String _selectedCategory = 'All';
  String _sortBy = 'Total Sales';

  @override
  void initState() {
    super.initState();
    _loadMockBestSellerReport();
  }

  void _loadMockBestSellerReport() {
    // Mock best seller report data
    _bestSellerReport = [
      {
        'id': '1',
        'productName': 'iPhone 15 Pro Max',
        'productCode': 'IP15PM-128',
        'category': 'Electronics',
        'totalSold': 145,
        'totalQuantity': 145,
        'totalRevenue': 2175000.0,
        'averagePrice': 15000.0,
        'lastSold': DateTime(2025, 10, 8),
        'stockRemaining': 23,
        'rank': 1,
      },
      {
        'id': '2',
        'productName': 'Samsung Galaxy S24 Ultra',
        'productCode': 'SGS24U-256',
        'category': 'Electronics',
        'totalSold': 132,
        'totalQuantity': 132,
        'totalRevenue': 1848000.0,
        'averagePrice': 14000.0,
        'lastSold': DateTime(2025, 10, 7),
        'stockRemaining': 18,
        'rank': 2,
      },
      {
        'id': '3',
        'productName': 'MacBook Pro M3',
        'productCode': 'MBPM3-16',
        'category': 'Electronics',
        'totalSold': 98,
        'totalQuantity': 98,
        'totalRevenue': 2940000.0,
        'averagePrice': 30000.0,
        'lastSold': DateTime(2025, 10, 6),
        'stockRemaining': 7,
        'rank': 3,
      },
      {
        'id': '4',
        'productName': 'Nike Air Max 270',
        'productCode': 'NAM270-BLK',
        'category': 'Footwear',
        'totalSold': 87,
        'totalQuantity': 87,
        'totalRevenue': 130500.0,
        'averagePrice': 1500.0,
        'lastSold': DateTime(2025, 10, 5),
        'stockRemaining': 45,
        'rank': 4,
      },
      {
        'id': '5',
        'productName': 'Sony WH-1000XM5',
        'productCode': 'WH1000XM5-BLK',
        'category': 'Electronics',
        'totalSold': 76,
        'totalQuantity': 76,
        'totalRevenue': 304000.0,
        'averagePrice': 4000.0,
        'lastSold': DateTime(2025, 10, 4),
        'stockRemaining': 12,
        'rank': 5,
      },
      {
        'id': '6',
        'productName': 'Levi\'s 501 Original',
        'productCode': 'LV501-BLU',
        'category': 'Clothing',
        'totalSold': 65,
        'totalQuantity': 65,
        'totalRevenue': 97500.0,
        'averagePrice': 1500.0,
        'lastSold': DateTime(2025, 10, 3),
        'stockRemaining': 28,
        'rank': 6,
      },
      {
        'id': '7',
        'productName': 'KitchenAid Stand Mixer',
        'productCode': 'KA-SM-5QT',
        'category': 'Home & Kitchen',
        'totalSold': 54,
        'totalQuantity': 54,
        'totalRevenue': 216000.0,
        'averagePrice': 4000.0,
        'lastSold': DateTime(2025, 10, 2),
        'stockRemaining': 8,
        'rank': 7,
      },
      {
        'id': '8',
        'productName': 'Adidas Ultraboost 23',
        'productCode': 'ADUB23-WHT',
        'category': 'Footwear',
        'totalSold': 48,
        'totalQuantity': 48,
        'totalRevenue': 72000.0,
        'averagePrice': 1500.0,
        'lastSold': DateTime(2025, 10, 1),
        'stockRemaining': 32,
        'rank': 8,
      },
    ];
  }

  void _toggleReportSelection(Map<String, dynamic> report) {
    setState(() {
      final reportId = report['id'];
      final existingIndex = _selectedReports.indexWhere(
        (r) => r['id'] == reportId,
      );

      if (existingIndex >= 0) {
        _selectedReports.removeAt(existingIndex);
      } else {
        _selectedReports.add(Map<String, dynamic>.from(report));
      }

      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedReports.clear();
      } else {
        _selectedReports = List.from(_getFilteredReports());
      }
      _selectAll = !_selectAll;
    });
  }

  void _updateSelectAllState() {
    final filteredReports = _getFilteredReports();
    _selectAll =
        filteredReports.isNotEmpty &&
        _selectedReports.length == filteredReports.length;
  }

  List<Map<String, dynamic>> _getFilteredReports() {
    List<Map<String, dynamic>> filtered = _bestSellerReport.where((report) {
      final categoryMatch =
          _selectedCategory == 'All' || report['category'] == _selectedCategory;

      // Date filtering based on period
      bool dateMatch = true;
      if (_selectedPeriod == 'Last 7 Days') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        dateMatch = report['lastSold'].isAfter(sevenDaysAgo);
      } else if (_selectedPeriod == 'Last 30 Days') {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        dateMatch = report['lastSold'].isAfter(thirtyDaysAgo);
      }

      return categoryMatch && dateMatch;
    }).toList();

    // Sort based on selected criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Total Sales':
          return b['totalSold'].compareTo(a['totalSold']);
        case 'Total Revenue':
          return b['totalRevenue'].compareTo(a['totalRevenue']);
        case 'Total Quantity':
          return b['totalQuantity'].compareTo(a['totalQuantity']);
        default:
          return a['rank'].compareTo(b['rank']);
      }
    });

    return filtered;
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

  double _calculateTotal(String field) {
    return _getFilteredReports().fold(
      0.0,
      (sum, report) => sum + (report[field] as double),
    );
  }

  int _calculateTotalInt(String field) {
    return _getFilteredReports().fold(
      0,
      (sum, report) => sum + (report[field] as int),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        Text(
                          'Top performing products and sales analytics',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
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
                  '${filteredReports.length}',
                  Icons.inventory,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Total Sales',
                  '${_calculateTotalInt('totalSold')}',
                  Icons.shopping_cart,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Revenue',
                  'Rs. ${_calculateTotal('totalRevenue').toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Avg. Order Value',
                  'Rs. ${(_calculateTotal('totalRevenue') / _calculateTotalInt('totalSold')).toStringAsFixed(2)}',
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
                                    ['Last 7 Days', 'Last 30 Days', 'All Time']
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
                                                  color: Color(0xFF0D1845),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  sort,
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
                        Icon(Icons.star, color: Color(0xFF0D1845), size: 18),
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
                                '${filteredReports.length} Products',
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
                      rows: filteredReports.map((report) {
                        final isSelected = _selectedReports.any(
                          (r) => r['id'] == report['id'],
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
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRankColor(
                                    report['rank'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      report['rank'] <= 3
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: _getRankColor(report['rank']),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '#${report['rank']}',
                                      style: TextStyle(
                                        color: _getRankColor(report['rank']),
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
                                      color: Color(0xFF0D1845).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(report['category']),
                                      color: Color(0xFF0D1845),
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    report['productName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(report['productCode'])),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  report['category'],
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
                                report['totalSold'].toString(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(Text(report['totalQuantity'].toString())),
                            DataCell(
                              Text(
                                'Rs. ${report['totalRevenue'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF28A745),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report['averagePrice'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                report['stockRemaining'].toString(),
                                style: TextStyle(
                                  color: report['stockRemaining'] < 10
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(report['lastSold']),
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
                ],
              ),
            ),
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InventoryReportPage extends StatefulWidget {
  const InventoryReportPage({super.key});

  @override
  State<InventoryReportPage> createState() => _InventoryReportPageState();
}

class _InventoryReportPageState extends State<InventoryReportPage> {
  // Mock data for inventory report
  List<Map<String, dynamic>> _inventoryReport = [];
  List<Map<String, dynamic>> _selectedReports = [];
  bool _selectAll = false;

  // Filter states
  String _selectedCategory = 'All';
  String _selectedStockStatus = 'All';
  String _sortBy = 'Product Name';

  @override
  void initState() {
    super.initState();
    _loadMockInventoryReport();
  }

  void _loadMockInventoryReport() {
    // Mock inventory report data
    _inventoryReport = [
      {
        'id': '1',
        'productName': 'iPhone 15 Pro Max',
        'productCode': 'IP15PM-128',
        'category': 'Electronics',
        'currentStock': 23,
        'minStock': 5,
        'maxStock': 50,
        'unitCost': 1200.0,
        'sellingPrice': 1500.0,
        'totalValue': 34500.0,
        'lastUpdated': DateTime(2025, 10, 8),
        'stockStatus': 'Low Stock',
        'supplier': 'TechCorp Supplies',
      },
      {
        'id': '2',
        'productName': 'Samsung Galaxy S24 Ultra',
        'productCode': 'SGS24U-256',
        'category': 'Electronics',
        'currentStock': 18,
        'minStock': 3,
        'maxStock': 40,
        'unitCost': 1100.0,
        'sellingPrice': 1400.0,
        'totalValue': 25200.0,
        'lastUpdated': DateTime(2025, 10, 7),
        'stockStatus': 'In Stock',
        'supplier': 'Global Electronics',
      },
      {
        'id': '3',
        'productName': 'Nike Air Max 270',
        'productCode': 'NAM270-BLK',
        'category': 'Footwear',
        'currentStock': 45,
        'minStock': 10,
        'maxStock': 80,
        'unitCost': 1200.0,
        'sellingPrice': 1500.0,
        'totalValue': 54000.0,
        'lastUpdated': DateTime(2025, 10, 6),
        'stockStatus': 'In Stock',
        'supplier': 'Fashion Wholesale',
      },
      {
        'id': '4',
        'productName': 'KitchenAid Stand Mixer',
        'productCode': 'KA-SM-5QT',
        'category': 'Home & Kitchen',
        'currentStock': 8,
        'minStock': 2,
        'maxStock': 25,
        'unitCost': 3200.0,
        'sellingPrice': 4000.0,
        'totalValue': 25600.0,
        'lastUpdated': DateTime(2025, 10, 5),
        'stockStatus': 'Low Stock',
        'supplier': 'Home & Kitchen Ltd',
      },
      {
        'id': '5',
        'productName': 'Levi\'s 501 Original',
        'productCode': 'LV501-BLU',
        'category': 'Clothing',
        'currentStock': 28,
        'minStock': 5,
        'maxStock': 60,
        'unitCost': 1200.0,
        'sellingPrice': 1500.0,
        'totalValue': 33600.0,
        'lastUpdated': DateTime(2025, 10, 4),
        'stockStatus': 'In Stock',
        'supplier': 'Fashion Wholesale',
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
    List<Map<String, dynamic>> filtered = _inventoryReport.where((report) {
      final categoryMatch =
          _selectedCategory == 'All' || report['category'] == _selectedCategory;

      bool stockStatusMatch = true;
      if (_selectedStockStatus == 'Low Stock') {
        stockStatusMatch = report['stockStatus'] == 'Low Stock';
      } else if (_selectedStockStatus == 'Out of Stock') {
        stockStatusMatch = report['stockStatus'] == 'Out of Stock';
      } else if (_selectedStockStatus == 'In Stock') {
        stockStatusMatch = report['stockStatus'] == 'In Stock';
      }

      return categoryMatch && stockStatusMatch;
    }).toList();

    // Sort based on selected criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Product Name':
          return a['productName'].compareTo(b['productName']);
        case 'Current Stock':
          return b['currentStock'].compareTo(a['currentStock']);
        case 'Total Value':
          return b['totalValue'].compareTo(a['totalValue']);
        default:
          return a['productName'].compareTo(b['productName']);
      }
    });

    return filtered;
  }

  Color _getStockStatusColor(String status) {
    switch (status) {
      case 'In Stock':
        return Colors.green;
      case 'Low Stock':
        return Colors.orange;
      case 'Out of Stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
                      Icons.inventory_2,
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
                          'Inventory Report',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock levels, valuation, and inventory analytics',
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
                  'Total Stock',
                  '${_calculateTotalInt('currentStock')}',
                  Icons.warehouse,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Value',
                  'Rs. ${_calculateTotal('totalValue').toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Low Stock Items',
                  '${filteredReports.where((r) => r['stockStatus'] == 'Low Stock').length}',
                  Icons.warning,
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
                      // Stock Status Filter
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
                                    Icons.info,
                                    size: 16,
                                    color: Color(0xFF0D1845),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Stock Status',
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
                                value: _selectedStockStatus,
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
                                          'In Stock',
                                          'Low Stock',
                                          'Out of Stock',
                                        ]
                                        .map(
                                          (status) => DropdownMenuItem(
                                            value: status,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  status == 'All'
                                                      ? Icons
                                                            .inventory_2_rounded
                                                      : status == 'In Stock'
                                                      ? Icons.check_circle
                                                      : status == 'Low Stock'
                                                      ? Icons.warning
                                                      : Icons.cancel,
                                                  color: status == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : status == 'In Stock'
                                                      ? Color(0xFF28A745)
                                                      : status == 'Low Stock'
                                                      ? Color(0xFFFFA726)
                                                      : Color(0xFFDC3545),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  status,
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
                                      _selectedStockStatus = value;
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
                                          'Product Name',
                                          'Current Stock',
                                          'Total Value',
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
                        Icon(
                          Icons.inventory_2,
                          color: Color(0xFF0D1845),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Inventory Details',
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
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Code')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Current Stock')),
                        DataColumn(label: Text('Min Stock')),
                        DataColumn(label: Text('Max Stock')),
                        DataColumn(label: Text('Unit Cost')),
                        DataColumn(label: Text('Selling Price')),
                        DataColumn(label: Text('Total Value')),
                        DataColumn(label: Text('Stock Status')),
                        DataColumn(label: Text('Supplier')),
                        DataColumn(label: Text('Last Updated')),
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
                                report['currentStock'].toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      report['currentStock'] <
                                          report['minStock']
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),
                            DataCell(Text(report['minStock'].toString())),
                            DataCell(Text(report['maxStock'].toString())),
                            DataCell(
                              Text(
                                'Rs. ${report['unitCost'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report['sellingPrice'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report['totalValue'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF28A745),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStockStatusColor(
                                    report['stockStatus'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  report['stockStatus'],
                                  style: TextStyle(
                                    color: _getStockStatusColor(
                                      report['stockStatus'],
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(report['supplier'])),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(report['lastUpdated']),
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
                                      Icons.edit,
                                      color: Color(0xFF007BFF),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement edit stock
                                    },
                                    tooltip: 'Edit Stock',
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

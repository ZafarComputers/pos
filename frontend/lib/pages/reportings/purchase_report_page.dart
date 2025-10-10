import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchaseReportPage extends StatefulWidget {
  const PurchaseReportPage({super.key});

  @override
  State<PurchaseReportPage> createState() => _PurchaseReportPageState();
}

class _PurchaseReportPageState extends State<PurchaseReportPage> {
  // Mock data for purchase report
  List<Map<String, dynamic>> _purchaseReport = [];
  List<Map<String, dynamic>> _selectedReports = [];
  bool _selectAll = false;

  // Filter states
  String _selectedPeriod = 'Last 7 Days';
  String _selectedSupplier = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadMockPurchaseReport();
  }

  void _loadMockPurchaseReport() {
    // Mock purchase report data
    _purchaseReport = [
      {
        'id': '1',
        'date': DateTime(2025, 10, 8),
        'reference': 'PUR-2025-001',
        'supplier': 'TechCorp Supplies',
        'totalItems': 15,
        'totalQuantity': 45,
        'subtotal': 22500.0,
        'tax': 2250.0,
        'discount': 500.0,
        'shipping': 200.0,
        'grandTotal': 24450.0,
        'paidAmount': 24450.0,
        'dueAmount': 0.0,
        'paymentMethod': 'Bank Transfer',
        'status': 'Completed',
        'receivedBy': 'John Smith',
      },
      {
        'id': '2',
        'date': DateTime(2025, 10, 7),
        'reference': 'PUR-2025-002',
        'supplier': 'Global Electronics',
        'totalItems': 8,
        'totalQuantity': 24,
        'subtotal': 16800.0,
        'tax': 1680.0,
        'discount': 0.0,
        'shipping': 150.0,
        'grandTotal': 18630.0,
        'paidAmount': 9300.0,
        'dueAmount': 9330.0,
        'paymentMethod': 'Partial Payment',
        'status': 'Pending',
        'receivedBy': 'Sarah Johnson',
      },
      {
        'id': '3',
        'date': DateTime(2025, 10, 6),
        'reference': 'PUR-2025-003',
        'supplier': 'Fashion Wholesale',
        'totalItems': 12,
        'totalQuantity': 36,
        'subtotal': 12600.0,
        'tax': 1260.0,
        'discount': 300.0,
        'shipping': 100.0,
        'grandTotal': 13660.0,
        'paidAmount': 13660.0,
        'dueAmount': 0.0,
        'paymentMethod': 'Cash',
        'status': 'Completed',
        'receivedBy': 'Mike Davis',
      },
      {
        'id': '4',
        'date': DateTime(2025, 10, 5),
        'reference': 'PUR-2025-004',
        'supplier': 'Home & Kitchen Ltd',
        'totalItems': 6,
        'totalQuantity': 18,
        'subtotal': 9600.0,
        'tax': 960.0,
        'discount': 200.0,
        'shipping': 80.0,
        'grandTotal': 10440.0,
        'paidAmount': 0.0,
        'dueAmount': 10440.0,
        'paymentMethod': 'Unpaid',
        'status': 'Cancelled',
        'receivedBy': 'Lisa Wilson',
      },
      {
        'id': '5',
        'date': DateTime(2025, 10, 4),
        'reference': 'PUR-2025-005',
        'supplier': 'Sports Equipment Co',
        'totalItems': 10,
        'totalQuantity': 30,
        'subtotal': 19500.0,
        'tax': 1950.0,
        'discount': 400.0,
        'shipping': 120.0,
        'grandTotal': 21170.0,
        'paidAmount': 21170.0,
        'dueAmount': 0.0,
        'paymentMethod': 'Card',
        'status': 'Completed',
        'receivedBy': 'Tom Brown',
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
    return _purchaseReport.where((report) {
      final supplierMatch =
          _selectedSupplier == 'All' || report['supplier'] == _selectedSupplier;
      final statusMatch =
          _selectedStatus == 'All' || report['status'] == _selectedStatus;

      // Date filtering
      bool dateMatch = true;
      if (_selectedPeriod == 'Last 7 Days') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        dateMatch = report['date'].isAfter(sevenDaysAgo);
      } else if (_selectedPeriod == 'Last 30 Days') {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        dateMatch = report['date'].isAfter(thirtyDaysAgo);
      }

      return supplierMatch && statusMatch && dateMatch;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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
                      Icons.shopping_bag,
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
                          'Purchase Report',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comprehensive purchase transactions and supplier analytics',
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
                  'Total Purchases',
                  '${filteredReports.length}',
                  Icons.shopping_bag,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Total Items',
                  '${_calculateTotalInt('totalItems')}',
                  Icons.inventory,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Amount',
                  'Rs. ${_calculateTotal('grandTotal').toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Total Paid',
                  'Rs. ${_calculateTotal('paidAmount').toStringAsFixed(2)}',
                  Icons.payments,
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
                      // Supplier Filter
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
                                    Icons.business,
                                    size: 16,
                                    color: Color(0xFF0D1845),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Supplier',
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
                                value: _selectedSupplier,
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
                                          'TechCorp Supplies',
                                          'Global Electronics',
                                          'Fashion Wholesale',
                                          'Home & Kitchen Ltd',
                                          'Sports Equipment Co',
                                        ]
                                        .map(
                                          (supplier) => DropdownMenuItem(
                                            value: supplier,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  supplier == 'All'
                                                      ? Icons.business_center
                                                      : Icons.business,
                                                  color: supplier == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : Color(0xFF0D1845),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  supplier,
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
                                      _selectedSupplier = value;
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
                      // Status Filter
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
                                    'Status',
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
                                value: _selectedStatus,
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
                                    ['All', 'Completed', 'Pending', 'Cancelled']
                                        .map(
                                          (status) => DropdownMenuItem(
                                            value: status,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  status == 'All'
                                                      ? Icons
                                                            .inventory_2_rounded
                                                      : status == 'Completed'
                                                      ? Icons
                                                            .check_circle_rounded
                                                      : status == 'Pending'
                                                      ? Icons.pending
                                                      : Icons.cancel_rounded,
                                                  color: status == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : status == 'Completed'
                                                      ? Color(0xFF28A745)
                                                      : status == 'Pending'
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
                                      _selectedStatus = value;
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
                          Icons.shopping_bag,
                          color: Color(0xFF0D1845),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Purchase Report Details',
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
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Reference')),
                        DataColumn(label: Text('Supplier')),
                        DataColumn(label: Text('Items')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Subtotal')),
                        DataColumn(label: Text('Tax')),
                        DataColumn(label: Text('Discount')),
                        DataColumn(label: Text('Shipping')),
                        DataColumn(label: Text('Grand Total')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Due')),
                        DataColumn(label: Text('Payment Method')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Received By')),
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
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(report['date']),
                              ),
                            ),
                            DataCell(Text(report['reference'])),
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
                                      Icons.business,
                                      color: Color(0xFF0D1845),
                                      size: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(report['supplier']),
                                ],
                              ),
                            ),
                            DataCell(Text(report['totalItems'].toString())),
                            DataCell(Text(report['totalQuantity'].toString())),
                            DataCell(
                              Text(
                                'Rs. ${report['subtotal'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text('Rs. ${report['tax'].toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report['discount'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report['shipping'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report['grandTotal'].toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report['paidAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report['dueAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(Text(report['paymentMethod'])),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    report['status'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  report['status'],
                                  style: TextStyle(
                                    color: _getStatusColor(report['status']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(report['receivedBy'])),
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
                                      Icons.print,
                                      color: Color(0xFF28A745),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement print
                                    },
                                    tooltip: 'Print',
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

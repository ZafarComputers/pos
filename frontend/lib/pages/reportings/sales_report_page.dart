import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  // Mock data for sales report
  List<Map<String, dynamic>> _salesReport = [];
  List<Map<String, dynamic>> _selectedReports = [];
  bool _selectAll = false;

  // Filter states
  String _selectedPeriod = 'Last 7 Days';
  String _selectedVendor = 'All';
  String _selectedBiller = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadMockSalesReport();
  }

  void _loadMockSalesReport() {
    // Mock sales report data
    _salesReport = [
      {
        'id': '1',
        'date': DateTime(2025, 10, 8),
        'reference': 'SALE-2025-001',
        'vendor': 'Carl Evans',
        'biller': 'John Smith',
        'totalItems': 5,
        'totalQuantity': 8,
        'subtotal': 2200.0,
        'tax': 300.0,
        'discount': 50.0,
        'grandTotal': 2450.0,
        'paidAmount': 2450.0,
        'dueAmount': 0.0,
        'paymentMethod': 'Cash',
        'status': 'Completed',
      },
      {
        'id': '2',
        'date': DateTime(2025, 10, 7),
        'reference': 'SALE-2025-002',
        'vendor': 'Minerva Rameriz',
        'biller': 'Sarah Johnson',
        'totalItems': 3,
        'totalQuantity': 5,
        'subtotal': 1600.0,
        'tax': 200.0,
        'discount': 0.0,
        'grandTotal': 1800.0,
        'paidAmount': 900.0,
        'dueAmount': 900.0,
        'paymentMethod': 'Card',
        'status': 'Pending',
      },
      {
        'id': '3',
        'date': DateTime(2025, 10, 6),
        'reference': 'SALE-2025-003',
        'vendor': 'Robert Lamon',
        'biller': 'Mike Davis',
        'totalItems': 7,
        'totalQuantity': 12,
        'subtotal': 2900.0,
        'tax': 300.0,
        'discount': 100.0,
        'grandTotal': 3100.0,
        'paidAmount': 3100.0,
        'dueAmount': 0.0,
        'paymentMethod': 'Bank Transfer',
        'status': 'Completed',
      },
      {
        'id': '4',
        'date': DateTime(2025, 10, 5),
        'reference': 'SALE-2025-004',
        'vendor': 'Mark Joslyn',
        'biller': 'Lisa Wilson',
        'totalItems': 2,
        'totalQuantity': 3,
        'subtotal': 1350.0,
        'tax': 150.0,
        'discount': 0.0,
        'grandTotal': 1500.0,
        'paidAmount': 0.0,
        'dueAmount': 1500.0,
        'paymentMethod': 'Unpaid',
        'status': 'Cancelled',
      },
      {
        'id': '5',
        'date': DateTime(2025, 10, 4),
        'reference': 'SALE-2025-005',
        'vendor': 'Patricia Lewis',
        'biller': 'Tom Brown',
        'totalItems': 4,
        'totalQuantity': 6,
        'subtotal': 850.0,
        'tax': 100.0,
        'discount': 50.0,
        'grandTotal': 900.0,
        'paidAmount': 900.0,
        'dueAmount': 0.0,
        'paymentMethod': 'Cash',
        'status': 'Completed',
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
    return _salesReport.where((report) {
      final customerMatch =
          _selectedVendor == 'All' || report['vendor'] == _selectedVendor;
      final billerMatch =
          _selectedBiller == 'All' || report['biller'] == _selectedBiller;

      // Date filtering
      bool dateMatch = true;
      if (_startDate != null && _endDate != null) {
        dateMatch =
            report['date'].isAfter(
              _startDate!.subtract(const Duration(days: 1)),
            ) &&
            report['date'].isBefore(_endDate!.add(const Duration(days: 1)));
      } else if (_selectedPeriod == 'Last 7 Days') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        dateMatch = report['date'].isAfter(sevenDaysAgo);
      } else if (_selectedPeriod == 'Last 30 Days') {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        dateMatch = report['date'].isAfter(thirtyDaysAgo);
      }

      return customerMatch && billerMatch && dateMatch;
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
                  'Total Sales',
                  'Rs. ${_calculateTotal('grandTotal').toStringAsFixed(2)}',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Total Paid',
                  'Rs. ${_calculateTotal('paidAmount').toStringAsFixed(2)}',
                  Icons.payments,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Due',
                  'Rs. ${_calculateTotal('dueAmount').toStringAsFixed(2)}',
                  Icons.pending,
                  Colors.orange,
                ),
                _buildSummaryCard(
                  'Total Tax',
                  'Rs. ${_calculateTotal('tax').toStringAsFixed(2)}',
                  Icons.account_balance,
                  Colors.purple,
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
                                    [
                                          'Last 7 Days',
                                          'Last 30 Days',
                                          'Custom Range',
                                        ]
                                        .map(
                                          (period) => DropdownMenuItem(
                                            value: period,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  period == 'Custom Range'
                                                      ? Icons.calendar_today
                                                      : Icons.schedule,
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
                                      if (value != 'Custom Range') {
                                        _startDate = null;
                                        _endDate = null;
                                      }
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
                                          'Carl Evans',
                                          'Minerva Rameriz',
                                          'Robert Lamon',
                                          'Mark Joslyn',
                                          'Patricia Lewis',
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
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Reference')),
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Biller')),
                        DataColumn(label: Text('Items')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Subtotal')),
                        DataColumn(label: Text('Tax')),
                        DataColumn(label: Text('Discount')),
                        DataColumn(label: Text('Grand Total')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Due')),
                        DataColumn(label: Text('Payment Method')),
                        DataColumn(label: Text('Status')),
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
                                      Icons.person,
                                      color: Color(0xFF0D1845),
                                      size: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(report['vendor']),
                                ],
                              ),
                            ),
                            DataCell(Text(report['biller'])),
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

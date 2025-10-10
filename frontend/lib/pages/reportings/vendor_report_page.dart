import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VendorReportPage extends StatefulWidget {
  const VendorReportPage({super.key});

  @override
  State<VendorReportPage> createState() => _VendorReportPageState();
}

class _VendorReportPageState extends State<VendorReportPage> {
  // Mock data for vendor report
  List<Map<String, dynamic>> _vendorReport = [];
  List<Map<String, dynamic>> _selectedReports = [];
  bool _selectAll = false;

  // Filter states
  String _selectedStatus = 'All';
  String _sortBy = 'Total Orders';

  @override
  void initState() {
    super.initState();
    _loadMockVendorReport();
  }

  void _loadMockVendorReport() {
    // Mock vendor report data
    _vendorReport = [
      {
        'id': '1',
        'vendorName': 'Carl Evans',
        'email': 'carl.evans@email.com',
        'phone': '+1-555-0123',
        'totalOrders': 15,
        'totalSpent': 22500.0,
        'averageOrder': 1500.0,
        'lastOrder': DateTime(2025, 10, 8),
        'status': 'Paid',
        'registrationDate': DateTime(2025, 1, 15),
        'city': 'New York',
      },
      {
        'id': '2',
        'vendorName': 'Minerva Rameriz',
        'email': 'minerva.ramirez@email.com',
        'phone': '+1-555-0124',
        'totalOrders': 8,
        'totalSpent': 12000.0,
        'averageOrder': 1500.0,
        'lastOrder': DateTime(2025, 10, 7),
        'status': 'Paid',
        'registrationDate': DateTime(2025, 2, 20),
        'city': 'Los Angeles',
      },
      {
        'id': '3',
        'vendorName': 'Robert Lamon',
        'email': 'robert.lamon@email.com',
        'phone': '+1-555-0125',
        'totalOrders': 12,
        'totalSpent': 18000.0,
        'averageOrder': 1500.0,
        'lastOrder': DateTime(2025, 10, 6),
        'status': 'Paid',
        'registrationDate': DateTime(2025, 3, 10),
        'city': 'Chicago',
      },
      {
        'id': '4',
        'vendorName': 'Patricia Lewis',
        'email': 'patricia.lewis@email.com',
        'phone': '+1-555-0126',
        'totalOrders': 6,
        'totalSpent': 9000.0,
        'averageOrder': 1500.0,
        'lastOrder': DateTime(2025, 10, 4),
        'status': 'Unpaid',
        'registrationDate': DateTime(2025, 4, 5),
        'city': 'Houston',
      },
      {
        'id': '5',
        'vendorName': 'Daniel Jude',
        'email': 'daniel.jude@email.com',
        'phone': '+1-555-0127',
        'totalOrders': 10,
        'totalSpent': 15000.0,
        'averageOrder': 1500.0,
        'lastOrder': DateTime(2025, 10, 3),
        'status': 'Paid',
        'registrationDate': DateTime(2025, 5, 12),
        'city': 'Phoenix',
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
    List<Map<String, dynamic>> filtered = _vendorReport.where((report) {
      final statusMatch =
          _selectedStatus == 'All' || report['status'] == _selectedStatus;

      return statusMatch;
    }).toList();

    // Sort based on selected criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Total Orders':
          return b['totalOrders'].compareTo(a['totalOrders']);
        case 'Total Spent':
          return b['totalSpent'].compareTo(a['totalSpent']);
        case 'Vendor Name':
          return a['vendorName'].compareTo(b['vendorName']);
        case 'Last Order':
          return b['lastOrder'].compareTo(a['lastOrder']);
        default:
          return a['vendorName'].compareTo(b['vendorName']);
      }
    });

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Unpaid':
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
                      Icons.people,
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
                          'Vendor Report',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vendor analytics, purchase history, and behavior insights',
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
                  'Total Vendors',
                  '${filteredReports.length}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Paid Vendors',
                  '${filteredReports.where((r) => r['status'] == 'Paid').length}',
                  Icons.person,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Revenue',
                  'Rs. ${_calculateTotal('totalSpent').toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Avg. Order Value',
                  'Rs. ${(_calculateTotal('totalSpent') / _calculateTotalInt('totalOrders')).toStringAsFixed(2)}',
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
                                    'Vendor Status',
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
                                items: ['All', 'Paid', 'Unpaid']
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Row(
                                          children: [
                                            Icon(
                                              status == 'All'
                                                  ? Icons.group
                                                  : status == 'Paid'
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color: status == 'All'
                                                  ? Color(0xFF6C757D)
                                                  : status == 'Paid'
                                                  ? Color(0xFF28A745)
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
                                          'Total Orders',
                                          'Total Spent',
                                          'Vendor Name',
                                          'Last Order',
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
                        Icon(Icons.people, color: Color(0xFF0D1845), size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Vendor Details',
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
                                Icons.person,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${filteredReports.length} Vendors',
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
                      dataRowHeight: 80.0,
                      columnSpacing: 20.0,
                      columns: const [
                        DataColumn(label: Text('Select')),
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('City')),
                        DataColumn(label: Text('Total Orders')),
                        DataColumn(label: Text('Total Spent')),
                        DataColumn(label: Text('Avg. Order')),
                        DataColumn(label: Text('Last Order')),
                        DataColumn(label: Text('Registration')),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (value) =>
                                      _toggleReportSelection(report),
                                  activeColor: Color(0xFF0D1845),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF0D1845,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Color(0xFF0D1845),
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      report['vendorName'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(report['email']),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(report['phone']),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(report['city']),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  report['totalOrders'].toString(),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  'Rs. ${report['totalSpent'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF28A745),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  'Rs. ${report['averageOrder'].toStringAsFixed(2)}',
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(report['lastOrder']),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(report['registrationDate']),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
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
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.visibility,
                                        color: Color(0xFF0D1845),
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        // TODO: Implement view customer details
                                      },
                                      tooltip: 'View Details',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.email,
                                        color: Color(0xFF007BFF),
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        // TODO: Implement send email
                                      },
                                      tooltip: 'Send Email',
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

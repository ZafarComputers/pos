import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceReportPage extends StatefulWidget {
  const InvoiceReportPage({super.key});

  @override
  State<InvoiceReportPage> createState() => _InvoiceReportPageState();
}

class _InvoiceReportPageState extends State<InvoiceReportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedPeriod = 'Today';
  String _selectedVendor = 'All Vendors';
  String _selectedBiller = 'All Billers';
  String _selectedStatus = 'All Status';

  final List<String> _periods = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];
  final List<String> _vendors = [
    'All Vendors',
    'John Doe',
    'Jane Smith',
    'Bob Johnson',
    'Alice Brown',
  ];
  final List<String> _billers = [
    'All Billers',
    'Biller 1',
    'Biller 2',
    'Biller 3',
  ];
  final List<String> _statuses = [
    'All Status',
    'Paid',
    'Unpaid',
    'Partial',
    'Overdue',
  ];

  final List<Map<String, dynamic>> _invoiceData = [
    {
      'invoiceNo': 'INV-001',
      'date': '2024-01-15',
      'vendor': 'John Doe',
      'biller': 'Biller 1',
      'total': 1250.00,
      'paid': 1250.00,
      'due': 0.00,
      'status': 'Paid',
      'paymentMethod': 'Cash',
    },
    {
      'invoiceNo': 'INV-002',
      'date': '2024-01-14',
      'vendor': 'Jane Smith',
      'biller': 'Biller 2',
      'total': 890.50,
      'paid': 445.25,
      'due': 445.25,
      'status': 'Partial',
      'paymentMethod': 'Card',
    },
    {
      'invoiceNo': 'INV-003',
      'date': '2024-01-13',
      'vendor': 'Bob Johnson',
      'biller': 'Biller 1',
      'total': 2100.75,
      'paid': 0.00,
      'due': 2100.75,
      'status': 'Unpaid',
      'paymentMethod': 'Bank Transfer',
    },
    {
      'invoiceNo': 'INV-004',
      'date': '2024-01-12',
      'vendor': 'Alice Brown',
      'biller': 'Biller 3',
      'total': 675.25,
      'paid': 675.25,
      'due': 0.00,
      'status': 'Paid',
      'paymentMethod': 'Cash',
    },
    {
      'invoiceNo': 'INV-005',
      'date': '2024-01-11',
      'vendor': 'John Doe',
      'biller': 'Biller 2',
      'total': 1540.00,
      'paid': 770.00,
      'due': 770.00,
      'status': 'Partial',
      'paymentMethod': 'Cheque',
    },
  ];

  List<Map<String, dynamic>> get _filteredData {
    return _invoiceData.where((invoice) {
      final matchesSearch =
          invoice['invoiceNo'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          invoice['vendor'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
      final matchesCustomer =
          _selectedVendor == 'All Vendors' ||
          invoice['vendor'] == _selectedVendor;
      final matchesBiller =
          _selectedBiller == 'All Billers' ||
          invoice['biller'] == _selectedBiller;
      final matchesStatus =
          _selectedStatus == 'All Status' ||
          invoice['status'] == _selectedStatus;

      return matchesSearch && matchesCustomer && matchesBiller && matchesStatus;
    }).toList();
  }

  double get _totalInvoices => _filteredData.length.toDouble();
  double get _totalAmount =>
      _filteredData.fold(0.0, (sum, invoice) => sum + invoice['total']);
  double get _totalPaid =>
      _filteredData.fold(0.0, (sum, invoice) => sum + invoice['paid']);
  double get _totalDue =>
      _filteredData.fold(0.0, (sum, invoice) => sum + invoice['due']);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Unpaid':
        return Colors.red;
      case 'Partial':
        return Colors.orange;
      case 'Overdue':
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      Icons.receipt_long,
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
                          'Invoice Report',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comprehensive invoice analytics and reporting',
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
                  'Total Invoices',
                  _totalInvoices.toInt().toString(),
                  Icons.receipt,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Total Amount',
                  'Rs. ${NumberFormat('#,##0.00').format(_totalAmount)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Paid',
                  'Rs. ${NumberFormat('#,##0.00').format(_totalPaid)}',
                  Icons.payment,
                  Colors.orange,
                ),
                _buildSummaryCard(
                  'Total Due',
                  'Rs. ${NumberFormat('#,##0.00').format(_totalDue)}',
                  Icons.pending,
                  Colors.red,
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
                                items: _periods
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
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Customer Filter
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
                                items: _vendors
                                    .map(
                                      (vendor) => DropdownMenuItem(
                                        value: vendor,
                                        child: Row(
                                          children: [
                                            Icon(
                                              vendor == 'All Vendors'
                                                  ? Icons.group
                                                  : Icons.person,
                                              color: vendor == 'All Vendors'
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Biller Filter
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
                                    'Biller',
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
                                value: _selectedBiller,
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
                                items: _billers
                                    .map(
                                      (biller) => DropdownMenuItem(
                                        value: biller,
                                        child: Row(
                                          children: [
                                            Icon(
                                              biller == 'All Billers'
                                                  ? Icons.business_center
                                                  : Icons.business,
                                              color: biller == 'All Billers'
                                                  ? Color(0xFF6C757D)
                                                  : Color(0xFF0D1845),
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              biller,
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
                                      _selectedBiller = value;
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
                                    Icons.flag,
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
                                items: _statuses
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Row(
                                          children: [
                                            Icon(
                                              status == 'All Status'
                                                  ? Icons.list
                                                  : Icons.flag,
                                              color: status == 'All Status'
                                                  ? Color(0xFF6C757D)
                                                  : Color(0xFF0D1845),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by invoice number or vendor...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF0D1845),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFF0D1845),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
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
                        Icon(
                          Icons.receipt_long,
                          color: Color(0xFF0D1845),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Invoice Report Details',
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
                                '${_filteredData.length} Records',
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
                      dataRowHeight: 120.0,
                      columnSpacing: 40.0,
                      columns: const [
                        DataColumn(label: Text('Invoice No')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Biller')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Due')),
                        DataColumn(label: Text('Payment Method')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: _filteredData.map((invoice) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  invoice['invoiceNo'],
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(DateTime.parse(invoice['date'])),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF0D1845,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Color(0xFF0D1845),
                                        size: 12,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(invoice['vendor']),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(invoice['biller']),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  'Rs. ${NumberFormat('#,##0.00').format(invoice['total'])}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  'Rs. ${NumberFormat('#,##0.00').format(invoice['paid'])}',
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(
                                  'Rs. ${NumberFormat('#,##0.00').format(invoice['due'])}',
                                ),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Text(invoice['paymentMethod']),
                              ),
                            ),
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40.0,
                                  horizontal: 12.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      invoice['status'],
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    invoice['status'],
                                    style: TextStyle(
                                      color: _getStatusColor(invoice['status']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
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

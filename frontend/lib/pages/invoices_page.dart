import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  // Mock data for demonstration - in real app this would come from API
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _selectedInvoices = [];
  bool _selectAll = false;

  // Filter states
  String _selectedCustomer = 'All';
  String _selectedStatus = 'All';
  String _sortBy = 'Last 7 Days';

  @override
  void initState() {
    super.initState();
    _loadMockInvoices();
  }

  void _loadMockInvoices() {
    // Mock invoices data with comprehensive dummy data
    _invoices = [
      {
        'id': '1',
        'invoiceNo': 'INV-2025-001',
        'customer': 'Carl Evans',
        'dueDate': DateTime(2025, 10, 15),
        'amount': 2500.0,
        'paid': 2500.0,
        'amountDue': 0.0,
        'status': 'Paid',
      },
      {
        'id': '2',
        'invoiceNo': 'INV-2025-002',
        'customer': 'Minerva Rameriz',
        'dueDate': DateTime(2025, 10, 12),
        'amount': 1800.0,
        'paid': 900.0,
        'amountDue': 900.0,
        'status': 'Partial',
      },
      {
        'id': '3',
        'invoiceNo': 'INV-2025-003',
        'customer': 'Robert Lamon',
        'dueDate': DateTime(2025, 10, 10),
        'amount': 3200.0,
        'paid': 3200.0,
        'amountDue': 0.0,
        'status': 'Paid',
      },
      {
        'id': '4',
        'invoiceNo': 'INV-2025-004',
        'customer': 'Mark Joslyn',
        'dueDate': DateTime(2025, 10, 8),
        'amount': 1500.0,
        'paid': 0.0,
        'amountDue': 1500.0,
        'status': 'Unpaid',
      },
      {
        'id': '5',
        'invoiceNo': 'INV-2025-005',
        'customer': 'Patricia Lewis',
        'dueDate': DateTime(2025, 10, 5),
        'amount': 950.0,
        'paid': 950.0,
        'amountDue': 0.0,
        'status': 'Paid',
      },
      {
        'id': '6',
        'invoiceNo': 'INV-2025-006',
        'customer': 'Daniel Jude',
        'dueDate': DateTime(2025, 10, 3),
        'amount': 2100.0,
        'paid': 1050.0,
        'amountDue': 1050.0,
        'status': 'Partial',
      },
      {
        'id': '7',
        'invoiceNo': 'INV-2025-007',
        'customer': 'Emma Bates',
        'dueDate': DateTime(2025, 10, 1),
        'amount': 1750.0,
        'paid': 1750.0,
        'amountDue': 0.0,
        'status': 'Paid',
      },
      {
        'id': '8',
        'invoiceNo': 'INV-2025-008',
        'customer': 'Richard Fralick',
        'dueDate': DateTime(2025, 9, 28),
        'amount': 2800.0,
        'paid': 1400.0,
        'amountDue': 1400.0,
        'status': 'Partial',
      },
      {
        'id': '9',
        'invoiceNo': 'INV-2025-009',
        'customer': 'Michelle Robison',
        'dueDate': DateTime(2025, 9, 25),
        'amount': 1200.0,
        'paid': 1200.0,
        'amountDue': 0.0,
        'status': 'Paid',
      },
      {
        'id': '10',
        'invoiceNo': 'INV-2025-010',
        'customer': 'Marsha Betts',
        'dueDate': DateTime(2025, 9, 22),
        'amount': 850.0,
        'paid': 0.0,
        'amountDue': 850.0,
        'status': 'Unpaid',
      },
      {
        'id': '11',
        'invoiceNo': 'INV-2025-011',
        'customer': 'John Smith',
        'dueDate': DateTime(2025, 9, 20),
        'amount': 1950.0,
        'paid': 1950.0,
        'amountDue': 0.0,
        'status': 'Paid',
      },
      {
        'id': '12',
        'invoiceNo': 'INV-2025-012',
        'customer': 'Sarah Johnson',
        'dueDate': DateTime(2025, 9, 18),
        'amount': 750.0,
        'paid': 0.0,
        'amountDue': 750.0,
        'status': 'Overdue',
      },
      {
        'id': '13',
        'invoiceNo': 'INV-2025-013',
        'customer': 'Mike Davis',
        'dueDate': DateTime(2025, 9, 15),
        'amount': 1650.0,
        'paid': 825.0,
        'amountDue': 825.0,
        'status': 'Partial',
      },
      {
        'id': '14',
        'invoiceNo': 'INV-2025-014',
        'customer': 'Lisa Wilson',
        'dueDate': DateTime(2025, 9, 12),
        'amount': 2200.0,
        'paid': 2200.0,
        'amountDue': 0.0,
        'status': 'Paid',
      },
      {
        'id': '15',
        'invoiceNo': 'INV-2025-015',
        'customer': 'Tom Brown',
        'dueDate': DateTime(2025, 9, 10),
        'amount': 1350.0,
        'paid': 0.0,
        'amountDue': 1350.0,
        'status': 'Unpaid',
      },
    ];
  }

  void _toggleInvoiceSelection(Map<String, dynamic> invoice) {
    setState(() {
      final invoiceId = invoice['id'];
      final existingIndex = _selectedInvoices.indexWhere(
        (i) => i['id'] == invoiceId,
      );

      if (existingIndex >= 0) {
        _selectedInvoices.removeAt(existingIndex);
      } else {
        _selectedInvoices.add(Map<String, dynamic>.from(invoice));
      }

      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedInvoices.clear();
      } else {
        _selectedInvoices = List.from(_getFilteredInvoices());
      }
      _selectAll = !_selectAll;
    });
  }

  void _updateSelectAllState() {
    final filteredInvoices = _getFilteredInvoices();
    _selectAll =
        filteredInvoices.isNotEmpty &&
        _selectedInvoices.length == filteredInvoices.length;
  }

  List<Map<String, dynamic>> _getFilteredInvoices() {
    return _invoices.where((invoice) {
      final customerMatch =
          _selectedCustomer == 'All' ||
          invoice['customer'] == _selectedCustomer;
      final statusMatch =
          _selectedStatus == 'All' || invoice['status'] == _selectedStatus;

      // Date filtering based on sortBy
      bool dateMatch = true;
      if (_sortBy == 'Last 7 Days') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        dateMatch = invoice['dueDate'].isAfter(sevenDaysAgo);
      }

      return customerMatch && statusMatch && dateMatch;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Unpaid':
        return Colors.red;
      case 'Partial':
        return Colors.orange;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvoices = _getFilteredInvoices();

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
            // Enhanced Header - Matching Product List Page Design
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
                          'Invoices',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and track all customer invoices',
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
                      // TODO: Implement create invoice functionality
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Invoice'),
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

            // Enhanced Filters Section - Matching Product List Page Design
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
                      // Customer Filter
                      Expanded(
                        flex: 2,
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
                                    'Filter by Customer',
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
                                value: _selectedCustomer,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Select customer',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFADB5BD),
                                    fontSize: 14,
                                  ),
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
                                          'Daniel Jude',
                                          'Emma Bates',
                                          'Richard Fralick',
                                          'Michelle Robison',
                                          'Marsha Betts',
                                          'John Smith',
                                          'Sarah Johnson',
                                          'Mike Davis',
                                          'Lisa Wilson',
                                          'Tom Brown',
                                        ]
                                        .map(
                                          (customer) => DropdownMenuItem(
                                            value: customer,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  customer == 'All'
                                                      ? Icons.group
                                                      : Icons.person,
                                                  color: customer == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : Color(0xFF0D1845),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  customer,
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
                                      _selectedCustomer = value;
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
                        flex: 2,
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
                                    'Filter by Status',
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
                                  hintText: 'Select status',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFADB5BD),
                                    fontSize: 14,
                                  ),
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
                                          'Paid',
                                          'Unpaid',
                                          'Partial',
                                          'Overdue',
                                        ]
                                        .map(
                                          (status) => DropdownMenuItem(
                                            value: status,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  status == 'All'
                                                      ? Icons.receipt_long
                                                      : status == 'Paid'
                                                      ? Icons.check_circle
                                                      : status == 'Unpaid'
                                                      ? Icons.cancel
                                                      : status == 'Partial'
                                                      ? Icons.pie_chart
                                                      : Icons.warning,
                                                  color: status == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : status == 'Paid'
                                                      ? Color(0xFF28A745)
                                                      : status == 'Unpaid'
                                                      ? Color(0xFFDC3545)
                                                      : status == 'Partial'
                                                      ? Color(0xFFFFA726)
                                                      : Color(0xFFFF5722),
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

            // Enhanced Table Section - Matching Product List Page Design
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
                          Icons.receipt_long,
                          color: Color(0xFF0D1845),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Invoices List',
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
                                Icons.receipt_long,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${filteredInvoices.length} Invoices',
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
                        DataColumn(label: Text('Invoice No.')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Due Date')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Amount Due')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredInvoices.map((invoice) {
                        final isSelected = _selectedInvoices.any(
                          (i) => i['id'] == invoice['id'],
                        );
                        return DataRow(
                          selected: isSelected,
                          cells: [
                            DataCell(
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _toggleInvoiceSelection(invoice),
                                activeColor: Color(0xFF0D1845),
                              ),
                            ),
                            DataCell(Text(invoice['invoiceNo'])),
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
                                      Icons.person,
                                      color: Color(0xFF0D1845),
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(invoice['customer']),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(invoice['dueDate']),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${invoice['amount'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text('Rs. ${invoice['paid'].toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${invoice['amountDue'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
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
                                      // TODO: Implement view invoice details
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
                                      // TODO: Implement edit invoice
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.print,
                                      color: Color(0xFF28A745),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement print invoice
                                    },
                                    tooltip: 'Print',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.email,
                                      color: Color(0xFFFFA726),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement send invoice via email
                                    },
                                    tooltip: 'Send Email',
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
}

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

  // Filter states
  String _selectedTimeFilter = 'All'; // Day, Month, Year, All

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
        'customerType': 'Normal',
        'date': DateTime(2025, 10, 15),
        'totalAmount': 2500.0,
        'paidAmount': 2500.0,
        'dueAmount': 0.0,
        'status': 'Paid',
        'products': [
          {'name': 'Wireless Headphones', 'quantity': 1, 'price': 2500.0},
        ],
      },
      {
        'id': '2',
        'invoiceNo': 'INV-2025-002',
        'customer': 'Minerva Rameriz',
        'customerType': 'Credit',
        'date': DateTime(2025, 10, 12),
        'totalAmount': 1800.0,
        'paidAmount': 900.0,
        'dueAmount': 900.0,
        'status': 'Partial',
        'products': [
          {'name': 'Bluetooth Speaker', 'quantity': 2, 'price': 900.0},
        ],
      },
      {
        'id': '3',
        'invoiceNo': 'INV-2025-003',
        'customer': 'Robert Lamon',
        'customerType': 'Normal',
        'date': DateTime(2025, 10, 10),
        'totalAmount': 3200.0,
        'paidAmount': 3200.0,
        'dueAmount': 0.0,
        'status': 'Paid',
        'products': [
          {'name': 'Gaming Laptop', 'quantity': 1, 'price': 3200.0},
        ],
      },
      {
        'id': '4',
        'invoiceNo': 'INV-2025-004',
        'customer': 'Mark Joslyn',
        'customerType': 'Credit',
        'date': DateTime(2025, 10, 8),
        'totalAmount': 1500.0,
        'paidAmount': 0.0,
        'dueAmount': 1500.0,
        'status': 'Unpaid',
        'products': [
          {'name': 'Mechanical Keyboard', 'quantity': 1, 'price': 1500.0},
        ],
      },
      {
        'id': '5',
        'invoiceNo': 'INV-2025-005',
        'customer': 'Patricia Lewis',
        'customerType': 'Normal',
        'date': DateTime(2025, 10, 5),
        'totalAmount': 950.0,
        'paidAmount': 950.0,
        'dueAmount': 0.0,
        'status': 'Paid',
        'products': [
          {'name': 'USB Cable', 'quantity': 3, 'price': 316.67},
        ],
      },
      {
        'id': '6',
        'invoiceNo': 'INV-2025-006',
        'customer': 'Daniel Jude',
        'customerType': 'Credit',
        'date': DateTime(2025, 10, 3),
        'totalAmount': 2100.0,
        'paidAmount': 1050.0,
        'dueAmount': 1050.0,
        'status': 'Partial',
        'products': [
          {'name': 'Wireless Mouse', 'quantity': 2, 'price': 1050.0},
        ],
      },
      {
        'id': '7',
        'invoiceNo': 'INV-2025-007',
        'customer': 'Emma Bates',
        'customerType': 'Normal',
        'date': DateTime(2025, 10, 1),
        'totalAmount': 1750.0,
        'paidAmount': 1750.0,
        'dueAmount': 0.0,
        'status': 'Paid',
        'products': [
          {'name': 'Monitor Stand', 'quantity': 1, 'price': 1750.0},
        ],
      },
      {
        'id': '8',
        'invoiceNo': 'INV-2025-008',
        'customer': 'Richard Fralick',
        'customerType': 'Credit',
        'date': DateTime(2025, 9, 28),
        'totalAmount': 2800.0,
        'paidAmount': 1400.0,
        'dueAmount': 1400.0,
        'status': 'Partial',
        'products': [
          {'name': 'External SSD', 'quantity': 1, 'price': 2800.0},
        ],
      },
      {
        'id': '9',
        'invoiceNo': 'INV-2025-009',
        'customer': 'Michelle Robison',
        'customerType': 'Normal',
        'date': DateTime(2025, 9, 25),
        'totalAmount': 1200.0,
        'paidAmount': 1200.0,
        'dueAmount': 0.0,
        'status': 'Paid',
        'products': [
          {'name': 'Phone Case', 'quantity': 4, 'price': 300.0},
        ],
      },
      {
        'id': '10',
        'invoiceNo': 'INV-2025-010',
        'customer': 'Marsha Betts',
        'customerType': 'Credit',
        'date': DateTime(2025, 9, 22),
        'totalAmount': 850.0,
        'paidAmount': 0.0,
        'dueAmount': 850.0,
        'status': 'Unpaid',
        'products': [
          {'name': 'Screen Protector', 'quantity': 5, 'price': 170.0},
        ],
      },
      {
        'id': '11',
        'invoiceNo': 'INV-2025-011',
        'customer': 'John Smith',
        'customerType': 'Normal',
        'date': DateTime(2025, 9, 20),
        'totalAmount': 1950.0,
        'paidAmount': 1950.0,
        'dueAmount': 0.0,
        'status': 'Paid',
        'products': [
          {'name': 'Power Bank', 'quantity': 3, 'price': 650.0},
        ],
      },
      {
        'id': '12',
        'invoiceNo': 'INV-2025-012',
        'customer': 'Sarah Johnson',
        'customerType': 'Credit',
        'date': DateTime(2025, 9, 18),
        'totalAmount': 750.0,
        'paidAmount': 0.0,
        'dueAmount': 750.0,
        'status': 'Overdue',
        'products': [
          {'name': 'Earphone Case', 'quantity': 5, 'price': 150.0},
        ],
      },
      {
        'id': '13',
        'invoiceNo': 'INV-2025-013',
        'customer': 'Mike Davis',
        'customerType': 'Normal',
        'date': DateTime(2025, 9, 15),
        'totalAmount': 1650.0,
        'paidAmount': 825.0,
        'dueAmount': 825.0,
        'status': 'Partial',
        'products': [
          {'name': 'Cable Organizer', 'quantity': 6, 'price': 275.0},
        ],
      },
      {
        'id': '14',
        'invoiceNo': 'INV-2025-014',
        'customer': 'Lisa Wilson',
        'customerType': 'Credit',
        'date': DateTime(2025, 9, 12),
        'totalAmount': 2200.0,
        'paidAmount': 2200.0,
        'dueAmount': 0.0,
        'status': 'Paid',
        'products': [
          {'name': 'Tablet Stand', 'quantity': 2, 'price': 1100.0},
        ],
      },
      {
        'id': '15',
        'invoiceNo': 'INV-2025-015',
        'customer': 'Tom Brown',
        'customerType': 'Normal',
        'date': DateTime(2025, 9, 10),
        'totalAmount': 1350.0,
        'paidAmount': 0.0,
        'dueAmount': 1350.0,
        'status': 'Unpaid',
        'products': [
          {'name': 'Phone Holder', 'quantity': 9, 'price': 150.0},
        ],
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredInvoices() {
    return _invoices.where((invoice) {
      // Date filtering based on time filter
      bool dateMatch = true;
      final now = DateTime.now();
      if (_selectedTimeFilter == 'Day') {
        dateMatch = invoice['date'].year == now.year &&
                   invoice['date'].month == now.month &&
                   invoice['date'].day == now.day;
      } else if (_selectedTimeFilter == 'Month') {
        dateMatch = invoice['date'].year == now.year &&
                   invoice['date'].month == now.month;
      } else if (_selectedTimeFilter == 'Year') {
        dateMatch = invoice['date'].year == now.year;
      }

      return dateMatch;
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

  void _viewInvoiceDetails(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              invoice['invoiceNo'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Info
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D1845),
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.person, color: Color(0xFF0D1845), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    invoice['customer'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: invoice['customerType'] == 'Credit' 
                                        ? Color(0xFFFFA726).withOpacity(0.1)
                                        : Color(0xFF28A745).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      invoice['customerType'],
                                      style: TextStyle(
                                        color: invoice['customerType'] == 'Credit' 
                                          ? Color(0xFFFFA726)
                                          : Color(0xFF28A745),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Color(0xFF0D1845), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(invoice['date']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Products
                        Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1845),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Product',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Price',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Products List
                              ...(invoice['products'] as List).map((product) {
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          product['name'],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          product['quantity'].toString(),
                                          style: TextStyle(fontSize: 14),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Rs. ${product['price'].toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 14),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Rs. ${(product['quantity'] * product['price']).toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 14),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Amount Summary
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${invoice['totalAmount'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Paid Amount:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${invoice['paidAmount'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Due Amount:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: invoice['dueAmount'] > 0 ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${invoice['dueAmount'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: invoice['dueAmount'] > 0 ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Divider(),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(invoice['status']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      invoice['status'],
                                      style: TextStyle(
                                        color: _getStatusColor(invoice['status']),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Close'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Navigate to POS page to add more products to this invoice
                                Navigator.pushNamed(context, '/pos');
                              },
                              icon: Icon(Icons.add_shopping_cart, size: 16),
                              label: Text('Add to Invoice'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0D1845),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                      // Time Filter
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
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFF0D1845),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Filter by Time',
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
                                value: _selectedTimeFilter,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Select time period',
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
                                items: ['All', 'Day', 'Month', 'Year']
                                    .map(
                                      (filter) => DropdownMenuItem(
                                        value: filter,
                                        child: Row(
                                          children: [
                                            Icon(
                                              filter == 'All'
                                                  ? Icons.calendar_view_month
                                                  : filter == 'Day'
                                                  ? Icons.today
                                                  : filter == 'Month'
                                                  ? Icons.calendar_view_month
                                                  : Icons.calendar_today,
                                              color: filter == 'All'
                                                  ? Color(0xFF6C757D)
                                                  : Color(0xFF0D1845),
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              filter,
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
                                      _selectedTimeFilter = value;
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
                        DataColumn(label: Text('Invoice Number')),
                        DataColumn(label: Text('Customer Name')),
                        DataColumn(label: Text('Customer Type')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Total Amount')),
                        DataColumn(label: Text('Paid Amount')),
                        DataColumn(label: Text('Due Amount')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('View')),
                      ],
                      rows: filteredInvoices.map((invoice) {
                        return DataRow(
                          cells: [
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: invoice['customerType'] == 'Credit' 
                                    ? Color(0xFFFFA726).withOpacity(0.1)
                                    : Color(0xFF28A745).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  invoice['customerType'],
                                  style: TextStyle(
                                    color: invoice['customerType'] == 'Credit' 
                                      ? Color(0xFFFFA726)
                                      : Color(0xFF28A745),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(invoice['date']),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${invoice['totalAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${invoice['paidAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${invoice['dueAmount'].toStringAsFixed(2)}',
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
                              IconButton(
                                icon: Icon(
                                  Icons.visibility,
                                  color: Color(0xFF0D1845),
                                  size: 18,
                                ),
                                onPressed: () => _viewInvoiceDetails(invoice),
                                tooltip: 'View Details',
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesReturnPage extends StatefulWidget {
  const SalesReturnPage({super.key});

  @override
  State<SalesReturnPage> createState() => _SalesReturnPageState();
}

class _SalesReturnPageState extends State<SalesReturnPage> {
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _returnReasonController = TextEditingController();

  // Mock data for demonstration - in real app this would come from API
  List<Map<String, dynamic>> _salesReturns = [];
  List<Map<String, dynamic>> _selectedProducts = [];
  bool _isSubmittingReturn = false;
  bool _showAddReturnDialog = false;

  // Filter states
  String _selectedCustomer = 'All';
  String _selectedStatus = 'All';
  String _selectedPaymentStatus = 'All';
  String _sortBy = 'Last 7 Days';

  // New state variables for the updated form
  String _selectedCustomerType = 'Normal Customer';
  DateTime _selectedReturnDate = DateTime.now();
  List<Map<String, dynamic>> _invoiceProducts = [];
  bool _isLoadingInvoice = false;
  String _invoiceError = '';

  @override
  void initState() {
    super.initState();
    _loadMockSalesReturns();
  }

  @override
  void dispose() {
    _returnReasonController.dispose();
    _cnicController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  void _loadMockSalesReturns() {
    // Mock sales returns data based on Dreamspos website structure with comprehensive dummy data
    _salesReturns = [
      {
        'id': '1',
        'product': {'name': 'Lenovo IdeaPad 3', 'image': null},
        'date': DateTime(2025, 10, 2),
        'customer': 'Carl Evans',
        'status': 'Accepted',
        'grandTotal': 1000.0,
        'paidAmount': 1000.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '2',
        'product': {'name': 'Apple tablet', 'image': null},
        'date': DateTime(2025, 10, 3),
        'customer': 'Minerva Rameriz',
        'status': 'Pending',
        'grandTotal': 1500.0,
        'paidAmount': 0.0,
        'dueAmount': 1500.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '3',
        'product': {'name': 'Headphone', 'image': null},
        'date': DateTime(2025, 10, 4),
        'customer': 'Robert Lamon',
        'status': 'Completed',
        'grandTotal': 2000.0,
        'paidAmount': 1000.0,
        'dueAmount': 1000.0,
        'paymentStatus': 'Overdue',
      },
      {
        'id': '4',
        'product': {'name': 'Nike Jordan', 'image': null},
        'date': DateTime(2025, 10, 1),
        'customer': 'Mark Joslyn',
        'status': 'Accepted',
        'grandTotal': 1500.0,
        'paidAmount': 1500.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '5',
        'product': {'name': 'Macbook Pro', 'image': null},
        'date': DateTime(2025, 9, 28),
        'customer': 'Patricia Lewis',
        'status': 'Accepted',
        'grandTotal': 800.0,
        'paidAmount': 800.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '6',
        'product': {'name': 'Apple Earpods', 'image': null},
        'date': DateTime(2025, 9, 25),
        'customer': 'Daniel Jude',
        'status': 'Accepted',
        'grandTotal': 1300.0,
        'paidAmount': 1300.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '7',
        'product': {'name': 'Iphone 14 Pro', 'image': null},
        'date': DateTime(2025, 9, 22),
        'customer': 'Emma Bates',
        'status': 'Accepted',
        'grandTotal': 1100.0,
        'paidAmount': 1100.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '8',
        'product': {'name': 'Gaming Chair', 'image': null},
        'date': DateTime(2025, 9, 20),
        'customer': 'Richard Fralick',
        'status': 'Pending',
        'grandTotal': 2300.0,
        'paidAmount': 2300.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '9',
        'product': {'name': 'Borealis Backpack', 'image': null},
        'date': DateTime(2025, 9, 18),
        'customer': 'Michelle Robison',
        'status': 'Pending',
        'grandTotal': 1700.0,
        'paidAmount': 1700.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '10',
        'product': {'name': 'Red Premium Satchel', 'image': null},
        'date': DateTime(2025, 9, 15),
        'customer': 'Marsha Betts',
        'status': 'Rejected',
        'grandTotal': 750.0,
        'paidAmount': 0.0,
        'dueAmount': 750.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '11',
        'product': {'name': 'Samsung Galaxy S23', 'image': null},
        'date': DateTime(2025, 9, 12),
        'customer': 'John Smith',
        'status': 'Completed',
        'grandTotal': 1200.0,
        'paidAmount': 600.0,
        'dueAmount': 600.0,
        'paymentStatus': 'Overdue',
      },
      {
        'id': '12',
        'product': {'name': 'Dell XPS 13', 'image': null},
        'date': DateTime(2025, 9, 10),
        'customer': 'Sarah Johnson',
        'status': 'Accepted',
        'grandTotal': 1800.0,
        'paidAmount': 1800.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '13',
        'product': {'name': 'Sony WH-1000XM5', 'image': null},
        'date': DateTime(2025, 9, 8),
        'customer': 'Mike Davis',
        'status': 'Pending',
        'grandTotal': 350.0,
        'paidAmount': 0.0,
        'dueAmount': 350.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '14',
        'product': {'name': 'iPad Air', 'image': null},
        'date': DateTime(2025, 9, 5),
        'customer': 'Lisa Wilson',
        'status': 'Accepted',
        'grandTotal': 600.0,
        'paidAmount': 600.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '15',
        'product': {'name': 'Logitech MX Master 3', 'image': null},
        'date': DateTime(2025, 9, 3),
        'customer': 'Tom Brown',
        'status': 'Rejected',
        'grandTotal': 100.0,
        'paidAmount': 0.0,
        'dueAmount': 100.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '16',
        'product': {'name': 'ASUS ROG Strix G15', 'image': null},
        'date': DateTime(2025, 9, 1),
        'customer': 'Alex Chen',
        'status': 'Accepted',
        'grandTotal': 2500.0,
        'paidAmount': 2500.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '17',
        'product': {'name': 'Microsoft Surface Pro 9', 'image': null},
        'date': DateTime(2025, 8, 28),
        'customer': 'Jessica Taylor',
        'status': 'Completed',
        'grandTotal': 1400.0,
        'paidAmount': 700.0,
        'dueAmount': 700.0,
        'paymentStatus': 'Overdue',
      },
      {
        'id': '18',
        'product': {'name': 'Razer DeathAdder V3', 'image': null},
        'date': DateTime(2025, 8, 25),
        'customer': 'Kevin Martinez',
        'status': 'Pending',
        'grandTotal': 80.0,
        'paidAmount': 0.0,
        'dueAmount': 80.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '19',
        'product': {'name': 'Samsung 4K Monitor', 'image': null},
        'date': DateTime(2025, 8, 22),
        'customer': 'Amanda Garcia',
        'status': 'Accepted',
        'grandTotal': 400.0,
        'paidAmount': 400.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '20',
        'product': {'name': 'WD External SSD 1TB', 'image': null},
        'date': DateTime(2025, 8, 20),
        'customer': 'David Rodriguez',
        'status': 'Rejected',
        'grandTotal': 150.0,
        'paidAmount': 0.0,
        'dueAmount': 150.0,
        'paymentStatus': 'Unpaid',
      },
    ];
  }

  Future<void> _fetchInvoiceDetails() async {
    final invoiceNumber = _invoiceNumberController.text.trim();
    if (invoiceNumber.isEmpty) {
      setState(() {
        _invoiceError = 'Please enter an invoice number';
        _invoiceProducts.clear();
      });
      return;
    }

    if (_selectedCustomerType == 'Credit Customer') {
      final cnic = _cnicController.text.trim();
      if (cnic.isEmpty) {
        setState(() {
          _invoiceError = 'Please enter customer CNIC';
          _invoiceProducts.clear();
        });
        return;
      }
    }

    setState(() {
      _isLoadingInvoice = true;
      _invoiceError = '';
      _invoiceProducts.clear();
      _selectedProducts.clear();
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock invoice data - in real app this would be API call
    if (invoiceNumber == 'INV-12345') {
      setState(() {
        _invoiceProducts = [
          {
            'id': '1',
            'name': 'Wireless Headphones',
            'quantity': 1,
            'price': 99.99,
            'isSelected': false,
            'returnQuantityController': TextEditingController(text: '1'),
          },
          {
            'id': '2',
            'name': 'Bluetooth Speaker',
            'quantity': 2,
            'price': 49.99,
            'isSelected': false,
            'returnQuantityController': TextEditingController(text: '1'),
          },
          {
            'id': '3',
            'name': 'USB Cable',
            'quantity': 1,
            'price': 9.99,
            'isSelected': false,
            'returnQuantityController': TextEditingController(text: '1'),
          },
        ];
        _isLoadingInvoice = false;
      });
    } else {
      setState(() {
        _invoiceError = 'Invoice not found or no products available for return';
        _isLoadingInvoice = false;
      });
    }
  }

  Future<void> _submitReturn() async {
    // Get selected products from invoice products
    final selectedProducts = _invoiceProducts
        .where((p) => p['isSelected'] == true)
        .toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select products to return')),
      );
      return;
    }

    final returnReason = _returnReasonController.text.trim();
    if (returnReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a return reason')),
      );
      return;
    }

    setState(() {
      _isSubmittingReturn = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Calculate totals for selected products
    double totalAmount = 0.0;
    for (var product in selectedProducts) {
      final quantity =
          int.tryParse(product['returnQuantityController'].text) ??
          product['quantity'];
      totalAmount += product['price'] * quantity;
    }

    // Add to sales returns list
    final newReturn = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'product': {'name': selectedProducts.first['name'], 'image': null},
      'date': _selectedReturnDate,
      'customer': _selectedCustomerType == 'Credit Customer'
          ? 'Credit Customer'
          : 'Normal Customer',
      'customerType': _selectedCustomerType,
      'status': 'Pending',
      'totalPaid': 0.0,
      'dueAmount': totalAmount,
      'grandTotal': totalAmount,
      'paidAmount': 0.0,
      'paymentStatus': 'Unpaid',
    };

    setState(() {
      _salesReturns.insert(0, newReturn);
      _isSubmittingReturn = false;
      _showAddReturnDialog = false;
    });

    // Reset form
    _resetForm();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return invoice generated successfully')),
    );
  }

  void _resetForm() {
    setState(() {
      _returnReasonController.clear();
      _cnicController.clear();
      _invoiceNumberController.clear();
      _selectedProducts.clear();
      _selectedCustomerType = 'Normal Customer';
      _selectedReturnDate = DateTime.now();
      _invoiceProducts.clear();
      _invoiceError = '';
    });
  }

  List<Map<String, dynamic>> _getFilteredReturns() {
    return _salesReturns.where((returnItem) {
      final customerMatch =
          _selectedCustomer == 'All' ||
          returnItem['customer'] == _selectedCustomer;
      final statusMatch =
          _selectedStatus == 'All' || returnItem['status'] == _selectedStatus;
      final paymentMatch =
          _selectedPaymentStatus == 'All' ||
          returnItem['paymentStatus'] == _selectedPaymentStatus;

      // Date filtering based on sortBy
      bool dateMatch = true;
      if (_sortBy == 'Last 7 Days') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        dateMatch = returnItem['date'].isAfter(sevenDaysAgo);
      }

      return customerMatch && statusMatch && paymentMatch && dateMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReturns = _getFilteredReturns();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Returns'),
        backgroundColor: const Color(0xFF0D1845),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF8F9FA)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Header with margin
                Container(
                  margin: const EdgeInsets.all(24),
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
                          Icons.assignment_return,
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
                              'Sales Returns',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage product returns and process customer refunds',
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
                          setState(() {
                            _showAddReturnDialog = true;
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Sales Return'),
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

                // Filters Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
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
                        crossAxisAlignment: CrossAxisAlignment.end,
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
                                              'Alex Chen',
                                              'Jessica Taylor',
                                              'Kevin Martinez',
                                              'Amanda Garcia',
                                              'David Rodriguez',
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
                                          _selectedCustomer = value;
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
                                              'Accepted',
                                              'Rejected',
                                              'Completed',
                                              'Pending',
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
                                                          : status == 'Accepted'
                                                          ? Icons
                                                                .check_circle_rounded
                                                          : status == 'Rejected'
                                                          ? Icons.cancel_rounded
                                                          : status ==
                                                                'Completed'
                                                          ? Icons
                                                                .done_all_rounded
                                                          : Icons.pending,
                                                      color: status == 'All'
                                                          ? Color(0xFF6C757D)
                                                          : status == 'Accepted'
                                                          ? Color(0xFF28A745)
                                                          : status == 'Rejected'
                                                          ? Color(0xFFDC3545)
                                                          : status ==
                                                                'Completed'
                                                          ? Color(0xFF007BFF)
                                                          : Color(0xFFFFA726),
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      status,
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
                                          _selectedStatus = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Payment Status Filter
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
                                        Icons.payment,
                                        size: 16,
                                        color: Color(0xFF0D1845),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Payment Status',
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
                                    value: _selectedPaymentStatus,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: 'Select payment status',
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
                                    items: ['All', 'Paid', 'Unpaid', 'Overdue']
                                        .map(
                                          (status) => DropdownMenuItem(
                                            value: status,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  status == 'All'
                                                      ? Icons
                                                            .account_balance_wallet
                                                      : status == 'Paid'
                                                      ? Icons.check_circle
                                                      : status == 'Unpaid'
                                                      ? Icons.cancel
                                                      : Icons.warning,
                                                  color: status == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : status == 'Paid'
                                                      ? Color(0xFF28A745)
                                                      : status == 'Unpaid'
                                                      ? Color(0xFFDC3545)
                                                      : Color(0xFFFFA726),
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
                                          _selectedPaymentStatus = value;
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

                // Table Section
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
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
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text('Return ID', style: _headerStyle()),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Product', style: _headerStyle()),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Date', style: _headerStyle()),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Customer Name',
                                  style: _headerStyle(),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Customer Type',
                                  style: _headerStyle(),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('Status', style: _headerStyle()),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Total Paid',
                                  style: _headerStyle(),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Due Amount',
                                  style: _headerStyle(),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Actions', style: _headerStyle()),
                              ),
                            ],
                          ),
                        ),

                        // Table Body
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredReturns.length,
                            itemBuilder: (context, index) {
                              final returnItem = filteredReturns[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        returnItem['id'],
                                        style: _cellStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Color(0xFFDEE2E6),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.inventory_2,
                                              color: Color(0xFF6C757D),
                                              size: 18,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            returnItem['product']['name'],
                                            style: _cellStyle(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(returnItem['date']),
                                        style: _cellStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        returnItem['customer'],
                                        style: _cellStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (returnItem['customerType'] ==
                                                          'Credit Customer'
                                                      ? Colors.blue
                                                      : Colors.green)
                                                  .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          returnItem['customerType'] ??
                                              'Normal',
                                          style: TextStyle(
                                            color:
                                                returnItem['customerType'] ==
                                                    'Credit Customer'
                                                ? Colors.blue[800]
                                                : Colors.green[800],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            returnItem['status'],
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          returnItem['status'],
                                          style: TextStyle(
                                            color: _getStatusColor(
                                              returnItem['status'],
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rs. ${returnItem['paidAmount'].toStringAsFixed(2)}',
                                        style: _cellStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Rs. ${returnItem['dueAmount'].toStringAsFixed(2)}',
                                        style: _cellStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.visibility,
                                              color: const Color(0xFF0D1845),
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _viewReturnDetails(returnItem),
                                            tooltip: 'View Details',
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _editReturn(returnItem),
                                            tooltip: 'Edit',
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            onPressed: () =>
                                                _deleteReturn(returnItem['id']),
                                            tooltip: 'Delete',
                                            padding: const EdgeInsets.all(6),
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Add Return Dialog
            ...(_showAddReturnDialog ? [_buildAddReturnDialog()] : []),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Color(0xFF343A40),
    );
  }

  TextStyle _cellStyle() {
    return const TextStyle(fontSize: 13, color: Color(0xFF6C757D));
  }

  void _viewReturnDetails(Map<String, dynamic> returnItem) {
    // TODO: Implement view return details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for return ${returnItem['id']}')),
    );
  }

  void _editReturn(Map<String, dynamic> returnItem) {
    // TODO: Implement edit return
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing return ${returnItem['id']}')),
    );
  }

  void _deleteReturn(String returnId) {
    // TODO: Implement delete return
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleting return $returnId')));
  }

  Widget _buildAddReturnDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1845),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Add Sales Return',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showAddReturnDialog = false;
                          _resetForm();
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Dialog Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Type Selection
                      const Text(
                        'Customer Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCustomerType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: ['Normal Customer', 'Credit Customer']
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCustomerType = value;
                              _cnicController.clear();
                              _invoiceProducts.clear();
                              _invoiceError = '';
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Conditional Fields based on Customer Type
                      if (_selectedCustomerType == 'Credit Customer') ...[
                        const Text(
                          'Customer CNIC',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1845),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cnicController,
                          decoration: InputDecoration(
                            labelText: 'CNIC',
                            hintText: 'e.g., 12345-6789012-3',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.credit_card),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Date Selection
                      const Text(
                        'Return Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedReturnDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Color(0xFF0D1845),
                                    onPrimary: Colors.white,
                                    onSurface: Color(0xFF343A40),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != _selectedReturnDate) {
                            setState(() {
                              _selectedReturnDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(_selectedReturnDate),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Invoice Number
                      const Text(
                        'Invoice Number / Reference',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _invoiceNumberController,
                              decoration: InputDecoration(
                                labelText: 'Invoice Number',
                                hintText: 'e.g., INV-12345',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.receipt_long),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoadingInvoice
                                ? null
                                : _fetchInvoiceDetails,
                            icon: _isLoadingInvoice
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              _isLoadingInvoice
                                  ? 'Searching...'
                                  : 'Find Invoice',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D1845),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Invoice Error Display
                      if (_invoiceError.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _invoiceError,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Products Section
                      if (_invoiceProducts.isNotEmpty) ...[
                        const Text(
                          'Select Products to Return',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1845),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Select')),
                                DataColumn(label: Text('Product')),
                                DataColumn(label: Text('Quantity')),
                                DataColumn(label: Text('Price')),
                                DataColumn(label: Text('Total')),
                              ],
                              rows: _invoiceProducts.map((product) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: product['isSelected'],
                                        onChanged: (value) {
                                          setState(() {
                                            product['isSelected'] =
                                                value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(Text(product['name'])),
                                    DataCell(
                                      product['isSelected']
                                          ? TextField(
                                              controller:
                                                  product['returnQuantityController'],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                hintText: 'Qty',
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (value) {
                                                final qty =
                                                    int.tryParse(value) ?? 0;
                                                if (qty > product['quantity']) {
                                                  product['returnQuantityController']
                                                          .text =
                                                      product['quantity']
                                                          .toString();
                                                }
                                              },
                                            )
                                          : Text(
                                              product['quantity'].toString(),
                                            ),
                                    ),
                                    DataCell(
                                      Text(
                                        'Rs. ${product['price'].toStringAsFixed(2)}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        'Rs. ${(product['price'] * product['quantity']).toStringAsFixed(2)}',
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Return Reason
                        const Text(
                          'Return Reason',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1845),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _returnReasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Reason for return',
                            hintText:
                                'Please provide a reason for this return...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_invoiceProducts.isNotEmpty &&
                                      _invoiceProducts.any(
                                        (p) => p['isSelected'],
                                      ) &&
                                      !_isSubmittingReturn)
                                  ? _submitReturn
                                  : null,
                              icon: _isSubmittingReturn
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.assignment_return),
                              label: Text(
                                _isSubmittingReturn
                                    ? 'Submitting...'
                                    : 'Submit Return',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D1845),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _showAddReturnDialog = false;
                                _resetForm();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Cancel'),
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
      ),
    );
  }
}

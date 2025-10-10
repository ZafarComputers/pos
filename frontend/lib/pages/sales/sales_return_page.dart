import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesReturnPage extends StatefulWidget {
  const SalesReturnPage({super.key});

  @override
  State<SalesReturnPage> createState() => _SalesReturnPageState();
}

class _SalesReturnPageState extends State<SalesReturnPage> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _returnReasonController = TextEditingController();

  // Mock data for demonstration - in real app this would come from API
  List<Map<String, dynamic>> _salesReturns = [];
  Map<String, dynamic>? _orderDetails;
  bool _isLoadingOrder = false;
  bool _isOrderEligible = false;
  String _eligibilityMessage = '';
  List<Map<String, dynamic>> _selectedProducts = [];
  bool _isSubmittingReturn = false;
  bool _showAddReturnDialog = false;

  // Filter states
  String _selectedCustomer = 'All';
  String _selectedStatus = 'All';
  String _selectedPaymentStatus = 'All';
  String _sortBy = 'Last 7 Days';

  // Mock order data for demonstration
  final Map<String, dynamic> _mockOrderData = {
    'orderId': 'INV-12345',
    'customerName': 'John Doe',
    'purchaseDate': DateTime(2025, 10, 1), // Within 7 days from Oct 5, 2025
    'products': [
      {
        'id': '1',
        'name': 'Wireless Headphones',
        'price': 99.99,
        'quantity': 1,
        'image': null,
      },
      {
        'id': '2',
        'name': 'Bluetooth Speaker',
        'price': 49.99,
        'quantity': 2,
        'image': null,
      },
      {
        'id': '3',
        'name': 'USB Cable',
        'price': 9.99,
        'quantity': 1,
        'image': null,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadMockSalesReturns();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _returnReasonController.dispose();
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

  Future<void> _fetchOrderDetails() async {
    final orderId = _orderIdController.text.trim();
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an Order ID')));
      return;
    }

    setState(() {
      _isLoadingOrder = true;
      _orderDetails = null;
      _isOrderEligible = false;
      _eligibilityMessage = '';
      _selectedProducts.clear();
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock validation - in real app this would be API call
    if (orderId == _mockOrderData['orderId']) {
      final orderData = Map<String, dynamic>.from(_mockOrderData);
      final purchaseDate = orderData['purchaseDate'] as DateTime;
      final daysDifference = DateTime.now().difference(purchaseDate).inDays;

      // Check return policy (7 days)
      const returnPeriodDays = 7;
      final isEligible = daysDifference <= returnPeriodDays;

      setState(() {
        _orderDetails = orderData;
        _isOrderEligible = isEligible;
        _eligibilityMessage = isEligible
            ? 'Order is eligible for return'
            : 'Order is not eligible for return (purchase date: ${DateFormat('MMM dd, yyyy').format(purchaseDate)})';
        _isLoadingOrder = false;
      });
    } else {
      setState(() {
        _isLoadingOrder = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order not found')));
    }
  }

  void _toggleProductSelection(Map<String, dynamic> product) {
    setState(() {
      final productId = product['id'];
      final existingIndex = _selectedProducts.indexWhere(
        (p) => p['id'] == productId,
      );

      if (existingIndex >= 0) {
        _selectedProducts.removeAt(existingIndex);
      } else {
        _selectedProducts.add(Map<String, dynamic>.from(product));
      }
    });
  }

  Future<void> _submitReturn() async {
    if (!_isOrderEligible || _selectedProducts.isEmpty) {
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

    // Add to sales returns list
    final newReturn = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'product': {'name': _selectedProducts.first['name'], 'image': null},
      'date': DateTime.now(),
      'customer': _orderDetails!['customerName'],
      'status': 'Pending', // Initial status for new returns
      'grandTotal': _selectedProducts.fold(
        0.0,
        (sum, p) => sum + (p['price'] * p['quantity']),
      ),
      'paidAmount': 0.0,
      'dueAmount': _selectedProducts.fold(
        0.0,
        (sum, p) => sum + (p['price'] * p['quantity']),
      ),
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
      const SnackBar(content: Text('Return submitted successfully')),
    );
  }

  void _resetForm() {
    setState(() {
      _orderIdController.clear();
      _returnReasonController.clear();
      _orderDetails = null;
      _isOrderEligible = false;
      _eligibilityMessage = '';
      _selectedProducts.clear();
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF8F9FA)],
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
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
                        label: const Text('Process Return'),
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
                      const SizedBox(height: 16),
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
                              Icons.assignment_return,
                              color: Color(0xFF0D1845),
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Returns List',
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
                                    Icons.assignment_return,
                                    color: Color(0xFF1976D2),
                                    size: 12,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    '${filteredReturns.length} Returns',
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
                          dataRowColor:
                              MaterialStateProperty.resolveWith<Color>((
                                Set<MaterialState> states,
                              ) {
                                if (states.contains(MaterialState.selected)) {
                                  return Color(0xFF0D1845).withOpacity(0.1);
                                }
                                return Colors.white;
                              }),
                          columns: const [
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Grand Total')),
                            DataColumn(label: Text('Paid')),
                            DataColumn(label: Text('Due')),
                            DataColumn(label: Text('Payment Status')),
                          ],
                          rows: filteredReturns.map((returnItem) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                      Text(returnItem['product']['name']),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(returnItem['date']),
                                  ),
                                ),
                                DataCell(Text(returnItem['customer'])),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        returnItem['status'],
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
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
                                DataCell(
                                  Text(
                                    'Rs. ${returnItem['grandTotal'].toStringAsFixed(2)}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'Rs. ${returnItem['paidAmount'].toStringAsFixed(2)}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'Rs. ${returnItem['dueAmount'].toStringAsFixed(2)}',
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPaymentStatusColor(
                                        returnItem['paymentStatus'],
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      returnItem['paymentStatus'],
                                      style: TextStyle(
                                        color: _getPaymentStatusColor(
                                          returnItem['paymentStatus'],
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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

          // Add Return Dialog
          if (_showAddReturnDialog) _buildAddReturnDialog(),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Unpaid':
        return Colors.red;
      case 'Overdue':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
                      'Process Sales Return',
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
                      // Order ID Input
                      const Text(
                        'Step 1: Enter Order ID',
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
                              controller: _orderIdController,
                              decoration: InputDecoration(
                                labelText: 'Order ID',
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
                            onPressed: _isLoadingOrder
                                ? null
                                : _fetchOrderDetails,
                            icon: _isLoadingOrder
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
                              _isLoadingOrder ? 'Searching...' : 'Find Order',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D1845),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Order Details
                      if (_orderDetails != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isOrderEligible
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Order Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _isOrderEligible
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isOrderEligible
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _isOrderEligible
                                          ? 'Eligible'
                                          : 'Not Eligible',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _eligibilityMessage,
                                style: TextStyle(
                                  color: _isOrderEligible
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      'Order ID',
                                      _orderDetails!['orderId'],
                                      Icons.receipt_long,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      'Customer',
                                      _orderDetails!['customerName'],
                                      Icons.person,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      'Purchase Date',
                                      DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_orderDetails!['purchaseDate']),
                                      Icons.calendar_today,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Products Selection
                        const Text(
                          'Step 2: Select Products to Return',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1845),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(_orderDetails!['products'] as List).map((product) {
                          final isSelected = _selectedProducts.any(
                            (p) => p['id'] == product['id'],
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0D1845).withOpacity(0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0D1845)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: InkWell(
                              onTap: _isOrderEligible
                                  ? () => _toggleProductSelection(product)
                                  : null,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: _isOrderEligible
                                        ? (value) =>
                                              _toggleProductSelection(product)
                                        : null,
                                    activeColor: const Color(0xFF0D1845),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Qty: ${product['quantity']} • Rs. ${product['price']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Return Reason
                        const Text(
                          'Step 3: Return Reason',
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
                            hintText:
                                'Please provide a reason for the return...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          enabled: _isOrderEligible,
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    (_isOrderEligible &&
                                        _selectedProducts.isNotEmpty &&
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

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D1845),
            ),
          ),
        ],
      ),
    );
  }
}

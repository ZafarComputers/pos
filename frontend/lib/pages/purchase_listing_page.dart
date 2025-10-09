import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'create_purchase_page.dart';

class PurchaseListingPage extends StatefulWidget {
  const PurchaseListingPage({super.key});

  @override
  State<PurchaseListingPage> createState() => _PurchaseListingPageState();
}

class _PurchaseListingPageState extends State<PurchaseListingPage> {
  // Mock data for demonstration - in real app this would come from API
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _selectedPurchases = [];
  bool _selectAll = false;

  // Filter states
  String _selectedStatus = 'All';
  String _selectedPaymentStatus = 'All';
  String _sortBy = 'Last 7 Days';

  @override
  void initState() {
    super.initState();
    _loadMockPurchases();
  }

  void _loadMockPurchases() {
    // Mock purchase data with comprehensive dummy data
    _purchases = [
      {
        'id': '1',
        'reference': 'PUR-2025-001',
        'date': DateTime(2025, 10, 8),
        'vendor': 'Tech Supplies Inc.',
        'status': 'Completed',
        'total': 15000.0,
        'paidAmount': 15000.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '2',
        'reference': 'PUR-2025-002',
        'date': DateTime(2025, 10, 7),
        'vendor': 'Global Electronics Ltd.',
        'status': 'Pending',
        'total': 22500.0,
        'paidAmount': 0.0,
        'dueAmount': 22500.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '3',
        'reference': 'PUR-2025-003',
        'date': DateTime(2025, 10, 6),
        'vendor': 'Fashion Wholesale Co.',
        'status': 'Completed',
        'total': 18500.0,
        'paidAmount': 18500.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '4',
        'reference': 'PUR-2025-004',
        'date': DateTime(2025, 10, 5),
        'vendor': 'Home Goods Distributors',
        'status': 'Pending',
        'total': 12000.0,
        'paidAmount': 0.0,
        'dueAmount': 12000.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '5',
        'reference': 'PUR-2025-005',
        'date': DateTime(2025, 10, 4),
        'vendor': 'Sports Equipment Corp.',
        'status': 'Completed',
        'total': 9500.0,
        'paidAmount': 9500.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '6',
        'reference': 'PUR-2025-006',
        'date': DateTime(2025, 10, 3),
        'vendor': 'Beauty Products Ltd.',
        'status': 'Pending',
        'total': 16800.0,
        'paidAmount': 0.0,
        'dueAmount': 16800.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '7',
        'reference': 'PUR-2025-007',
        'date': DateTime(2025, 10, 2),
        'vendor': 'Office Supplies Plus',
        'status': 'Completed',
        'total': 13200.0,
        'paidAmount': 13200.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '8',
        'reference': 'PUR-2025-008',
        'date': DateTime(2025, 10, 1),
        'vendor': 'Industrial Parts Co.',
        'status': 'Pending',
        'total': 28500.0,
        'paidAmount': 0.0,
        'dueAmount': 28500.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '9',
        'reference': 'PUR-2025-009',
        'date': DateTime(2025, 9, 30),
        'vendor': 'Food & Beverage Distributors',
        'status': 'Completed',
        'total': 9800.0,
        'paidAmount': 9800.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '10',
        'reference': 'PUR-2025-010',
        'date': DateTime(2025, 9, 29),
        'vendor': 'Medical Supplies Inc.',
        'status': 'Pending',
        'total': 24500.0,
        'paidAmount': 0.0,
        'dueAmount': 24500.0,
        'paymentStatus': 'Unpaid',
      },
      {
        'id': '11',
        'reference': 'PUR-2025-011',
        'date': DateTime(2025, 9, 28),
        'vendor': 'Construction Materials Ltd.',
        'status': 'Completed',
        'total': 32000.0,
        'paidAmount': 32000.0,
        'dueAmount': 0.0,
        'paymentStatus': 'Paid',
      },
      {
        'id': '12',
        'reference': 'PUR-2025-012',
        'date': DateTime(2025, 9, 27),
        'vendor': 'Automotive Parts Corp.',
        'status': 'Pending',
        'total': 18700.0,
        'paidAmount': 0.0,
        'dueAmount': 18700.0,
        'paymentStatus': 'Unpaid',
      },
    ];
  }

  void _togglePurchaseSelection(Map<String, dynamic> purchase) {
    setState(() {
      final purchaseId = purchase['id'];
      final existingIndex = _selectedPurchases.indexWhere(
        (p) => p['id'] == purchaseId,
      );

      if (existingIndex >= 0) {
        _selectedPurchases.removeAt(existingIndex);
      } else {
        _selectedPurchases.add(Map<String, dynamic>.from(purchase));
      }

      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedPurchases.clear();
      } else {
        _selectedPurchases = List.from(_getFilteredPurchases());
      }
      _selectAll = !_selectAll;
    });
  }

  void _updateSelectAllState() {
    final filteredPurchases = _getFilteredPurchases();
    _selectAll =
        filteredPurchases.isNotEmpty &&
        _selectedPurchases.length == filteredPurchases.length;
  }

  List<Map<String, dynamic>> _getFilteredPurchases() {
    return _purchases.where((purchase) {
      final statusMatch =
          _selectedStatus == 'All' || purchase['status'] == _selectedStatus;
      final paymentMatch =
          _selectedPaymentStatus == 'All' ||
          purchase['paymentStatus'] == _selectedPaymentStatus;

      // Date filtering based on sortBy
      bool dateMatch = true;
      if (_sortBy == 'Last 7 Days') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        dateMatch = purchase['date'].isAfter(sevenDaysAgo);
      }

      return statusMatch && paymentMatch && dateMatch;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPurchases = _getFilteredPurchases();

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
                          'Purchase Listing',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and track all purchase transactions',
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePurchasePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add new purchase'),
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
                                items: ['All', 'Completed', 'Pending']
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Row(
                                          children: [
                                            Icon(
                                              status == 'All'
                                                  ? Icons.inventory_2_rounded
                                                  : status == 'Completed'
                                                  ? Icons.check_circle_rounded
                                                  : Icons.pending,
                                              color: status == 'All'
                                                  ? Color(0xFF6C757D)
                                                  : status == 'Completed'
                                                  ? Color(0xFF28A745)
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
                                items: ['All', 'Paid', 'Unpaid']
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Row(
                                          children: [
                                            Icon(
                                              status == 'All'
                                                  ? Icons.account_balance_wallet
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
                                      _selectedPaymentStatus = value;
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
                          Icons.shopping_bag,
                          color: Color(0xFF0D1845),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Purchase List',
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
                                Icons.shopping_bag,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${filteredPurchases.length} Purchases',
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
                        DataColumn(label: Text('Vendor Name')),
                        DataColumn(label: Text('Reference Number')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Total Amount')),
                        DataColumn(label: Text('Paid Amount')),
                        DataColumn(label: Text('Due Amount')),
                        DataColumn(label: Text('Payment Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredPurchases.map((purchase) {
                        final isSelected = _selectedPurchases.any(
                          (p) => p['id'] == purchase['id'],
                        );
                        return DataRow(
                          selected: isSelected,
                          cells: [
                            DataCell(
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _togglePurchaseSelection(purchase),
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
                                      Icons.business,
                                      color: Color(0xFF0D1845),
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(purchase['vendor']),
                                ],
                              ),
                            ),
                            DataCell(Text(purchase['reference'])),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(purchase['date']),
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
                                    purchase['status'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  purchase['status'],
                                  style: TextStyle(
                                    color: _getStatusColor(purchase['status']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${purchase['total'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${purchase['paidAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${purchase['dueAmount'].toStringAsFixed(2)}',
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
                                    purchase['paymentStatus'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  purchase['paymentStatus'],
                                  style: TextStyle(
                                    color: _getPaymentStatusColor(
                                      purchase['paymentStatus'],
                                    ),
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
                                      // TODO: Implement view purchase details
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
                                      // TODO: Implement edit purchase
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Color(0xFFDC3545),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement delete purchase
                                    },
                                    tooltip: 'Delete',
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

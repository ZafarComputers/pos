import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'create_purchase_return_page.dart';

class PurchaseReturnPage extends StatefulWidget {
  const PurchaseReturnPage({super.key});

  @override
  State<PurchaseReturnPage> createState() => _PurchaseReturnPageState();
}

class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
  // Mock data for demonstration - in real app this would come from API
  List<Map<String, dynamic>> _purchaseReturns = [];

  // Filter states
  String _selectedStatus = 'All';
  String _sortBy = 'Last 7 Days';

  @override
  void initState() {
    super.initState();
    _loadMockPurchaseReturns();
  }

  void _loadMockPurchaseReturns() {
    // Mock purchase return data with comprehensive dummy data
    _purchaseReturns = [
      {
        'id': '1',
        'reference': 'PUR-2025-001',
        'date': DateTime(2025, 10, 8),
        'vendor': 'Tech Supplies Inc.',
        'status': 'Completed',
        'totalReturnedAmount': 2500.0,
        'paid': 2500.0,
        'due': 0.0,
        'paymentStatus': 'returned',
        'productImage': 'assets/images/products/laptop.jpg',
      },
      {
        'id': '2',
        'reference': 'PUR-2025-002',
        'date': DateTime(2025, 10, 7),
        'vendor': 'Global Electronics Ltd.',
        'status': 'Pending',
        'totalReturnedAmount': 1800.0,
        'paid': 900.0,
        'due': 900.0,
        'paymentStatus': 'pending',
        'productImage': 'assets/images/products/phone.jpg',
      },
      {
        'id': '3',
        'reference': 'PUR-2025-003',
        'date': DateTime(2025, 10, 6),
        'vendor': 'Fashion Wholesale Co.',
        'status': 'Completed',
        'totalReturnedAmount': 3200.0,
        'paid': 3200.0,
        'due': 0.0,
        'paymentStatus': 'returned',
        'productImage': 'assets/images/products/clothing.jpg',
      },
      {
        'id': '4',
        'reference': 'PUR-2025-004',
        'date': DateTime(2025, 10, 5),
        'vendor': 'Home Goods Distributors',
        'status': 'Pending',
        'totalReturnedAmount': 1500.0,
        'paid': 750.0,
        'due': 750.0,
        'paymentStatus': 'pending',
        'productImage': 'assets/images/products/furniture.jpg',
      },
      {
        'id': '5',
        'reference': 'PUR-2025-005',
        'date': DateTime(2025, 10, 4),
        'vendor': 'Sports Equipment Corp.',
        'status': 'Completed',
        'totalReturnedAmount': 950.0,
        'paid': 950.0,
        'due': 0.0,
        'paymentStatus': 'returned',
        'productImage': 'assets/images/products/sports.jpg',
      },
      {
        'id': '6',
        'reference': 'PUR-2025-006',
        'date': DateTime(2025, 10, 3),
        'vendor': 'Beauty Products Ltd.',
        'status': 'Pending',
        'totalReturnedAmount': 2100.0,
        'paid': 1050.0,
        'due': 1050.0,
        'paymentStatus': 'pending',
        'productImage': 'assets/images/products/beauty.jpg',
      },
      {
        'id': '7',
        'reference': 'PUR-2025-007',
        'date': DateTime(2025, 10, 2),
        'vendor': 'Office Supplies Plus',
        'status': 'Completed',
        'totalReturnedAmount': 1750.0,
        'paid': 1750.0,
        'due': 0.0,
        'paymentStatus': 'returned',
        'productImage': 'assets/images/products/office.jpg',
      },
      {
        'id': '8',
        'reference': 'PUR-2025-008',
        'date': DateTime(2025, 10, 1),
        'vendor': 'Industrial Parts Co.',
        'status': 'Pending',
        'totalReturnedAmount': 2800.0,
        'paid': 1400.0,
        'due': 1400.0,
        'paymentStatus': 'pending',
        'productImage': 'assets/images/products/industrial.jpg',
      },
      {
        'id': '9',
        'reference': 'PUR-2025-009',
        'date': DateTime(2025, 9, 30),
        'vendor': 'Food & Beverage Distributors',
        'status': 'Completed',
        'totalReturnedAmount': 1200.0,
        'paid': 1200.0,
        'due': 0.0,
        'paymentStatus': 'returned',
        'productImage': 'assets/images/products/food.jpg',
      },
      {
        'id': '10',
        'reference': 'PUR-2025-010',
        'date': DateTime(2025, 9, 29),
        'vendor': 'Medical Supplies Inc.',
        'status': 'Pending',
        'totalReturnedAmount': 850.0,
        'paid': 425.0,
        'due': 425.0,
        'paymentStatus': 'pending',
        'productImage': 'assets/images/products/medical.jpg',
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredReturns() {
    return _purchaseReturns.where((purchaseReturn) {
      final statusMatch =
          _selectedStatus == 'All' ||
          purchaseReturn['status'] == _selectedStatus;

      // Date filtering based on sortBy
      bool dateMatch = true;
      if (_sortBy == 'Last 7 Days') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        dateMatch = purchaseReturn['date'].isAfter(sevenDaysAgo);
      }

      return statusMatch && dateMatch;
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

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'returned':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
                          'Purchase Return',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and track all purchase return transactions',
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
                          builder: (context) =>
                              const CreatePurchaseReturnPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Purchase Return'),
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
                          'Purchase Return List',
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
                      dataRowColor: MaterialStateProperty.resolveWith<Color>((
                        Set<MaterialState> states,
                      ) {
                        if (states.contains(MaterialState.selected)) {
                          return Color(0xFF0D1845).withOpacity(0.1);
                        }
                        return Colors.white;
                      }),
                      columns: const [
                        DataColumn(label: Text('Product Image')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Vendor Name')),
                        DataColumn(label: Text('Reference')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Due')),
                        DataColumn(label: Text('Payment Status')),
                      ],
                      rows: filteredReturns.map((purchaseReturn) {
                        return DataRow(
                          cells: [
                            // Product Image
                            DataCell(
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                            ),
                            // Date
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(purchaseReturn['date']),
                              ),
                            ),
                            // Vendor Name
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
                                  Text(purchaseReturn['vendor']),
                                ],
                              ),
                            ),
                            // Reference
                            DataCell(Text(purchaseReturn['reference'])),
                            // Status
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    purchaseReturn['status'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  purchaseReturn['status'],
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      purchaseReturn['status'],
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            // Total
                            DataCell(
                              Text(
                                'Rs. ${purchaseReturn['totalReturnedAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            // Paid
                            DataCell(
                              Text(
                                'Rs. ${purchaseReturn['paid'].toStringAsFixed(2)}',
                              ),
                            ),
                            // Due
                            DataCell(
                              Text(
                                'Rs. ${purchaseReturn['due'].toStringAsFixed(2)}',
                              ),
                            ),
                            // Payment Status
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPaymentStatusColor(
                                    purchaseReturn['paymentStatus'],
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  purchaseReturn['paymentStatus'],
                                  style: TextStyle(
                                    color: _getPaymentStatusColor(
                                      purchaseReturn['paymentStatus'],
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
    );
  }
}

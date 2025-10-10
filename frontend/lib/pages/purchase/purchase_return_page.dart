import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchaseReturnPage extends StatefulWidget {
  const PurchaseReturnPage({super.key});

  @override
  State<PurchaseReturnPage> createState() => _PurchaseReturnPageState();
}

class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
  // Mock data for demonstration - in real app this would come from API
  List<Map<String, dynamic>> _purchaseReturns = [];
  List<Map<String, dynamic>> _selectedReturns = [];
  bool _selectAll = false;

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
      },
      {
        'id': '2',
        'reference': 'PUR-2025-002',
        'date': DateTime(2025, 10, 7),
        'vendor': 'Global Electronics Ltd.',
        'status': 'Pending',
        'totalReturnedAmount': 1800.0,
      },
      {
        'id': '3',
        'reference': 'PUR-2025-003',
        'date': DateTime(2025, 10, 6),
        'vendor': 'Fashion Wholesale Co.',
        'status': 'Completed',
        'totalReturnedAmount': 3200.0,
      },
      {
        'id': '4',
        'reference': 'PUR-2025-004',
        'date': DateTime(2025, 10, 5),
        'vendor': 'Home Goods Distributors',
        'status': 'Pending',
        'totalReturnedAmount': 1500.0,
      },
      {
        'id': '5',
        'reference': 'PUR-2025-005',
        'date': DateTime(2025, 10, 4),
        'vendor': 'Sports Equipment Corp.',
        'status': 'Completed',
        'totalReturnedAmount': 950.0,
      },
      {
        'id': '6',
        'reference': 'PUR-2025-006',
        'date': DateTime(2025, 10, 3),
        'vendor': 'Beauty Products Ltd.',
        'status': 'Pending',
        'totalReturnedAmount': 2100.0,
      },
      {
        'id': '7',
        'reference': 'PUR-2025-007',
        'date': DateTime(2025, 10, 2),
        'vendor': 'Office Supplies Plus',
        'status': 'Completed',
        'totalReturnedAmount': 1750.0,
      },
      {
        'id': '8',
        'reference': 'PUR-2025-008',
        'date': DateTime(2025, 10, 1),
        'vendor': 'Industrial Parts Co.',
        'status': 'Pending',
        'totalReturnedAmount': 2800.0,
      },
      {
        'id': '9',
        'reference': 'PUR-2025-009',
        'date': DateTime(2025, 9, 30),
        'vendor': 'Food & Beverage Distributors',
        'status': 'Completed',
        'totalReturnedAmount': 1200.0,
      },
      {
        'id': '10',
        'reference': 'PUR-2025-010',
        'date': DateTime(2025, 9, 29),
        'vendor': 'Medical Supplies Inc.',
        'status': 'Pending',
        'totalReturnedAmount': 850.0,
      },
    ];
  }

  void _toggleReturnSelection(Map<String, dynamic> purchaseReturn) {
    setState(() {
      final returnId = purchaseReturn['id'];
      final existingIndex = _selectedReturns.indexWhere(
        (r) => r['id'] == returnId,
      );

      if (existingIndex >= 0) {
        _selectedReturns.removeAt(existingIndex);
      } else {
        _selectedReturns.add(Map<String, dynamic>.from(purchaseReturn));
      }

      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedReturns.clear();
      } else {
        _selectedReturns = List.from(_getFilteredReturns());
      }
      _selectAll = !_selectAll;
    });
  }

  void _updateSelectAllState() {
    final filteredReturns = _getFilteredReturns();
    _selectAll =
        filteredReturns.isNotEmpty &&
        _selectedReturns.length == filteredReturns.length;
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
                          builder: (context) => const AddPurchaseReturnPage(),
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
                        DataColumn(label: Text('Select')),
                        DataColumn(label: Text('Vendor Name')),
                        DataColumn(label: Text('Reference Number')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Total Returned Amount')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredReturns.map((purchaseReturn) {
                        final isSelected = _selectedReturns.any(
                          (r) => r['id'] == purchaseReturn['id'],
                        );
                        return DataRow(
                          selected: isSelected,
                          cells: [
                            DataCell(
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _toggleReturnSelection(purchaseReturn),
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
                                  Text(purchaseReturn['vendor']),
                                ],
                              ),
                            ),
                            DataCell(Text(purchaseReturn['reference'])),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(purchaseReturn['date']),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${purchaseReturn['totalReturnedAmount'].toStringAsFixed(2)}',
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
                                      // TODO: Implement view purchase return details
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
                                      // TODO: Implement edit purchase return
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
                                      // TODO: Implement delete purchase return
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

class AddPurchaseReturnPage extends StatefulWidget {
  const AddPurchaseReturnPage({super.key});

  @override
  State<AddPurchaseReturnPage> createState() => _AddPurchaseReturnPageState();
}

class _AddPurchaseReturnPageState extends State<AddPurchaseReturnPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVendor;
  String? _selectedReference;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _availablePurchases = [];
  List<Map<String, dynamic>> _selectedProducts = [];

  // Mock vendors and purchases data
  final List<String> _vendors = [
    'Tech Supplies Inc.',
    'Global Electronics Ltd.',
    'Fashion Wholesale Co.',
    'Home Goods Distributors',
    'Sports Equipment Corp.',
    'Beauty Products Ltd.',
    'Office Supplies Plus',
    'Industrial Parts Co.',
    'Food & Beverage Distributors',
    'Medical Supplies Inc.',
  ];

  @override
  void initState() {
    super.initState();
    _loadMockPurchases();
  }

  void _loadMockPurchases() {
    _availablePurchases = [
      {
        'reference': 'PUR-2025-001',
        'vendor': 'Tech Supplies Inc.',
        'products': [
          {
            'id': '1',
            'name': 'Wireless Mouse',
            'image': 'assets/images/products/mouse.jpg',
            'quantityPurchased': 50,
            'quantityToReturn': 5,
            'unitPrice': 25.0,
            'total': 125.0,
          },
          {
            'id': '2',
            'name': 'Mechanical Keyboard',
            'image': 'assets/images/products/keyboard.jpg',
            'quantityPurchased': 30,
            'quantityToReturn': 3,
            'unitPrice': 75.0,
            'total': 225.0,
          },
        ],
      },
      {
        'reference': 'PUR-2025-002',
        'vendor': 'Global Electronics Ltd.',
        'products': [
          {
            'id': '3',
            'name': 'USB Cable',
            'image': 'assets/images/products/cable.jpg',
            'quantityPurchased': 100,
            'quantityToReturn': 10,
            'unitPrice': 5.0,
            'total': 50.0,
          },
        ],
      },
    ];
  }

  void _onVendorChanged(String? vendor) {
    setState(() {
      _selectedVendor = vendor;
      _selectedReference = null;
      _selectedProducts.clear();
    });
  }

  void _onReferenceChanged(String? reference) {
    setState(() {
      _selectedReference = reference;
      _selectedProducts.clear();

      // Auto-populate products based on selected reference
      final purchase = _availablePurchases.firstWhere(
        (p) => p['reference'] == reference,
        orElse: () => {},
      );

      if (purchase.isNotEmpty) {
        _selectedProducts = List.from(purchase['products']);
      }
    });
  }

  void _updateProductQuantity(String productId, int quantity) {
    setState(() {
      final productIndex = _selectedProducts.indexWhere(
        (p) => p['id'] == productId,
      );
      if (productIndex >= 0) {
        _selectedProducts[productIndex]['quantityToReturn'] = quantity;
        _selectedProducts[productIndex]['total'] =
            quantity * _selectedProducts[productIndex]['unitPrice'];
      }
    });
  }

  void _removeProduct(String productId) {
    setState(() {
      _selectedProducts.removeWhere((p) => p['id'] == productId);
    });
  }

  double _calculateTotalReturnAmount() {
    return _selectedProducts.fold(
      0.0,
      (sum, product) => sum + product['total'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1845),
        title: const Text('Add Purchase Return'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF8F9FA)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                              'Create Purchase Return',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Return products from existing purchases',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                Container(
                  padding: const EdgeInsets.all(24),
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
                      const Text(
                        'Return Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF343A40),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Vendor Selection
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vendor Name',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedVendor,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'Select vendor',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFDEE2E6),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFDEE2E6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF0D1845),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items: _vendors
                                      .map(
                                        (vendor) => DropdownMenuItem(
                                          value: vendor,
                                          child: Text(vendor),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _onVendorChanged,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a vendor';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Date Picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        _selectedDate = pickedDate;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFDEE2E6),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF6C757D),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat(
                                            'dd MMM yyyy',
                                          ).format(_selectedDate),
                                          style: const TextStyle(
                                            color: Color(0xFF343A40),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Reference Number (auto-populated based on vendor)
                      if (_selectedVendor != null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reference Number',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedReference,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Select purchase reference',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDEE2E6),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDEE2E6),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0D1845),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              items: _availablePurchases
                                  .where(
                                    (purchase) =>
                                        purchase['vendor'] == _selectedVendor,
                                  )
                                  .map(
                                    (purchase) => DropdownMenuItem<String>(
                                      value: purchase['reference'] as String,
                                      child: Text(
                                        purchase['reference'] as String,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _onReferenceChanged,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a reference number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Products Table (only show when reference is selected)
                if (_selectedReference != null &&
                    _selectedProducts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
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
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const Text(
                                'Products to Return',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF343A40),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Total: Rs. ${_calculateTotalReturnAmount().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF1976D2),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              const Color(0xFFF8F9FA),
                            ),
                            columns: const [
                              DataColumn(label: Text('Product Image')),
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Quantity Purchased')),
                              DataColumn(label: Text('Quantity to Return')),
                              DataColumn(label: Text('Unit Price')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _selectedProducts.map((product) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(product['name'])),
                                  DataCell(
                                    Text(
                                      product['quantityPurchased'].toString(),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        initialValue:
                                            product['quantityToReturn']
                                                .toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          final quantity =
                                              int.tryParse(value) ?? 0;
                                          _updateProductQuantity(
                                            product['id'],
                                            quantity,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      'Rs. ${product['unitPrice'].toStringAsFixed(2)}',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      'Rs. ${product['total'].toStringAsFixed(2)}',
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Color(0xFFDC3545),
                                      ),
                                      onPressed: () =>
                                          _removeProduct(product['id']),
                                      tooltip: 'Remove Product',
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

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // TODO: Implement save purchase return
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Purchase return created successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Purchase Return'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6C757D)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF6C757D)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

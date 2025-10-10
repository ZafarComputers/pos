import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditCustomerPage extends StatefulWidget {
  const CreditCustomerPage({super.key});

  @override
  State<CreditCustomerPage> createState() => _CreditCustomerPageState();
}

class _CreditCustomerPageState extends State<CreditCustomerPage> {
  // Mock data for demonstration
  List<Map<String, dynamic>> _creditCustomers = [];
  List<Map<String, dynamic>> _selectedCustomers = [];
  bool _selectAll = false;

  // Filter states
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMockCustomers();
  }

  void _loadMockCustomers() {
    _creditCustomers = [
      {
        'id': '1',
        'code': 'CC001',
        'name': 'John Doe',
        'cnic': '12345-6789012-3',
        'phone': '+92-300-1234567',
        'totalPending': 2500.0,
        'paidAmount': 1500.0,
        'address': '123 Main St, Lahore',
        'city': 'Lahore',
        'secondPersonName': 'Jane Doe',
        'secondPersonCnic': '12345-6789012-4',
        'secondPersonPhone': '+92-300-1234568',
        'picture': null,
        'paymentRecords': [
          {
            'invoiceNumber': 'INV-001',
            'date': DateTime(2025, 10, 1),
            'totalAmount': 1000.0,
            'paidAmount': 600.0,
            'pendingAmount': 400.0,
          },
          {
            'invoiceNumber': 'INV-002',
            'date': DateTime(2025, 10, 5),
            'totalAmount': 1500.0,
            'paidAmount': 900.0,
            'pendingAmount': 600.0,
          },
        ],
      },
      {
        'id': '2',
        'code': 'CC002',
        'name': 'Ahmed Khan',
        'cnic': '23456-7890123-4',
        'phone': '+92-301-2345678',
        'totalPending': 1800.0,
        'paidAmount': 1200.0,
        'address': '456 Market Rd, Karachi',
        'city': 'Karachi',
        'secondPersonName': 'Sara Khan',
        'secondPersonCnic': '23456-7890123-5',
        'secondPersonPhone': '+92-301-2345679',
        'picture': null,
        'paymentRecords': [
          {
            'invoiceNumber': 'INV-003',
            'date': DateTime(2025, 9, 28),
            'totalAmount': 1800.0,
            'paidAmount': 1200.0,
            'pendingAmount': 600.0,
          },
        ],
      },
      {
        'id': '3',
        'code': 'CC003',
        'name': 'Maria Santos',
        'cnic': '34567-8901234-5',
        'phone': '+92-302-3456789',
        'totalPending': 3200.0,
        'paidAmount': 800.0,
        'address': '789 Plaza Ave, Islamabad',
        'city': 'Islamabad',
        'secondPersonName': 'Carlos Santos',
        'secondPersonCnic': '34567-8901234-6',
        'secondPersonPhone': '+92-302-3456790',
        'picture': null,
        'paymentRecords': [
          {
            'invoiceNumber': 'INV-004',
            'date': DateTime(2025, 10, 3),
            'totalAmount': 2000.0,
            'paidAmount': 500.0,
            'pendingAmount': 1500.0,
          },
          {
            'invoiceNumber': 'INV-005',
            'date': DateTime(2025, 10, 7),
            'totalAmount': 2000.0,
            'paidAmount': 300.0,
            'pendingAmount': 1700.0,
          },
        ],
      },
    ];
  }

  void _toggleCustomerSelection(Map<String, dynamic> customer) {
    setState(() {
      final customerId = customer['id'];
      final existingIndex = _selectedCustomers.indexWhere(
        (c) => c['id'] == customerId,
      );

      if (existingIndex >= 0) {
        _selectedCustomers.removeAt(existingIndex);
      } else {
        _selectedCustomers.add(Map<String, dynamic>.from(customer));
      }

      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedCustomers.clear();
      } else {
        _selectedCustomers = List.from(_getFilteredCustomers());
      }
      _selectAll = !_selectAll;
    });
  }

  void _updateSelectAllState() {
    final filteredCustomers = _getFilteredCustomers();
    _selectAll =
        filteredCustomers.isNotEmpty &&
        _selectedCustomers.length == filteredCustomers.length;
  }

  List<Map<String, dynamic>> _getFilteredCustomers() {
    if (_searchQuery.isEmpty) {
      return _creditCustomers;
    }

    final query = _searchQuery.toLowerCase();
    return _creditCustomers.where((customer) {
      return customer['name'].toLowerCase().contains(query) ||
          customer['cnic'].contains(query) ||
          customer['phone'].contains(query) ||
          customer['code'].toLowerCase().contains(query);
    }).toList();
  }

  double _getTotalPendingCredit() {
    return _creditCustomers.fold(
      0.0,
      (sum, customer) => sum + customer['totalPending'],
    );
  }

  void _showCreateCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateCreditCustomerDialog(
        currentCustomerCount: _creditCustomers.length,
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _creditCustomers.add(result);
        });
      }
    });
  }

  void _showEditCustomerDialog(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => EditCreditCustomerDialog(customer: customer),
    ).then((result) {
      if (result != null) {
        setState(() {
          final index = _creditCustomers.indexWhere(
            (c) => c['id'] == customer['id'],
          );
          if (index >= 0) {
            _creditCustomers[index] = result;
          }
        });
      }
    });
  }

  void _deleteCustomer(String customerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'Are you sure you want to delete this credit customer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _creditCustomers.removeWhere((c) => c['id'] == customerId);
                _selectedCustomers.removeWhere((c) => c['id'] == customerId);
                _updateSelectAllState();
              });
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _getFilteredCustomers();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to POS',
        ),
        title: const Text('Credit Customers'),
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
        child: Column(
          children: [
            // Header with Summary Cards
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
              margin: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
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
                              'Credit Customers',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage credit customers and their payment records',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCreateCustomerDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Create New Credit Customer'),
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
                  const SizedBox(height: 32),
                  // Summary Cards
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Total Credit Customers',
                        _creditCustomers.length.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      const SizedBox(width: 24),
                      _buildSummaryCard(
                        'Total Pending Credit',
                        'Rs. ${_getTotalPendingCredit().toStringAsFixed(2)}',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search and Table
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
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _updateSelectAllState();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name, CNIC, phone, or code...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),

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
                          Checkbox(
                            value: _selectAll,
                            onChanged: (value) => _toggleSelectAll(),
                            activeColor: const Color(0xFF0D1845),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Text('Code', style: _headerStyle()),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Customer Name', style: _headerStyle()),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('CNIC', style: _headerStyle()),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Phone Number', style: _headerStyle()),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Total Pending', style: _headerStyle()),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Paid Amount', style: _headerStyle()),
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
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          final isSelected = _selectedCustomers.any(
                            (c) => c['id'] == customer['id'],
                          );

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0D1845).withOpacity(0.05)
                                  : Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) =>
                                      _toggleCustomerSelection(customer),
                                  activeColor: const Color(0xFF0D1845),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    customer['code'],
                                    style: _cellStyle(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    customer['name'],
                                    style: _cellStyle(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    customer['cnic'],
                                    style: _cellStyle(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    customer['phone'],
                                    style: _cellStyle(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Rs. ${customer['totalPending'].toStringAsFixed(2)}',
                                    style: _cellStyle(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Rs. ${customer['paidAmount'].toStringAsFixed(2)}',
                                    style: _cellStyle(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.visibility,
                                          color: const Color(0xFF0D1845),
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _showEditCustomerDialog(customer),
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
                                            _showEditCustomerDialog(customer),
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
                                            _deleteCustomer(customer['id']),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
}

class CreateCreditCustomerDialog extends StatefulWidget {
  final int currentCustomerCount;

  const CreateCreditCustomerDialog({
    super.key,
    required this.currentCustomerCount,
  });

  @override
  State<CreateCreditCustomerDialog> createState() =>
      _CreateCreditCustomerDialogState();
}

class _CreateCreditCustomerDialogState
    extends State<CreateCreditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondPersonNameController = TextEditingController();
  final _secondPersonCnicController = TextEditingController();
  final _secondPersonPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1845), Color(0xFF1A237E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create New Credit Customer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill in all required information to create a new credit customer',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary Customer Information Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Primary Customer Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _fullNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name *',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter full name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cnicController,
                                    decoration: InputDecoration(
                                      labelText: 'CNIC Number *',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.credit_card),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter CNIC number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number *',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Second Person Information Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Second Person Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _secondPersonNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Second Person Name *',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter second person name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _secondPersonCnicController,
                                    decoration: InputDecoration(
                                      labelText: 'Second Person CNIC *',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(Icons.credit_card),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter second person CNIC';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _secondPersonPhoneController,
                              decoration: InputDecoration(
                                labelText: 'Second Person Phone Number *',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter second person phone number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Address Information Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Address Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Address *',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.home),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: 'City *',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.location_city),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter city';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      foregroundColor: Colors.grey[600],
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newCustomer = {
                          'id': DateTime.now().millisecondsSinceEpoch
                              .toString(),
                          'code':
                              'CC${(widget.currentCustomerCount + 1).toString().padLeft(3, '0')}',
                          'name': _fullNameController.text,
                          'cnic': _cnicController.text,
                          'phone': _phoneController.text,
                          'totalPending': 0.0,
                          'paidAmount': 0.0,
                          'address': _addressController.text,
                          'city': _cityController.text,
                          'secondPersonName': _secondPersonNameController.text,
                          'secondPersonCnic': _secondPersonCnicController.text,
                          'secondPersonPhone':
                              _secondPersonPhoneController.text,
                          'paymentRecords': <Map<String, dynamic>>[],
                        };
                        Navigator.of(context).pop(newCustomer);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 2,
                      shadowColor: Colors.green.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

class EditCreditCustomerDialog extends StatefulWidget {
  final Map<String, dynamic> customer;

  const EditCreditCustomerDialog({super.key, required this.customer});

  @override
  State<EditCreditCustomerDialog> createState() =>
      _EditCreditCustomerDialogState();
}

class _EditCreditCustomerDialogState extends State<EditCreditCustomerDialog> {
  late List<Map<String, dynamic>> _paymentRecords;

  @override
  void initState() {
    super.initState();
    _paymentRecords = List.from(widget.customer['paymentRecords']);
  }

  void _addPaymentRecord() {
    setState(() {
      _paymentRecords.add({
        'invoiceNumber':
            'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'date': DateTime.now(),
        'totalAmount': 0.0,
        'paidAmount': 0.0,
        'pendingAmount': 0.0,
      });
    });
  }

  void _updatePaymentRecord(int index, Map<String, dynamic> record) {
    setState(() {
      _paymentRecords[index] = record;
    });
  }

  double _calculateTotalPending() {
    return _paymentRecords.fold(
      0.0,
      (sum, record) => sum + record['pendingAmount'],
    );
  }

  double _calculateTotalPaid() {
    return _paymentRecords.fold(
      0.0,
      (sum, record) => sum + record['paidAmount'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1845),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Customer: ${widget.customer['name']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Customer Info Summary
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1845).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF0D1845)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customer['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        Text(
                          'CNIC: ${widget.customer['cnic']} | Phone: ${widget.customer['phone']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Pending: Rs. ${_calculateTotalPending().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Total Paid: Rs. ${_calculateTotalPaid().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF28A745),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Payment Records
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Records',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addPaymentRecord,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1845),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Invoice Number',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total Amount',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Paid Amount',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Pending Amount',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Payment Records List
                    ..._paymentRecords.map((record) {
                      final index = _paymentRecords.indexOf(record);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(record['invoiceNumber']),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(record['date']),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Rs. ${record['totalAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Rs. ${record['paidAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Rs. ${record['pendingAmount'].toStringAsFixed(2)}',
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () =>
                                    _showEditPaymentDialog(index, record),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final updatedCustomer = Map<String, dynamic>.from(
                        widget.customer,
                      );
                      updatedCustomer['paymentRecords'] = _paymentRecords;
                      updatedCustomer['totalPending'] =
                          _calculateTotalPending();
                      updatedCustomer['paidAmount'] = _calculateTotalPaid();
                      Navigator.of(context).pop(updatedCustomer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPaymentDialog(int index, Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => EditPaymentDialog(
        record: record,
        onSave: (updatedRecord) => _updatePaymentRecord(index, updatedRecord),
      ),
    );
  }
}

class EditPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> record;
  final Function(Map<String, dynamic>) onSave;

  const EditPaymentDialog({
    super.key,
    required this.record,
    required this.onSave,
  });

  @override
  State<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  late TextEditingController _totalAmountController;
  late TextEditingController _paidAmountController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _totalAmountController = TextEditingController(
      text: widget.record['totalAmount'].toString(),
    );
    _paidAmountController = TextEditingController(
      text: widget.record['paidAmount'].toString(),
    );
    _selectedDate = widget.record['date'];
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  double _calculatePending() {
    final total = double.tryParse(_totalAmountController.text) ?? 0.0;
    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return total - paid;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Payment Record'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _totalAmountController,
            decoration: const InputDecoration(
              labelText: 'Total Amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paidAmountController,
            decoration: const InputDecoration(
              labelText: 'Paid Amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pending Amount: Rs. ${_calculatePending().toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedRecord = {
              'invoiceNumber': widget.record['invoiceNumber'],
              'date': _selectedDate,
              'totalAmount':
                  double.tryParse(_totalAmountController.text) ?? 0.0,
              'paidAmount': double.tryParse(_paidAmountController.text) ?? 0.0,
              'pendingAmount': _calculatePending(),
            };
            widget.onSave(updatedRecord);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

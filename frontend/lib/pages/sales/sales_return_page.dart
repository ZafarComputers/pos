import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sales_service.dart';

class SalesReturnPage extends StatefulWidget {
  const SalesReturnPage({super.key});

  @override
  State<SalesReturnPage> createState() => _SalesReturnPageState();
}

class _SalesReturnPageState extends State<SalesReturnPage> {
  late List<SalesReturn> _salesReturns = [];
  late bool _isLoading = false;
  late String _errorMessage = '';
  late bool _showAddReturnDialog = false;
  late String _selectedCustomer = 'All';
  late String _sortBy = 'All';
  late String _selectedCustomerType = 'Normal Customer';
  late DateTime _selectedReturnDate = DateTime.now();
  late List<Map<String, dynamic>> _invoiceProducts = [];
  late bool _isLoadingInvoice = false;
  late String _invoiceError = '';
  late List<Map<String, dynamic>> _selectedProducts = [];

  // Pagination variables
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool _isSubmittingReturn = false;

  // Invoice data
  late int _invoiceCustomerId = 0;
  late int _invoicePosId = 0;

  // Filtered data for pagination
  List<SalesReturn> _allFilteredReturns = [];
  List<SalesReturn> _filteredReturns = [];

  // Edit form state variables
  late DateTime _editReturnDate = DateTime.now();
  late List<Map<String, dynamic>> _editProducts = [];
  late String _editReason = '';
  late TextEditingController _editReasonController = TextEditingController();

  // Action dialog states
  late bool _showViewDialog = false;
  late bool _showEditDialog = false;
  late bool _showDeleteDialog = false;
  late SalesReturn? _currentReturn = null;
  late bool _isLoadingAction = false;

  // Controllers
  late TextEditingController _returnReasonController = TextEditingController();
  late TextEditingController _cnicController = TextEditingController();
  late TextEditingController _invoiceNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSalesReturns();
  }

  @override
  void dispose() {
    _returnReasonController.dispose();
    _cnicController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesReturns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await SalesService.getSalesReturns();

      setState(() {
        _salesReturns = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sales returns: $e';
        _isLoading = false;
      });
    }
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

    String? cnic;
    if (_selectedCustomerType == 'Credit Customer') {
      cnic = _cnicController.text.trim();
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

    try {
      final invoiceResponse = await SalesService.getInvoiceByNumber(
        invoiceNumber,
        cnic: cnic,
      );
      setState(() {
        _invoiceCustomerId = _selectedCustomerType == 'Normal Customer'
            ? 1
            : invoiceResponse.customerId; // Default for normal
        _invoicePosId = invoiceResponse.posId > 0
            ? invoiceResponse.posId
            : 1; // Default to 1 if invalid
        _invoiceProducts = invoiceResponse.details.map((detail) {
          return {
            'id': detail.id.toString(),
            'productId': detail.productId,
            'name': detail.productName,
            'quantity': int.tryParse(detail.quantity) ?? 1,
            'price': double.tryParse(detail.price) ?? 0.0,
            'isSelected': false,
            'returnQuantityController': TextEditingController(text: '1'),
          };
        }).toList();
        _isLoadingInvoice = false;
      });
    } catch (e) {
      setState(() {
        _invoiceError =
            'Invoice not found or no products available for return: $e';
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

    try {
      // Calculate totals for selected products
      double totalAmount = 0.0;
      final details = selectedProducts.map((product) {
        final quantity =
            int.tryParse(product['returnQuantityController'].text) ??
            product['quantity'];
        final unitPrice = product['price'];
        totalAmount += unitPrice * quantity;
        return {
          'product_id': int.tryParse(product['productId']) ?? 0,
          'qty': quantity,
          'return_unit_price': unitPrice,
        };
      }).toList();

      final returnData = {
        'customer_id': _invoiceCustomerId,
        'invRet_date': DateFormat('yyyy-MM-dd').format(_selectedReturnDate),
        'return_inv_amout': totalAmount.toStringAsFixed(2),
        'details': details,
      };

      // Only include pos_id if it's valid
      if (_invoicePosId > 0) {
        returnData['pos_id'] = _invoicePosId;
      }

      final newReturn = await SalesService.createSalesReturn(returnData);

      setState(() {
        _salesReturns.insert(0, newReturn);
        _isSubmittingReturn = false;
        _showAddReturnDialog = false;
      });

      // Reset form
      _resetForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return created successfully')),
      );
    } catch (e) {
      setState(() {
        _isSubmittingReturn = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create return: $e')));
    }
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
      _invoiceCustomerId = 0;
      _invoicePosId = 0;
    });
  }

  List<SalesReturn> _getFilteredReturns() {
    // Apply filters to get all filtered returns
    _allFilteredReturns = _salesReturns.where((returnItem) {
      final customerMatch =
          _selectedCustomer == 'All' ||
          returnItem.customer.name == _selectedCustomer;

      // Date filtering based on sortBy
      bool dateMatch = true;
      if (_sortBy == 'Last 7 Days') {
        try {
          final returnDate = DateTime.parse(returnItem.invRetDate);
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          dateMatch = returnDate.isAfter(sevenDaysAgo);
        } catch (e) {
          dateMatch = true; // If date parsing fails, include the item
        }
      }

      return customerMatch && dateMatch;
    }).toList();

    // Apply pagination
    _paginateFilteredReturns();

    return _filteredReturns;
  }

  // Apply pagination to filtered returns
  void _paginateFilteredReturns() {
    try {
      // Handle empty results case
      if (_allFilteredReturns.isEmpty) {
        setState(() {
          _filteredReturns = [];
        });
        return;
      }

      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      // Ensure startIndex is not greater than the list length
      if (startIndex >= _allFilteredReturns.length) {
        // Reset to page 1 if current page is out of bounds
        setState(() {
          currentPage = 1;
        });
        _paginateFilteredReturns(); // Recursive call with corrected page
        return;
      }

      setState(() {
        _filteredReturns = _allFilteredReturns.sublist(
          startIndex,
          endIndex > _allFilteredReturns.length
              ? _allFilteredReturns.length
              : endIndex,
        );
      });
    } catch (e) {
      setState(() {
        _filteredReturns = [];
        currentPage = 1;
      });
    }
  }

  // Check if we can go to the next page
  bool _canGoToNextPage() {
    final totalPages = _getTotalPages();
    return currentPage < totalPages;
  }

  // Get total number of pages
  int _getTotalPages() {
    if (_allFilteredReturns.isEmpty) return 1;
    return (_allFilteredReturns.length / itemsPerPage).ceil();
  }

  // Change page
  void _changePage(int page) {
    if (page < 1 || page > _getTotalPages()) return;

    setState(() {
      currentPage = page;
    });
    _paginateFilteredReturns();
  }

  // Build page number buttons
  List<Widget> _buildPageButtons() {
    final totalPages = _getTotalPages();
    final current = currentPage;

    // Show max 5 page buttons centered around current page
    const maxButtons = 5;
    final halfRange = maxButtons ~/ 2; // 2

    // Calculate desired start and end
    int startPage = (current - halfRange).clamp(1, totalPages);
    int endPage = (startPage + maxButtons - 1).clamp(1, totalPages);

    // If endPage exceeds totalPages, adjust startPage
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = (endPage - maxButtons + 1).clamp(1, totalPages);
    }

    List<Widget> buttons = [];

    for (int i = startPage; i <= endPage; i++) {
      buttons.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          child: ElevatedButton(
            onPressed: i == current ? null : () => _changePage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor: i == current
                  ? const Color(0xFF17A2B8)
                  : Colors.white,
              foregroundColor: i == current
                  ? Colors.white
                  : const Color(0xFF6C757D),
              elevation: i == current ? 2 : 0,
              side: i == current
                  ? null
                  : const BorderSide(color: Color(0xFFDEE2E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(32, 32),
            ),
            child: Text(
              i.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
        ),
      );
    }

    return buttons;
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

                // Error message display
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = '';
                            });
                          },
                          icon: Icon(Icons.close, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                                              ..._salesReturns
                                                  .map(
                                                    (returnItem) => returnItem
                                                        .customer
                                                        .name,
                                                  )
                                                  .toSet(),
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
                                          currentPage =
                                              1; // Reset to page 1 when filter changes
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
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
                                    bottom: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Return ID',
                                        style: _headerStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Product',
                                        style: _headerStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Date',
                                        style: _headerStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Customer Name',
                                        style: _headerStyle(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Status',
                                        style: _headerStyle(),
                                      ),
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
                                      child: Text(
                                        'Actions',
                                        style: _headerStyle(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Table Body
                              Expanded(
                                child: filteredReturns.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.assignment_return,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No sales returns found',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: filteredReturns.length,
                                        itemBuilder: (context, index) {
                                          final returnItem =
                                              filteredReturns[index];
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
                                                    returnItem.id.toString(),
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
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          border: Border.all(
                                                            color: Color(
                                                              0xFFDEE2E6,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          Icons.inventory_2,
                                                          color: Color(
                                                            0xFF6C757D,
                                                          ),
                                                          size: 18,
                                                        ),
                                                      ),
                                                      SizedBox(width: 12),
                                                      Text(
                                                        returnItem
                                                                .details
                                                                .isNotEmpty
                                                            ? returnItem
                                                                  .details
                                                                  .first
                                                                  .productName
                                                            : 'N/A',
                                                        style: _cellStyle(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    returnItem
                                                            .invRetDate
                                                            .isNotEmpty
                                                        ? DateFormat(
                                                            'dd MMM yyyy',
                                                          ).format(
                                                            DateTime.parse(
                                                              returnItem
                                                                  .invRetDate,
                                                            ),
                                                          )
                                                        : 'N/A',
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    returnItem
                                                            .customer
                                                            .name
                                                            .isNotEmpty
                                                        ? returnItem
                                                              .customer
                                                              .name
                                                        : 'Walk-in',
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Active',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.green[800],
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    'Rs. 0.00',
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    'Rs. ${double.tryParse(returnItem.returnInvAmount)?.toStringAsFixed(2) ?? '0.00'}',
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
                                                          color: const Color(
                                                            0xFF0D1845,
                                                          ),
                                                          size: 18,
                                                        ),
                                                        onPressed: () =>
                                                            _viewReturnDetails(
                                                              returnItem,
                                                            ),
                                                        tooltip: 'View Details',
                                                        padding:
                                                            const EdgeInsets.all(
                                                              6,
                                                            ),
                                                        constraints:
                                                            const BoxConstraints(),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.edit,
                                                          color: Colors.blue,
                                                          size: 18,
                                                        ),
                                                        onPressed: () =>
                                                            _editReturn(
                                                              returnItem,
                                                            ),
                                                        tooltip: 'Edit',
                                                        padding:
                                                            const EdgeInsets.all(
                                                              6,
                                                            ),
                                                        constraints:
                                                            const BoxConstraints(),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                          size: 18,
                                                        ),
                                                        onPressed: () =>
                                                            _deleteReturn(
                                                              returnItem.id
                                                                  .toString(),
                                                            ),
                                                        tooltip: 'Delete',
                                                        padding:
                                                            const EdgeInsets.all(
                                                              6,
                                                            ),
                                                        constraints:
                                                            const BoxConstraints(),
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

                              // Pagination Controls
                              if (_allFilteredReturns.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Previous button
                                      ElevatedButton.icon(
                                        onPressed: currentPage > 1
                                            ? () => _changePage(currentPage - 1)
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_left,
                                          size: 14,
                                        ),
                                        label: Text(
                                          'Previous',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: currentPage > 1
                                              ? const Color(0xFF17A2B8)
                                              : const Color(0xFF6C757D),
                                          elevation: 0,
                                          side: BorderSide(
                                            color: const Color(0xFFDEE2E6),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // Page numbers
                                      ..._buildPageButtons(),

                                      const SizedBox(width: 8),

                                      // Next button
                                      ElevatedButton.icon(
                                        onPressed: _canGoToNextPage()
                                            ? () => _changePage(currentPage + 1)
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_right,
                                          size: 14,
                                        ),
                                        label: Text(
                                          'Next',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _canGoToNextPage()
                                              ? const Color(0xFF17A2B8)
                                              : Colors.grey.shade300,
                                          foregroundColor: _canGoToNextPage()
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          elevation: _canGoToNextPage() ? 2 : 0,
                                          side: _canGoToNextPage()
                                              ? null
                                              : BorderSide(
                                                  color: const Color(
                                                    0xFFDEE2E6,
                                                  ),
                                                ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                        ),
                                      ),

                                      // Page info
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FA),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Page $currentPage of ${_getTotalPages()} (${_allFilteredReturns.length} total)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6C757D),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),

            // Add Return Dialog
            ...(_showAddReturnDialog ? [_buildAddReturnDialog()] : []),

            // View Return Dialog
            ...(_showViewDialog ? [_buildViewReturnDialog()] : []),

            // Edit Return Dialog
            ...(_showEditDialog ? [_buildEditReturnDialog()] : []),

            // Delete Confirmation Dialog
            ...(_showDeleteDialog ? [_buildDeleteConfirmationDialog()] : []),
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

  void _viewReturnDetails(SalesReturn returnItem) async {
    setState(() {
      _isLoadingAction = true;
      _currentReturn = returnItem;
    });

    try {
      final salesReturn = await SalesService.getSalesReturnById(
        returnItem.id.toString(),
      );
      setState(() {
        _currentReturn = salesReturn;
        _showViewDialog = true;
        _isLoadingAction = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAction = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load return details: $e')),
      );
    }
  }

  void _editReturn(SalesReturn returnItem) async {
    setState(() {
      _isLoadingAction = true;
      _currentReturn = returnItem;
    });

    try {
      final salesReturn = await SalesService.getSalesReturnById(
        returnItem.id.toString(),
      );
      setState(() {
        _currentReturn = salesReturn;
        // Initialize edit form data
        _editReturnDate = salesReturn.invRetDate.isNotEmpty
            ? DateTime.parse(salesReturn.invRetDate)
            : DateTime.now();
        _editReason = ''; // Initialize with empty or from model if available
        _editReasonController.text = _editReason;
        _editProducts = salesReturn.details.map((detail) {
          return {
            'id': detail.id,
            'productId': detail.productId,
            'productName': detail.productName,
            'quantity': detail.qty,
            'unitPrice': detail.returnUnitPrice,
            'total': detail.total,
            'quantityController': TextEditingController(text: detail.qty),
            'priceController': TextEditingController(
              text: detail.returnUnitPrice,
            ),
          };
        }).toList();
        _showEditDialog = true;
        _isLoadingAction = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAction = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load return details for editing: $e'),
        ),
      );
    }
  }

  void _deleteReturn(String returnId) {
    setState(() {
      _currentReturn = _salesReturns.firstWhere(
        (r) => r.id.toString() == returnId,
      );
      _showDeleteDialog = true;
    });
  }

  Future<void> _confirmDeleteReturn() async {
    if (_currentReturn == null) return;

    setState(() {
      _isLoadingAction = true;
    });

    try {
      await SalesService.deleteSalesReturn(_currentReturn!.id.toString(), {});
      setState(() {
        _salesReturns.removeWhere((r) => r.id == _currentReturn!.id);
        _showDeleteDialog = false;
        _currentReturn = null;
        _isLoadingAction = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return deleted successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoadingAction = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete return: $e')));
    }
  }

  Future<void> _submitEditReturn() async {
    if (_currentReturn == null) return;

    // Validate form data
    if (_editReason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a return reason')),
      );
      return;
    }

    // Validate product quantities and prices
    for (final product in _editProducts) {
      final qty = int.tryParse(product['quantityController'].text) ?? 0;
      final price = double.tryParse(product['priceController'].text) ?? 0.0;

      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid quantity for ${product['productName']}'),
          ),
        );
        return;
      }

      if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid price for ${product['productName']}'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoadingAction = true;
    });

    try {
      // Prepare updated data
      final updatedDetails = _editProducts.map((product) {
        final qty = int.tryParse(product['quantityController'].text) ?? 0;
        final price = double.tryParse(product['priceController'].text) ?? 0.0;
        final total = qty * price;

        return {
          'id': product['id'],
          'product_id': product['productId'],
          'product_name': product['productName'],
          'qty': qty.toString(),
          'return_unit_price': price.toString(),
          'total': total,
        };
      }).toList();

      // Calculate new total amount
      final newTotalAmount = updatedDetails.fold<double>(
        0.0,
        (sum, detail) => sum + (detail['total'] as double),
      );

      final updateData = {
        'id': _currentReturn!.id,
        'customer_id': _currentReturn!.customer.id,
        'invRet_date': DateFormat('yyyy-MM-dd').format(_editReturnDate),
        'return_inv_amout': newTotalAmount.toStringAsFixed(2),
        'pos_id': _currentReturn!.posId,
        'details': updatedDetails,
        'reason': _editReason.trim(),
      };

      await SalesService.updateSalesReturn(
        _currentReturn!.id.toString(),
        updateData,
      );

      setState(() {
        _showEditDialog = false;
        _currentReturn = null;
        _isLoadingAction = false;
        // Clear edit form data
        _editProducts.clear();
        _editReasonController.clear();
        _editReason = '';
      });

      // Refresh the list
      _loadSalesReturns();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoadingAction = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update return: $e')));
    }
  }

  void _closeViewDialog() {
    setState(() {
      _showViewDialog = false;
      _currentReturn = null;
    });
  }

  void _closeEditDialog() {
    setState(() {
      _showEditDialog = false;
      _currentReturn = null;
    });
  }

  void _closeDeleteDialog() {
    setState(() {
      _showDeleteDialog = false;
      _currentReturn = null;
    });
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

  Widget _buildViewReturnDialog() {
    if (_currentReturn == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.7,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Dialog Header
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assignment_return,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Return Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _closeViewDialog,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Dialog Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Return Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(
                                    'Return ID',
                                    '#${_currentReturn!.id}',
                                    Icons.receipt_long,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoItem(
                                    'Date',
                                    _currentReturn!.invRetDate.isNotEmpty
                                        ? DateFormat('dd MMM yyyy').format(
                                            DateTime.parse(
                                              _currentReturn!.invRetDate,
                                            ),
                                          )
                                        : 'N/A',
                                    Icons.calendar_today,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(
                                    'Amount',
                                    'Rs. ${double.tryParse(_currentReturn!.returnInvAmount)?.toStringAsFixed(2) ?? '0.00'}',
                                    Icons.receipt,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoItem(
                                    'POS ID',
                                    _currentReturn!.posId,
                                    Icons.point_of_sale,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Customer Information
                      const Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1845).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF0D1845),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentReturn!.customer.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D1845),
                                    ),
                                  ),
                                  Text(
                                    'Customer ID: ${_currentReturn!.customer.id}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Products Section
                      Row(
                        children: [
                          const Text(
                            'Returned Products',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1845),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1845).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentReturn!.details.length} item${_currentReturn!.details.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0D1845),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_currentReturn!.details.isNotEmpty) ...[
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _currentReturn!.details.length,
                            itemBuilder: (context, index) {
                              final detail = _currentReturn!.details[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border:
                                      index < _currentReturn!.details.length - 1
                                      ? Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade100,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0D1845,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2,
                                        color: Color(0xFF0D1845),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            detail.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D1845),
                                            ),
                                          ),
                                          Text(
                                            'ID: ${detail.productId}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Qty: ${detail.qty}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${detail.total.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Text(
                              'No product details available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
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

  Widget _buildEditReturnDialog() {
    if (_currentReturn == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.8,
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Dialog Header
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Sales Return',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _closeEditDialog,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Dialog Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Return Information
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(
                                    'Return ID',
                                    '#${_currentReturn!.id}',
                                    Icons.receipt_long,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoItem(
                                    'Customer',
                                    _currentReturn!.customer.name,
                                    Icons.person,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Edit Form
                      const Text(
                        'Edit Return Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Return Date
                      const Text(
                        'Return Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _editReturnDate,
                            firstDate: DateTime(2010),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: const Color(0xFF0D1845),
                                    onPrimary: Colors.white,
                                    onSurface: const Color(0xFF343A40),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != _editReturnDate) {
                            setState(() {
                              _editReturnDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF0D1845),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(_editReturnDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0D1845),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Return Reason
                      const Text(
                        'Return Reason',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _editReasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter reason for return...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        onChanged: (value) {
                          _editReason = value;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Products Section
                      Row(
                        children: [
                          const Text(
                            'Edit Product Quantities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1845),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1845).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_editProducts.length} item${_editProducts.length != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0D1845),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _editProducts.length,
                          itemBuilder: (context, index) {
                            final product = _editProducts[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: index < _editProducts.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0D1845,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2,
                                      color: Color(0xFF0D1845),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['productName'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0D1845),
                                          ),
                                        ),
                                        Text(
                                          'ID: ${product['productId']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Quantity',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF6C757D),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 32,
                                          child: TextField(
                                            controller:
                                                product['quantityController'],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              isDense: true,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Unit Price',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF6C757D),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          height: 32,
                                          child: TextField(
                                            controller:
                                                product['priceController'],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              isDense: true,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6C757D),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (context) {
                                          final qty =
                                              int.tryParse(
                                                product['quantityController']
                                                    .text,
                                              ) ??
                                              0;
                                          final price =
                                              double.tryParse(
                                                product['priceController'].text,
                                              ) ??
                                              0.0;
                                          final total = qty * price;
                                          return Text(
                                            'Rs. ${total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D1845),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingAction
                                  ? null
                                  : _submitEditReturn,
                              icon: _isLoadingAction
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
                                  : const Icon(Icons.save, size: 18),
                              label: Text(
                                _isLoadingAction
                                    ? 'Updating...'
                                    : 'Update Return',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D1845),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _closeEditDialog,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              side: const BorderSide(color: Colors.grey),
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
      ),
    );
  }

  Widget _buildDeleteConfirmationDialog() {
    if (_currentReturn == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 48,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'Delete Sales Return',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1845),
                ),
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                'Are you sure you want to delete return #${_currentReturn!.id}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),

              const SizedBox(height: 24),

              // Return Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(_currentReturn!.customer.name),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Rs. ${double.tryParse(_currentReturn!.returnInvAmount)?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closeDeleteDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingAction ? null : _confirmDeleteReturn,
                      icon: _isLoadingAction
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.delete_forever),
                      label: Text(_isLoadingAction ? 'Deleting...' : 'Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1845).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF0D1845), size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
        ),
      ],
    );
  }
}

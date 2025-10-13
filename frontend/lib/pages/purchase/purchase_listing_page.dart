import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'create_purchase_page.dart';
import '../../services/purchases_service.dart';

class PurchaseListingPage extends StatefulWidget {
  const PurchaseListingPage({super.key});

  @override
  State<PurchaseListingPage> createState() => _PurchaseListingPageState();
}

class _PurchaseListingPageState extends State<PurchaseListingPage> {
  // API data
  List<Purchase> _purchases = [];
  List<Purchase> _filteredPurchases = [];
  List<Purchase> _allFilteredPurchases =
      []; // Store all filtered purchases for local pagination
  List<Purchase> _allPurchasesCache =
      []; // Cache for all purchases to avoid refetching
  bool _isLoading = true;
  String? _errorMessage;
  int currentPage = 1;
  final int itemsPerPage = 10;

  // Filter states
  String _selectedStatus = 'All';
  String _selectedPaymentStatus = 'All';
  String _sortBy = 'Last 7 Days';

  @override
  void initState() {
    super.initState();
    _fetchAllPurchasesOnInit();
  }

  // Fetch all purchases once when page loads
  Future<void> _fetchAllPurchasesOnInit() async {
    try {
      print('🚀 Initial load: Fetching all purchases');
      setState(() {
        _errorMessage = null;
      });

      // Fetch all purchases from all pages
      List<Purchase> allPurchases = [];
      int currentFetchPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          print('📡 Fetching page $currentFetchPage');
          final response = await PurchaseService.getPurchases(
            page: currentFetchPage,
            perPage: 50, // Use larger page size for efficiency
          );

          allPurchases.addAll(response.data);
          print(
            '📦 Page $currentFetchPage: ${response.data.length} purchases (total: ${allPurchases.length})',
          );

          // Check if there are more pages
          if (response.meta.currentPage >= response.meta.lastPage) {
            hasMorePages = false;
          } else {
            currentFetchPage++;
          }
        } catch (e) {
          print('❌ Error fetching page $currentFetchPage: $e');
          hasMorePages = false; // Stop fetching on error
        }
      }

      _allPurchasesCache = allPurchases;
      print('💾 Cached ${_allPurchasesCache.length} total purchases');

      // Apply initial filters (which will be no filters, showing all purchases)
      _applyFiltersClientSide();
    } catch (e) {
      print('❌ Critical error in _fetchAllPurchasesOnInit: $e');
      setState(() {
        _errorMessage = 'Failed to load purchases. Please refresh the page.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await PurchaseService.getPurchases();
      setState(() {
        _purchases = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load purchases: $e';
        _isLoading = false;
      });
    }
  }

  // Client-side only filter application
  void _applyFilters() {
    print('🎯 _applyFilters called - performing client-side filtering only');
    _applyFiltersClientSide();
  }

  // Pure client-side filtering method
  void _applyFiltersClientSide() {
    try {
      print(
        '🎯 Client-side filtering - status: "$_selectedStatus", payment: "$_selectedPaymentStatus"',
      );

      // Apply filters to cached purchases (no API calls)
      _filterCachedPurchases();

      print('📦 _allPurchasesCache.length: ${_allPurchasesCache.length}');
      print('🎯 _allFilteredPurchases.length: ${_allFilteredPurchases.length}');
      print('👀 _filteredPurchases.length: ${_filteredPurchases.length}');
    } catch (e) {
      print('❌ Error in _applyFiltersClientSide: $e');
      setState(() {
        _errorMessage = 'Search error: Please try a different search term';
        _isLoading = false;
        _filteredPurchases = [];
      });
    }
  }

  // Filter cached purchases without any API calls
  void _filterCachedPurchases() {
    try {
      // Apply filters to cached purchases
      _allFilteredPurchases = _allPurchasesCache.where((purchase) {
        try {
          // Status filter (derived from payment status)
          final derivedStatus = purchase.paymentStatus.toLowerCase() == 'paid'
              ? 'Completed'
              : 'Pending';
          if (_selectedStatus != 'All' && derivedStatus != _selectedStatus) {
            return false;
          }

          // Payment status filter
          if (_selectedPaymentStatus != 'All' &&
              purchase.paymentStatus != _selectedPaymentStatus) {
            return false;
          }

          return true;
        } catch (e) {
          // If there's any error during filtering, exclude this purchase
          print('⚠️ Error filtering purchase ${purchase.purInvId}: $e');
          return false;
        }
      }).toList();

      print(
        '🔍 After filtering: ${_allFilteredPurchases.length} purchases match criteria',
      );
      print(
        '📝 Status filter: "$_selectedStatus", Payment filter: "$_selectedPaymentStatus"',
      );

      // Apply local pagination to filtered results
      _paginateFilteredPurchases();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Critical error in _filterCachedPurchases: $e');
      setState(() {
        _errorMessage =
            'Search failed. Please try again with a simpler search term.';
        _isLoading = false;
        // Fallback: show empty results instead of crashing
        _filteredPurchases = [];
        _allFilteredPurchases = [];
      });
    }
  }

  // Apply local pagination to filtered purchases
  void _paginateFilteredPurchases() {
    try {
      // Handle empty results case
      if (_allFilteredPurchases.isEmpty) {
        setState(() {
          _filteredPurchases = [];
        });
        return;
      }

      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      // Ensure startIndex is not greater than the list length
      if (startIndex >= _allFilteredPurchases.length) {
        // Reset to page 1 if current page is out of bounds
        setState(() {
          currentPage = 1;
        });
        _paginateFilteredPurchases(); // Recursive call with corrected page
        return;
      }

      setState(() {
        _filteredPurchases = _allFilteredPurchases.sublist(
          startIndex,
          endIndex > _allFilteredPurchases.length
              ? _allFilteredPurchases.length
              : endIndex,
        );
      });
    } catch (e) {
      print('❌ Error in _paginateFilteredPurchases: $e');
      setState(() {
        _filteredPurchases = [];
        currentPage = 1;
      });
    }
  }

  // Handle page changes for both filtered and normal pagination
  Future<void> _changePage(int newPage) async {
    setState(() {
      currentPage = newPage;
    });

    // Always use client-side pagination when we have cached purchases
    if (_allPurchasesCache.isNotEmpty) {
      _paginateFilteredPurchases();
    } else {
      // Fallback to server pagination only if no cached data
      await _fetchPurchases(page: newPage);
    }
  }

  Future<void> _fetchPurchases({int page = 1}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await PurchaseService.getPurchases(
        page: page,
        perPage: itemsPerPage,
      );
      setState(() {
        _purchases = response.data;
        currentPage = page;
        _isLoading = false;
        _filteredPurchases = response.data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateSelectAllState() {
    // This method is kept for future use if selection is re-implemented
  }

  List<Purchase> _getFilteredPurchases() {
    return _purchases.where((purchase) {
      // Derive status from payment status for filtering
      final derivedStatus = purchase.paymentStatus.toLowerCase() == 'paid'
          ? 'Completed'
          : 'Pending';
      final statusMatch =
          _selectedStatus == 'All' || derivedStatus == _selectedStatus;
      final paymentMatch =
          _selectedPaymentStatus == 'All' ||
          purchase.paymentStatus == _selectedPaymentStatus;

      // Date filtering based on sortBy
      bool dateMatch = true;
      if (_sortBy == 'Last 7 Days') {
        try {
          final purchaseDate = DateTime.parse(purchase.createdAt);
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          dateMatch = purchaseDate.isAfter(sevenDaysAgo);
        } catch (e) {
          // If date parsing fails, include the purchase
          dateMatch = true;
        }
      }

      return statusMatch && paymentMatch && dateMatch;
    }).toList();
  }

  // View purchase details
  Future<void> _viewPurchaseDetails(String purchaseId) async {
    // Show dialog immediately with loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _LoadingPurchaseDialog();
      },
    );

    try {
      final purchase = await PurchaseService.getPurchaseById(purchaseId);

      // Close loading dialog and show details dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showPurchaseDetailsDialog(purchase);
      }
    } catch (e) {
      // Close loading dialog and show error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load purchase details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show purchase details dialog
  void _showPurchaseDetailsDialog(Purchase purchase) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1845),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purchase Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Invoice: ${purchase.purInvBarcode}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Purchase Information
                        _buildDetailSection(
                          'Purchase Information',
                          Icons.info,
                          [
                            _buildDetailRow(
                              'Invoice ID',
                              purchase.purInvId.toString(),
                            ),
                            _buildDetailRow('Barcode', purchase.purInvBarcode),
                            _buildDetailRow(
                              'Date',
                              purchase.purDate.isNotEmpty
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(DateTime.parse(purchase.purDate))
                                  : 'N/A',
                            ),
                            _buildDetailRow('Vendor', purchase.vendorName),
                            _buildDetailRow(
                              'Vendor Invoice No',
                              purchase.venInvNo,
                            ),
                            _buildDetailRow(
                              'Vendor Invoice Date',
                              purchase.venInvDate.isNotEmpty
                                  ? DateFormat('dd MMM yyyy').format(
                                      DateTime.parse(purchase.venInvDate),
                                    )
                                  : 'N/A',
                            ),
                            _buildDetailRow('Reference', purchase.venInvRef),
                            _buildDetailRow(
                              'Description',
                              purchase.description,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Financial Information
                        _buildDetailSection(
                          'Financial Information',
                          Icons.account_balance_wallet,
                          [
                            _buildDetailRow(
                              'Total Amount',
                              'Rs. ${double.tryParse(purchase.invAmount)?.toStringAsFixed(2) ?? '0.00'}',
                            ),
                            _buildDetailRow(
                              'Discount Percent',
                              '${purchase.discountPercent}%',
                            ),
                            _buildDetailRow(
                              'Discount Amount',
                              'Rs. ${purchase.discountAmt}',
                            ),
                            _buildDetailRow(
                              'Payment Status',
                              purchase.paymentStatus.toUpperCase(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Purchase Details
                        Text(
                          'Purchase Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1845),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: const BorderRadius.only(
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
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Unit Price',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Discount',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Amount',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Items
                              ...purchase.purDetails.map((detail) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.grey[200]!),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(detail.productName),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(detail.quantity),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('Rs. ${detail.unitPrice}'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('Rs. ${detail.discAmount}'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('Rs. ${detail.amount}'),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
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
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF0D1845), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1845),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[900])),
          ),
        ],
      ),
    );
  }

  // Delete purchase
  Future<void> _deletePurchase(
    String purchaseId,
    String purchaseBarcode,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Text('Delete Purchase'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete purchase "$purchaseBarcode"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await PurchaseService.deletePurchase(purchaseId);

        // Remove from local cache
        _allPurchasesCache.removeWhere(
          (purchase) => purchase.purInvId.toString() == purchaseId,
        );

        // Re-apply filters to update the display
        _applyFiltersClientSide();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete purchase: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Edit purchase
  Future<void> _editPurchase(String purchaseId) async {
    // Show dialog immediately with loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _LoadingPurchaseDialog();
      },
    );

    try {
      final purchase = await PurchaseService.getPurchaseById(purchaseId);

      // Close loading dialog and show edit dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showEditPurchaseDialog(purchase);
      }
    } catch (e) {
      // Close loading dialog and show error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load purchase for editing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show edit purchase dialog
  void _showEditPurchaseDialog(Purchase purchase) {
    // Controllers for form fields
    final _editReferenceController = TextEditingController(
      text: purchase.venInvRef,
    );
    final _editOrderDiscountController = TextEditingController(
      text: (purchase.discountAmt.isNotEmpty) ? purchase.discountAmt : '0',
    );
    final _editNotesController = TextEditingController(
      text: purchase.description,
    );

    DateTime _editSelectedDate = purchase.purDate.isNotEmpty
        ? DateTime.parse(purchase.purDate)
        : DateTime.now();
    String _editSelectedStatus = purchase.paymentStatus.toLowerCase() == 'paid'
        ? 'paid'
        : 'unpaid';
    List<PurchaseItem> _editPurchaseItems = purchase.purDetails.map((detail) {
      return PurchaseItem(
        productId: int.tryParse(detail.productId),
        quantity: int.tryParse(detail.quantity) ?? 1,
        purchasePrice: double.tryParse(detail.unitPrice) ?? 0,
        discount: double.tryParse(detail.discPer) ?? 0,
        description: detail.productName,
      );
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1845),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Purchase',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Invoice: ${purchase.purInvBarcode}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Basic Information
                            Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D1845),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _editReferenceController,
                                    decoration: InputDecoration(
                                      labelText: 'Reference Number',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                            context: context,
                                            initialDate: _editSelectedDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                          );
                                      if (picked != null) {
                                        setState(() {
                                          _editSelectedDate = picked;
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Purchase Date',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_editSelectedDate),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _editNotesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description/Notes',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Financial Information
                            Text(
                              'Financial Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D1845),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _editOrderDiscountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Discount Amount',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _editSelectedStatus,
                                    decoration: InputDecoration(
                                      labelText: 'Payment Status',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    items: ['paid', 'unpaid']
                                        .map(
                                          (status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(status.toUpperCase()),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _editSelectedStatus = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Purchase Items
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Purchase Items',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D1845),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _editPurchaseItems.add(PurchaseItem());
                                    });
                                  },
                                  icon: Icon(Icons.add, size: 16),
                                  label: Text('Add Item'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0D1845),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            ..._editPurchaseItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item.description,
                                            decoration: InputDecoration(
                                              labelText: 'Product Name',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              _editPurchaseItems[index]
                                                      .description =
                                                  value;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _editPurchaseItems.removeAt(
                                                index,
                                              );
                                            });
                                          },
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          tooltip: 'Remove Item',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item.quantity
                                                .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Quantity',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              _editPurchaseItems[index]
                                                      .quantity =
                                                  int.tryParse(value) ?? 1;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item.purchasePrice
                                                .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Unit Price',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              _editPurchaseItems[index]
                                                      .purchasePrice =
                                                  double.tryParse(value) ?? 0;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: item.discount
                                                .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: 'Discount %',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              _editPurchaseItems[index]
                                                      .discount =
                                                  double.tryParse(value) ?? 0;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            const SizedBox(height: 24),

                            // Summary
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Subtotal:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Rs. ${_calculateEditSubtotal(_editPurchaseItems).toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Discount:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Rs. ${double.tryParse(_editOrderDiscountController.text) ?? 0}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Rs. ${_calculateEditGrandTotal(_editPurchaseItems, _editOrderDiscountController.text).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer
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
                            onPressed: () async {
                              // Prepare update data
                              final updateData = {
                                'pur_date': DateFormat(
                                  'yyyy-MM-dd',
                                ).format(_editSelectedDate),
                                'vendor_id': purchase.vendorId,
                                'ven_inv_no': purchase.venInvNo,
                                'ven_inv_date': purchase.venInvDate,
                                'ven_inv_ref': _editReferenceController.text,
                                'pur_inv_barcode': purchase.purInvBarcode,
                                'description': _editNotesController.text,
                                'inv_amount': _calculateEditGrandTotal(
                                  _editPurchaseItems,
                                  _editOrderDiscountController.text,
                                ).toString(),
                                'discount_percent':
                                    '0', // You might want to calculate this
                                'discount_amt':
                                    (double.tryParse(
                                              _editOrderDiscountController.text,
                                            ) ??
                                            0)
                                        .toString(),
                                'paid_amount': _editSelectedStatus == 'paid'
                                    ? _calculateEditGrandTotal(
                                        _editPurchaseItems,
                                        _editOrderDiscountController.text,
                                      ).toString()
                                    : '0',
                                'payment_status': _editSelectedStatus,
                                'details': _editPurchaseItems.map((item) {
                                  return {
                                    'product_id':
                                        item.productId?.toString() ?? '',
                                    'qty': item.quantity.toString(),
                                    'unit_price': item.purchasePrice.toString(),
                                    'discAmount':
                                        (item.purchasePrice *
                                                item.quantity *
                                                item.discount /
                                                100)
                                            .toString(),
                                  };
                                }).toList(),
                              };

                              try {
                                await PurchaseService.updatePurchase(
                                  purchase.purInvId.toString(),
                                  updateData,
                                );

                                // Refresh the purchase list
                                await _fetchAllPurchasesOnInit();

                                Navigator.of(context).pop();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Purchase updated successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update purchase: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0D1845),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update Purchase'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _calculateEditSubtotal(List<PurchaseItem> items) {
    return items.fold(
      0.0,
      (sum, item) => sum + (item.purchasePrice * item.quantity),
    );
  }

  double _calculateEditGrandTotal(
    List<PurchaseItem> items,
    String discountText,
  ) {
    double subtotal = _calculateEditSubtotal(items);
    double discount = double.tryParse(discountText) ?? 0;
    return subtotal - discount;
  }

  bool _canGoToNextPage() {
    final totalPages = _getTotalPages();
    return currentPage < totalPages;
  }

  int _getTotalPages() {
    if (_allFilteredPurchases.isEmpty) return 1;
    return (_allFilteredPurchases.length / itemsPerPage).ceil();
  }

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
          margin: EdgeInsets.symmetric(horizontal: 1),
          child: ElevatedButton(
            onPressed: i == current ? null : () => _changePage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor: i == current ? Color(0xFF17A2B8) : Colors.white,
              foregroundColor: i == current ? Colors.white : Color(0xFF6C757D),
              elevation: i == current ? 2 : 0,
              side: i == current ? null : BorderSide(color: Color(0xFFDEE2E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size(32, 32),
            ),
            child: Text(
              i.toString(),
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
        ),
      );
    }

    return buttons;
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
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return const Color(0xFF28A745); // Green
      case 'unpaid':
        return const Color(0xFFDC3545); // Red
      case 'partial':
        return const Color(0xFFFFA726); // Orange
      default:
        return const Color(0xFF6C757D); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Listing'),
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
              padding: const EdgeInsets.all(16),
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
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purchase Management',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Track and manage all purchase transactions',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePurchasePage(),
                            ),
                          );

                          // If purchase was created successfully, refresh the list
                          if (result == true) {
                            await _fetchAllPurchasesOnInit();
                          }
                        },
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text('Add Purchase'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D1845),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Summary Cards
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Total Purchases',
                        '${_allPurchasesCache.length}',
                        Icons.shopping_bag,
                        const Color(0xFF2196F3),
                      ),
                      _buildSummaryCard(
                        'Total Amount',
                        'Rs. ${_getTotalPurchaseAmount().toStringAsFixed(2)}',
                        Icons.attach_money,
                        const Color(0xFF4CAF50),
                      ),
                      _buildSummaryCard(
                        'Paid Amount',
                        'Rs. ${_getTotalPaidAmount().toStringAsFixed(2)}',
                        Icons.check_circle,
                        const Color(0xFF8BC34A),
                      ),
                      _buildSummaryCard(
                        'Due Amount',
                        'Rs. ${_getTotalDueAmount().toStringAsFixed(2)}',
                        Icons.pending,
                        const Color(0xFFFF9800),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search and Table
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
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
                    // Filters Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
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
                                                      ? Icons
                                                            .inventory_2_rounded
                                                      : status == 'Completed'
                                                      ? Icons
                                                            .check_circle_rounded
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
                                          currentPage =
                                              1; // Reset to first page when filter changes
                                        });
                                        // Apply filters when status changes
                                        _applyFilters();
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
                                                      ? Icons
                                                            .account_balance_wallet
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
                                          currentPage =
                                              1; // Reset to first page when filter changes
                                        });
                                        // Apply filters when payment status changes
                                        _applyFilters();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          Expanded(
                            flex: 2,
                            child: Text('Vendor Name', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Invoice Number',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Reference Number',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Date', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Status', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Total Amount', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Paid Amount', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Due Amount', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Payment Status',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Actions', style: _headerStyle()),
                          ),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadPurchases,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _filteredPurchases.isEmpty
                          ? const Center(
                              child: Text(
                                'No purchases found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredPurchases.length,
                              itemBuilder: (context, index) {
                                final purchase = _filteredPurchases[index];
                                final derivedStatus =
                                    purchase.paymentStatus.toLowerCase() ==
                                        'paid'
                                    ? 'Completed'
                                    : 'Pending';

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
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Color(
                                                  0xFF0D1845,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                Icons.business,
                                                color: Color(0xFF0D1845),
                                                size: 16,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                purchase.vendorName.isNotEmpty
                                                    ? purchase.vendorName
                                                    : 'N/A',
                                                style: _cellStyle(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          purchase.purInvId.toString(),
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          purchase.purInvBarcode.isNotEmpty
                                              ? purchase.purInvBarcode
                                              : 'N/A',
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          purchase.purDate.isNotEmpty
                                              ? DateFormat(
                                                  'dd MMM yyyy',
                                                ).format(
                                                  DateTime.parse(
                                                    purchase.purDate,
                                                  ),
                                                )
                                              : 'N/A',
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: 100,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                derivedStatus,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              derivedStatus,
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                  derivedStatus,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Rs. ${double.tryParse(purchase.invAmount)?.toStringAsFixed(2) ?? '0.00'}',
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          purchase.paymentStatus
                                                      .toLowerCase() ==
                                                  'paid'
                                              ? 'Rs. ${double.tryParse(purchase.invAmount)?.toStringAsFixed(2) ?? '0.00'}'
                                              : 'Rs. 0.00',
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          purchase.paymentStatus
                                                      .toLowerCase() ==
                                                  'paid'
                                              ? 'Rs. 0.00'
                                              : 'Rs. ${double.tryParse(purchase.invAmount)?.toStringAsFixed(2) ?? '0.00'}',
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: 100,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPaymentStatusColor(
                                                purchase.paymentStatus,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              purchase.paymentStatus,
                                              style: TextStyle(
                                                color: _getPaymentStatusColor(
                                                  purchase.paymentStatus,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
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
                                              onPressed: () {
                                                _viewPurchaseDetails(
                                                  purchase.purInvId.toString(),
                                                );
                                              },
                                              tooltip: 'View Details',
                                              padding: const EdgeInsets.all(6),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _editPurchase(
                                                  purchase.purInvId.toString(),
                                                );
                                              },
                                              tooltip: 'Edit',
                                              padding: const EdgeInsets.all(6),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _deletePurchase(
                                                  purchase.purInvId.toString(),
                                                  purchase.purInvBarcode,
                                                );
                                              },
                                              tooltip: 'Delete',
                                              padding: const EdgeInsets.all(6),
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

                    // Enhanced Pagination
                    const SizedBox(height: 20),
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
                            icon: Icon(Icons.chevron_left, size: 14),
                            label: Text(
                              'Previous',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: currentPage > 1
                                  ? Color(0xFF17A2B8)
                                  : Color(0xFF6C757D),
                              elevation: 0,
                              side: BorderSide(color: Color(0xFFDEE2E6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.symmetric(
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
                            icon: Icon(Icons.chevron_right, size: 14),
                            label: Text('Next', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canGoToNextPage()
                                  ? Color(0xFF17A2B8)
                                  : Colors.grey.shade300,
                              foregroundColor: _canGoToNextPage()
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              elevation: _canGoToNextPage() ? 2 : 0,
                              side: _canGoToNextPage()
                                  ? null
                                  : BorderSide(color: Color(0xFFDEE2E6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                          ),

                          // Page info
                          const SizedBox(width: 16),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Page $currentPage of ${_getTotalPages()} (${_allFilteredPurchases.length} total)',
                              style: TextStyle(
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getTotalPurchaseAmount() {
    return _allFilteredPurchases.fold(
      0.0,
      (sum, purchase) => sum + (double.tryParse(purchase.invAmount) ?? 0.0),
    );
  }

  double _getTotalPaidAmount() {
    return _allFilteredPurchases.fold(
      0.0,
      (sum, purchase) =>
          sum +
          (purchase.paymentStatus.toLowerCase() == 'paid'
              ? (double.tryParse(purchase.invAmount) ?? 0.0)
              : 0.0),
    );
  }

  double _getTotalDueAmount() {
    return _allFilteredPurchases.fold(
      0.0,
      (sum, purchase) =>
          sum +
          (purchase.paymentStatus.toLowerCase() == 'paid'
              ? 0.0
              : (double.tryParse(purchase.invAmount) ?? 0.0)),
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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
}

// Loading dialog widget
class _LoadingPurchaseDialog extends StatelessWidget {
  const _LoadingPurchaseDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Loading purchase details...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF0D1845),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

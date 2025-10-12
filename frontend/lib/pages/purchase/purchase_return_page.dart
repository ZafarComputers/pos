import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/purchases_service.dart';
import 'create_purchase_return_page.dart';

class PurchaseReturnPage extends StatefulWidget {
  const PurchaseReturnPage({super.key});

  @override
  State<PurchaseReturnPage> createState() => _PurchaseReturnPageState();
}

class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
  // API data
  List<PurchaseReturn> _purchaseReturns = [];
  List<PurchaseReturn> _filteredPurchaseReturns = [];
  List<PurchaseReturn> _allFilteredPurchaseReturns =
      []; // Store all filtered purchase returns for local pagination
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool _isLoading = false;
  String _errorMessage = '';

  // Filter states
  String _selectedStatus = 'All';
  final String _sortBy = 'All Time';

  @override
  void initState() {
    super.initState();
    _loadPurchaseReturns();
  }

  Future<void> _loadPurchaseReturns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // For now, the API returns all purchase returns in one response
      // If pagination is needed from the API in the future, we can implement
      // the same multi-page loading logic as the purchase listing page
      final response = await PurchaseReturnService.getPurchaseReturns();
      setState(() {
        _purchaseReturns = response.data;
        _isLoading = false;
      });

      print('Loaded ${_purchaseReturns.length} purchase returns');

      // Apply initial filters
      _applyFiltersClientSide();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading purchase returns: $e');
    }
  }

  // Client-side only filter application
  void _applyFilters() {
    _applyFiltersClientSide();
  }

  // Pure client-side filtering method
  void _applyFiltersClientSide() {
    // Apply filters to cached purchase returns
    _allFilteredPurchaseReturns = _purchaseReturns.where((purchaseReturn) {
      // For now, we'll show all purchase returns since status isn't in the API
      // In the future, you could add status filtering based on other criteria
      bool statusMatch = true;

      // Date filtering based on sortBy
      bool dateMatch = true;
      if (_sortBy == 'Last 7 Days') {
        try {
          final date = DateTime.parse(purchaseReturn.returnDate);
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          dateMatch = date.isAfter(sevenDaysAgo);
        } catch (e) {
          // If date parsing fails, include the item
          dateMatch = true;
        }
      }
      // For 'All Time', dateMatch remains true

      return statusMatch && dateMatch;
    }).toList();

    print('Filtered to ${_allFilteredPurchaseReturns.length} purchase returns');

    // Apply local pagination to filtered results
    _paginateFilteredPurchaseReturns();

    setState(() {});
  }

  // Apply local pagination to filtered purchase returns
  void _paginateFilteredPurchaseReturns() {
    // Handle empty results case
    if (_allFilteredPurchaseReturns.isEmpty) {
      setState(() {
        _filteredPurchaseReturns = [];
      });
      return;
    }

    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;

    // Ensure startIndex is not greater than the list length
    if (startIndex >= _allFilteredPurchaseReturns.length) {
      // Reset to page 1 if current page is out of bounds
      setState(() {
        currentPage = 1;
      });
      _paginateFilteredPurchaseReturns(); // Recursive call with corrected page
      return;
    }

    setState(() {
      _filteredPurchaseReturns = _allFilteredPurchaseReturns.sublist(
        startIndex,
        endIndex > _allFilteredPurchaseReturns.length
            ? _allFilteredPurchaseReturns.length
            : endIndex,
      );
    });

    print(
      'Paginated to ${_filteredPurchaseReturns.length} items for display (page $currentPage)',
    );
  }

  // Handle page changes
  Future<void> _changePage(int newPage) async {
    setState(() {
      currentPage = newPage;
    });

    // Use client-side pagination
    _paginateFilteredPurchaseReturns();
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  Future<void> _deletePurchaseReturn(int purchaseReturnId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase Return'),
        content: const Text(
          'Are you sure you want to delete this purchase return? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PurchaseReturnService.deletePurchaseReturn(purchaseReturnId);

        // Remove the item from local lists in real-time
        setState(() {
          _purchaseReturns.removeWhere(
            (item) => item.purchaseReturnId == purchaseReturnId,
          );
        });

        // Re-apply filters to update the displayed list
        _applyFiltersClientSide();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase return deleted successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete purchase return: $e')),
          );
        }
      }
    }
  }

  // View purchase return details
  Future<void> _viewPurchaseReturnDetails(int purchaseReturnId) async {
    // Show dialog immediately with loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _LoadingPurchaseReturnDialog();
      },
    );

    try {
      final purchaseReturn = await PurchaseReturnService.getPurchaseReturnById(
        purchaseReturnId,
      );

      // Close loading dialog and show details dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showPurchaseReturnDetailsDialog(purchaseReturn);
      }
    } catch (e) {
      // Close loading dialog and show error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load purchase return details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edit purchase return
  Future<void> _editPurchaseReturn(int purchaseReturnId) async {
    // Show dialog immediately with loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _LoadingPurchaseReturnDialog();
      },
    );

    try {
      final purchaseReturn = await PurchaseReturnService.getPurchaseReturnById(
        purchaseReturnId,
      );

      // Close loading dialog and show edit dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showEditPurchaseReturnDialog(purchaseReturn);
      }
    } catch (e) {
      // Close loading dialog and show error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load purchase return for editing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getTotalReturnedAmount() {
    return _purchaseReturns.fold(
      0.0,
      (sum, item) => sum + (double.tryParse(item.returnAmount) ?? 0.0),
    );
  }

  double _getTotalPaidAmount() {
    // Since the API doesn't provide paid amounts, we'll assume all amounts are paid for now
    // In a real implementation, you might need to calculate this differently
    return _getTotalReturnedAmount();
  }

  double _getTotalDueAmount() {
    // Since the API doesn't provide due amounts, we'll return 0 for now
    return 0.0;
  }

  bool _canGoToNextPage() {
    final totalPages = _getTotalPages();
    return currentPage < totalPages;
  }

  int _getTotalPages() {
    if (_allFilteredPurchaseReturns.isEmpty) return 1;
    return (_allFilteredPurchaseReturns.length / itemsPerPage).ceil();
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Return'),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF0D1845).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_return,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purchase Return Management',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Track and manage all purchase return transactions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
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
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Add Return',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D1845),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Summary Cards - More compact
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Total Returns',
                        '${_purchaseReturns.length}',
                        Icons.assignment_return,
                        const Color(0xFF2196F3),
                      ),
                      _buildSummaryCard(
                        'Total Amount',
                        'Rs. ${_getTotalReturnedAmount().toStringAsFixed(2)}',
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
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
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
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedStatus,
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
                            child: Text(
                              'Total Returned Amount',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Status', style: _headerStyle()),
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
                          : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading purchase returns',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadPurchaseReturns,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _filteredPurchaseReturns.isEmpty
                          ? const Center(
                              child: Text(
                                'No purchase returns found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredPurchaseReturns.length,
                              itemBuilder: (context, index) {
                                final purchaseReturn =
                                    _filteredPurchaseReturns[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[100]!,
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
                                                ).withValues(alpha: 0.1),
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
                                                purchaseReturn.vendor.fullName,
                                                style: _cellStyle(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: InkWell(
                                          onTap: () {
                                            // TODO: Navigate to original purchase
                                          },
                                          child: Text(
                                            purchaseReturn.returnInvNo,
                                            style: _cellStyle().copyWith(
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatDate(
                                            purchaseReturn.returnDate,
                                          ),
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Rs. ${double.tryParse(purchaseReturn.returnAmount)?.toStringAsFixed(2) ?? '0.00'}',
                                          style: _cellStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor('Completed')
                                                .withValues(
                                                  alpha: 0.1,
                                                ), // Default to Completed since API doesn't provide status
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Completed', // Default status since API doesn't provide status
                                            style: TextStyle(
                                              color: _getStatusColor(
                                                'Completed',
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
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
                                            // View button
                                            IconButton(
                                              icon: Icon(
                                                Icons.visibility,
                                                color: Color(0xFF17A2B8),
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _viewPurchaseReturnDetails(
                                                    purchaseReturn
                                                        .purchaseReturnId,
                                                  ),
                                              tooltip: 'View Details',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            // Edit button
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Color(0xFF28A745),
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _editPurchaseReturn(
                                                    purchaseReturn
                                                        .purchaseReturnId,
                                                  ),
                                              tooltip: 'Edit Purchase Return',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            // Delete button
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Color(0xFFDC3545),
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _deletePurchaseReturn(
                                                    purchaseReturn
                                                        .purchaseReturnId,
                                                  ),
                                              tooltip: 'Delete Purchase Return',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
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

                    // Pagination - Always show like purchase listing page
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
                              'Page $currentPage of ${_getTotalPages()} (${_allFilteredPurchaseReturns.length} total)',
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

  // Helper method to show purchase return details dialog
  void _showPurchaseReturnDetailsDialog(PurchaseReturn purchaseReturn) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _PurchaseReturnDetailsDialog(purchaseReturn: purchaseReturn);
      },
    );
  }

  // Helper method to show edit purchase return dialog
  void _showEditPurchaseReturnDialog(PurchaseReturn purchaseReturn) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _EditPurchaseReturnDialog(
          purchaseReturn: purchaseReturn,
          onUpdate: _updatePurchaseReturnInList,
        );
      },
    );
  }

  // Method to update purchase return in local list after edit
  void _updatePurchaseReturnInList(PurchaseReturn updatedPurchaseReturn) {
    setState(() {
      final index = _purchaseReturns.indexWhere(
        (item) =>
            item.purchaseReturnId == updatedPurchaseReturn.purchaseReturnId,
      );
      if (index != -1) {
        _purchaseReturns[index] = updatedPurchaseReturn;
      }
    });

    // Re-apply filters to update the displayed list
    _applyFiltersClientSide();
  }
}

// Loading dialog for purchase return operations
class _LoadingPurchaseReturnDialog extends StatelessWidget {
  const _LoadingPurchaseReturnDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Loading purchase return details...'),
        ],
      ),
    );
  }
}

// Purchase return details dialog
class _PurchaseReturnDetailsDialog extends StatelessWidget {
  final PurchaseReturn purchaseReturn;

  const _PurchaseReturnDetailsDialog({required this.purchaseReturn});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Purchase Return Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              'Return ID',
              purchaseReturn.purchaseReturnId.toString(),
            ),
            _buildDetailRow('Vendor', purchaseReturn.vendor.fullName),
            _buildDetailRow('Return Date', purchaseReturn.returnDate),
            _buildDetailRow('Return Invoice No', purchaseReturn.returnInvNo),
            _buildDetailRow(
              'Total Amount',
              '\$${double.tryParse(purchaseReturn.returnAmount)?.toStringAsFixed(2) ?? '0.00'}',
            ),
            _buildDetailRow(
              'Discount Percent',
              '${purchaseReturn.discountPercent}%',
            ),
            _buildDetailRow('Reason', purchaseReturn.reason),
            SizedBox(height: 16),
            Text(
              'Return Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...purchaseReturn.details.map((detail) => _buildItemRow(detail)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildItemRow(PurchaseReturnDetail detail) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product ID: ${detail.productId}'),
          Text('Quantity: ${detail.qty}'),
          Text(
            'Unit Price: \$${double.tryParse(detail.unitPrice)?.toStringAsFixed(2) ?? '0.00'}',
          ),
          Text('Discount %: ${detail.discPer}%'),
          Text(
            'Discount Amount: \$${double.tryParse(detail.discAmount)?.toStringAsFixed(2) ?? '0.00'}',
          ),
        ],
      ),
    );
  }
}

// Edit purchase return dialog
class _EditPurchaseReturnDialog extends StatefulWidget {
  final PurchaseReturn purchaseReturn;
  final Function(PurchaseReturn) onUpdate;

  const _EditPurchaseReturnDialog({
    required this.purchaseReturn,
    required this.onUpdate,
  });

  @override
  _EditPurchaseReturnDialogState createState() =>
      _EditPurchaseReturnDialogState();
}

class _EditPurchaseReturnDialogState extends State<_EditPurchaseReturnDialog> {
  late TextEditingController _returnDateController;
  late TextEditingController _returnInvNoController;
  late TextEditingController _reasonController;
  late TextEditingController _totalAmountController;
  late TextEditingController _discountPercentController;
  String? _selectedPaymentStatus;
  int? _selectedPurchaseId;
  int? _selectedVendorId;
  List<Map<String, dynamic>> _details = [];

  @override
  void initState() {
    super.initState();
    _returnDateController = TextEditingController(
      text: widget.purchaseReturn.returnDate,
    );
    _returnInvNoController = TextEditingController(
      text: widget.purchaseReturn.returnInvNo,
    );
    _reasonController = TextEditingController(
      text: widget.purchaseReturn.reason,
    );
    _totalAmountController = TextEditingController(
      text: widget.purchaseReturn.returnAmount,
    );
    _discountPercentController = TextEditingController(
      text: widget.purchaseReturn.discountPercent,
    );

    // Initialize details from the purchase return
    _details = widget.purchaseReturn.details
        .map(
          (detail) => {
            'product_id': int.tryParse(detail.productId) ?? 0,
            'qty': int.tryParse(detail.qty) ?? 0,
            'unit_price': double.tryParse(detail.unitPrice) ?? 0.0,
            'discPer': double.tryParse(detail.discPer) ?? 0.0,
            'discAmount': double.tryParse(detail.discAmount) ?? 0.0,
          },
        )
        .toList();

    // Set default payment status (API doesn't provide this, so we'll use a default)
    _selectedPaymentStatus = 'unpaid';

    // Set purchase_id and vendor_id from the purchase return data
    _selectedPurchaseId = widget.purchaseReturn.purchase != null
        ? widget.purchaseReturn.purchase['id']
        : null;
    _selectedVendorId = widget.purchaseReturn.vendor.id;
  }

  @override
  void dispose() {
    _returnDateController.dispose();
    _returnInvNoController.dispose();
    _reasonController.dispose();
    _totalAmountController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    child: Text(
                      'Edit Purchase Return',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                            controller: _returnDateController,
                            decoration: InputDecoration(
                              labelText: 'Return Date',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _returnInvNoController,
                            decoration: InputDecoration(
                              labelText: 'Return Invoice No',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
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
                            controller: _totalAmountController,
                            decoration: InputDecoration(
                              labelText: 'Total Amount',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountPercentController,
                            decoration: InputDecoration(
                              labelText: 'Discount Percent',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedPaymentStatus,
                      decoration: InputDecoration(
                        labelText: 'Payment Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['paid', 'unpaid', 'partial']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedPaymentStatus = value),
                    ),

                    const SizedBox(height: 24),

                    // Return Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Return Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1845),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addDetailItem,
                          icon: Icon(Icons.add, size: 16),
                          label: Text('Add Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0D1845),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ..._details.asMap().entries.map((entry) {
                      final index = entry.key;
                      final detail = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: detail['product_id']
                                        .toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Product ID',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => detail['product_id'] =
                                        int.tryParse(value) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: detail['qty'].toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Quantity',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => detail['qty'] =
                                        int.tryParse(value) ?? 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: detail['unit_price']
                                        .toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Unit Price',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => detail['unit_price'] =
                                        double.tryParse(value) ?? 0.0,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: detail['discPer'].toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Discount %',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => detail['discPer'] =
                                        double.tryParse(value) ?? 0.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: detail['discAmount']
                                        .toString(),
                                    decoration: InputDecoration(
                                      labelText: 'Discount Amount',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => detail['discAmount'] =
                                        double.tryParse(value) ?? 0.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removeDetailItem(index),
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Remove Item',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0D1845),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Purchase Return'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDetailItem() {
    setState(() {
      _details.add({
        'product_id': 0,
        'qty': 0,
        'unit_price': 0.0,
        'discPer': 0.0,
        'discAmount': 0.0,
      });
    });
  }

  void _removeDetailItem(int index) {
    setState(() {
      _details.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    try {
      final updateData = {
        'return_date': _returnDateController.text,
        'purchase_id': _selectedPurchaseId,
        'return_inv_no': _returnInvNoController.text,
        'vendor_id': _selectedVendorId,
        'reason': _reasonController.text,
        'total_amount': double.tryParse(_totalAmountController.text) ?? 0.0,
        'payment_status': _selectedPaymentStatus,
        'details': _details,
      };

      final updatedPurchaseReturn =
          await PurchaseReturnService.updatePurchaseReturn(
            widget.purchaseReturn.purchaseReturnId,
            updateData,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase return updated successfully')),
        );
        // Update the local list in real-time
        widget.onUpdate(updatedPurchaseReturn);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update purchase return: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

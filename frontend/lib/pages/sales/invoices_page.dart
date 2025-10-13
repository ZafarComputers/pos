import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sales_service.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  // API data
  List<Invoice> _filteredInvoices = [];
  List<Invoice> _allFilteredInvoices =
      []; // Store all filtered invoices for local pagination
  List<Invoice> _allInvoicesCache =
      []; // Cache for all invoices to avoid refetching
  bool _isLoading = true;
  String? _errorMessage;
  int currentPage = 1;
  final int itemsPerPage = 10;

  // Filter states
  String _selectedTimeFilter = 'All'; // Day, Month, Year, All

  @override
  void initState() {
    super.initState();
    _fetchAllInvoicesOnInit();
  }

  // Fetch all invoices once when page loads
  Future<void> _fetchAllInvoicesOnInit() async {
    try {
      print('🚀 Initial load: Fetching all invoices');
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }

      final response = await SalesService.getInvoices();
      _allInvoicesCache = response.data;
      print('💾 Cached ${_allInvoicesCache.length} total invoices');

      // Apply initial filters (which will be no filters, showing all invoices)
      _applyFiltersClientSide();
    } catch (e) {
      print('❌ Critical error in _fetchAllInvoicesOnInit: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load invoices. Please refresh the page.';
          _isLoading = false;
        });
      }
    }
  }

  // Pure client-side filtering method
  void _applyFiltersClientSide() {
    try {
      print('🎯 Client-side filtering - time filter: "$_selectedTimeFilter"');

      // Apply filters to cached invoices (no API calls)
      _filterCachedInvoices();

      print('📦 _allInvoicesCache.length: ${_allInvoicesCache.length}');
      print('🎯 _allFilteredInvoices.length: ${_allFilteredInvoices.length}');
      print('👀 _filteredInvoices.length: ${_filteredInvoices.length}');
    } catch (e) {
      print('❌ Error in _applyFiltersClientSide: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Search error: Please try a different search term';
          _isLoading = false;
        });
      }
    }
  }

  // Filter cached invoices without any API calls
  void _filterCachedInvoices() {
    try {
      // Apply filters to cached invoices
      _allFilteredInvoices = _allInvoicesCache.where((invoice) {
        try {
          // Date filtering based on time filter
          bool dateMatch = true;
          final now = DateTime.now();
          final invoiceDate = DateTime.parse(invoice.invDate);

          if (_selectedTimeFilter == 'Day') {
            dateMatch =
                invoiceDate.year == now.year &&
                invoiceDate.month == now.month &&
                invoiceDate.day == now.day;
          } else if (_selectedTimeFilter == 'Month') {
            dateMatch =
                invoiceDate.year == now.year && invoiceDate.month == now.month;
          } else if (_selectedTimeFilter == 'Year') {
            dateMatch = invoiceDate.year == now.year;
          }

          return dateMatch;
        } catch (e) {
          print('❌ Error filtering invoice ${invoice.invId}: $e');
          return false; // Skip problematic invoices
        }
      }).toList();

      print(
        '🔍 After filtering: ${_allFilteredInvoices.length} invoices match criteria',
      );

      // Apply local pagination to filtered results
      _paginateFilteredInvoices();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Critical error in _filterCachedInvoices: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Search failed. Please try again with a simpler search term.';
          _isLoading = false;
          // Fallback: show empty results instead of crashing
          _filteredInvoices = [];
          _allFilteredInvoices = [];
        });
      }
    }
  }

  // Apply local pagination to filtered invoices
  void _paginateFilteredInvoices() {
    try {
      // Handle empty results case
      if (_allFilteredInvoices.isEmpty) {
        if (mounted) {
          setState(() {
            _filteredInvoices = [];
          });
        }
        return;
      }

      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;

      // Ensure startIndex is not greater than the list length
      if (startIndex >= _allFilteredInvoices.length) {
        // Reset to page 1 if current page is out of bounds
        if (mounted) {
          setState(() {
            currentPage = 1;
          });
        }
        _paginateFilteredInvoices(); // Recursive call with corrected page
        return;
      }

      if (mounted) {
        setState(() {
          _filteredInvoices = _allFilteredInvoices.sublist(
            startIndex,
            endIndex > _allFilteredInvoices.length
                ? _allFilteredInvoices.length
                : endIndex,
          );
        });
      }

      print(
        'Paginated to ${_filteredInvoices.length} items for display (page $currentPage)',
      );
    } catch (e) {
      print('❌ Error in _paginateFilteredInvoices: $e');
      if (mounted) {
        setState(() {
          _filteredInvoices = [];
          currentPage = 1;
        });
      }
    }
  }

  // Handle page changes
  Future<void> _changePage(int newPage) async {
    if (mounted) {
      setState(() {
        currentPage = newPage;
      });
    }

    // Use client-side pagination when we have cached invoices
    if (_allInvoicesCache.isNotEmpty) {
      _paginateFilteredInvoices();
    }
  }

  bool _canGoToNextPage() {
    final totalPages = _getTotalPages();
    return currentPage < totalPages;
  }

  int _getTotalPages() {
    if (_allFilteredInvoices.isEmpty) return 1;
    return (_allFilteredInvoices.length / itemsPerPage).ceil();
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

  void _viewInvoiceDetails(Invoice invoice) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading invoice details...'),
            ],
          ),
        );
      },
    );

    try {
      final invoiceDetail = await SalesService.getInvoiceById(invoice.invId);

      // Close loading dialog and show details dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showInvoiceDetailsDialog(invoiceDetail);
      }
    } catch (e) {
      // Close loading dialog and show error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load invoice details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editInvoice(Invoice invoice) async {
    // Navigate to POS page with invoice data for editing
    Navigator.pushNamed(context, '/pos', arguments: invoice);
  }

  void _deleteInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
          'Are you sure you want to delete this invoice? This action cannot be undone.',
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
        await SalesService.deleteInvoice(invoice.invId);

        // Remove the invoice from local lists in real-time
        if (mounted) {
          setState(() {
            _allInvoicesCache.removeWhere(
              (item) => item.invId == invoice.invId,
            );
          });
        }

        // Re-apply filters to update the displayed list
        _applyFiltersClientSide();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete invoice: $e')),
          );
        }
      }
    }
  }

  // Helper method to show invoice details dialog
  void _showInvoiceDetailsDialog(InvoiceDetailResponse invoiceDetail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                    ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invoice Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'INV-${invoiceDetail.invId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
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
                        // Customer Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D1845),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Color(0xFF0D1845),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    invoiceDetail.customerName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Normal Customer',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF0D1845),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    (() {
                                      try {
                                        return DateFormat('dd MMM yyyy').format(
                                          DateTime.parse(invoiceDetail.invDate),
                                        );
                                      } catch (e) {
                                        print(
                                          '❌ Error parsing invoice date: $e',
                                        );
                                        return 'Invalid Date';
                                      }
                                    })(),
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

                        const SizedBox(height: 20),

                        // Invoice Items
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Invoice Items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D1845),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...invoiceDetail.details.map((detail) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Product ID: ${detail.productId}',
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
                                            'Qty: ${detail.quantity}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rs. ${detail.price}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rs. ${detail.subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF0D1845),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Amount Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${double.tryParse(invoiceDetail.invAmount)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Paid Amount:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${double.tryParse(invoiceDetail.paidAmount)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Due Amount:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          (double.tryParse(
                                                        invoiceDetail.invAmount,
                                                      ) ??
                                                      0) -
                                                  (double.tryParse(
                                                        invoiceDetail
                                                            .paidAmount,
                                                      ) ??
                                                      0) >
                                              0
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${((double.tryParse(invoiceDetail.invAmount) ?? 0) - (double.tryParse(invoiceDetail.paidAmount) ?? 0)).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          (double.tryParse(
                                                        invoiceDetail.invAmount,
                                                      ) ??
                                                      0) -
                                                  (double.tryParse(
                                                        invoiceDetail
                                                            .paidAmount,
                                                      ) ??
                                                      0) >
                                              0
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
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

  Color _getPaymentModeColor(String paymentMode) {
    switch (paymentMode.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'bank':
        return Colors.blue;
      case 'credit':
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
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
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 16),
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
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Color(0xFFDEE2E6),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Color(0xFFDEE2E6),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                                          ? Icons
                                                                .calendar_view_month
                                                          : filter == 'Day'
                                                          ? Icons.today
                                                          : filter == 'Month'
                                                          ? Icons
                                                                .calendar_view_month
                                                          : Icons
                                                                .calendar_today,
                                                      color: filter == 'All'
                                                          ? Color(0xFF6C757D)
                                                          : Color(0xFF0D1845),
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      filter,
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
                                          if (value != null && mounted) {
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
                            child: Text(
                              'Invoice Number',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Customer Name', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Customer Type', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text('Date', style: _headerStyle()),
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
                              'Mode of Payment',
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
                                  Icon(
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
                                    onPressed: _fetchAllInvoicesOnInit,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: _filteredInvoices.map((
                                        invoice,
                                      ) {
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
                                                child: Text(
                                                  'INV-${invoice.invId}',
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 2,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF0D1845,
                                                        ).withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.person,
                                                        color: Color(
                                                          0xFF0D1845,
                                                        ),
                                                        size: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        invoice.isCreditCustomer
                                                            ? invoice
                                                                  .customerName
                                                            : 'Walk-in Customer',
                                                        style: _cellStyle(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 2,
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
                                                  child: const Text(
                                                    'Normal',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  DateFormat(
                                                    'dd MMM yyyy',
                                                  ).format(
                                                    DateTime.parse(
                                                      invoice.invDate,
                                                    ),
                                                  ),
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'Rs. ${invoice.invAmount.toStringAsFixed(2)}',
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'Rs. ${invoice.paidAmount.toStringAsFixed(2)}',
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  'Rs. ${invoice.dueAmount.toStringAsFixed(2)}',
                                                  style: _cellStyle(),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getPaymentModeColor(
                                                      invoice.paymentMode,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    invoice.paymentMode,
                                                    style: TextStyle(
                                                      color:
                                                          _getPaymentModeColor(
                                                            invoice.paymentMode,
                                                          ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                        color: const Color(
                                                          0xFF0D1845,
                                                        ),
                                                        size: 18,
                                                      ),
                                                      onPressed: () =>
                                                          _viewInvoiceDetails(
                                                            invoice,
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
                                                          _editInvoice(invoice),
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
                                                          _deleteInvoice(
                                                            invoice,
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
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                // Pagination Controls
                                if (_allFilteredInvoices.isNotEmpty)
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Previous button
                                        ElevatedButton.icon(
                                          onPressed: currentPage > 1
                                              ? () =>
                                                    _changePage(currentPage - 1)
                                              : null,
                                          icon: Icon(
                                            Icons.chevron_left,
                                            size: 14,
                                          ),
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
                                            side: BorderSide(
                                              color: Color(0xFFDEE2E6),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
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
                                              ? () =>
                                                    _changePage(currentPage + 1)
                                              : null,
                                          icon: Icon(
                                            Icons.chevron_right,
                                            size: 14,
                                          ),
                                          label: Text(
                                            'Next',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _canGoToNextPage()
                                                ? Color(0xFF17A2B8)
                                                : Colors.grey.shade300,
                                            foregroundColor: _canGoToNextPage()
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                            elevation: _canGoToNextPage()
                                                ? 2
                                                : 0,
                                            side: _canGoToNextPage()
                                                ? null
                                                : BorderSide(
                                                    color: Color(0xFFDEE2E6),
                                                  ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'Page $currentPage of ${_getTotalPages()} (${_allFilteredInvoices.length} total)',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

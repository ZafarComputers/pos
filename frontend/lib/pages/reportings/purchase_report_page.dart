import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/purchase_reporting_service.dart';

class PurchaseReportPage extends StatefulWidget {
  const PurchaseReportPage({super.key});

  @override
  State<PurchaseReportPage> createState() => _PurchaseReportPageState();
}

class _PurchaseReportPageState extends State<PurchaseReportPage> {
  // API data
  List<PurchaseReport> _purchaseReports = [];
  List<PurchaseReport> _selectedReports = [];
  bool _selectAll = false;

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  int get _totalPages => (_getFilteredReports().length / _itemsPerPage).ceil();

  // Table scroll controller
  final ScrollController _tableScrollController = ScrollController();

  // Filter states
  String _selectedPeriod = 'Last 7 Days';
  String _selectedSupplier = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadPurchaseReports();
  }

  Future<void> _loadPurchaseReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await PurchaseReportingService.getPurchaseReports();
      _purchaseReports = response.data;

      // Calculate total pages
      _currentPage = 1;
      _selectedReports.clear();
      _selectAll = false;
    } catch (e) {
      _errorMessage = 'Failed to load purchase reports: $e';
      // Set empty data on error
      _purchaseReports = [];
      _currentPage = 1;
      _selectedReports.clear();
      _selectAll = false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  void _toggleReportSelection(PurchaseReport report) {
    setState(() {
      final reportId = report.purInvId;
      final existingIndex = _selectedReports.indexWhere(
        (r) => r.purInvId == reportId,
      );

      if (existingIndex >= 0) {
        _selectedReports.removeAt(existingIndex);
      } else {
        _selectedReports.add(report);
      }

      _updateSelectAllState();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedReports.clear();
      } else {
        _selectedReports = List.from(_getFilteredReports());
      }
      _selectAll = !_selectAll;
    });
  }

  void _updateSelectAllState() {
    final paginatedReports = _getPaginatedReports();
    _selectAll =
        paginatedReports.isNotEmpty &&
        _selectedReports.length == paginatedReports.length &&
        paginatedReports.every((report) => _selectedReports.contains(report));
  }

  List<PurchaseReport> _getFilteredReports() {
    return _purchaseReports.where((report) {
      final supplierMatch =
          _selectedSupplier == 'All' || report.vendorName == _selectedSupplier;
      final statusMatch =
          _selectedStatus == 'All' || report.paymentStatus == _selectedStatus;

      // Date filtering
      bool dateMatch = true;
      if (_selectedPeriod == 'Last 7 Days') {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        final reportDate = DateTime.tryParse(report.purDate) ?? DateTime.now();
        dateMatch = reportDate.isAfter(sevenDaysAgo);
      } else if (_selectedPeriod == 'Last 30 Days') {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final reportDate = DateTime.tryParse(report.purDate) ?? DateTime.now();
        dateMatch = reportDate.isAfter(thirtyDaysAgo);
      }

      return supplierMatch && statusMatch && dateMatch;
    }).toList();
  }

  List<PurchaseReport> _getPaginatedReports() {
    final filteredReports = _getFilteredReports();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return filteredReports.sublist(
      startIndex,
      endIndex > filteredReports.length ? filteredReports.length : endIndex,
    );
  }

  int _calculateTotalQuantity(PurchaseReport report) {
    return report.purDetails.fold(
      0,
      (sum, detail) => sum + (int.tryParse(detail.quantity) ?? 0),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _calculateTotal(String field) {
    return _getFilteredReports().fold(0.0, (sum, report) {
      switch (field) {
        case 'grandTotal':
          return sum + (double.tryParse(report.invAmount) ?? 0.0);
        case 'paidAmount':
          // For paid amount, we need to calculate from payment status
          return sum +
              (report.paymentStatus.toLowerCase() == 'paid'
                  ? (double.tryParse(report.invAmount) ?? 0.0)
                  : 0.0);
        default:
          return sum;
      }
    });
  }

  int _calculateTotalInt(String field) {
    return _getFilteredReports().fold(0, (sum, report) {
      switch (field) {
        case 'totalItems':
          return sum + report.purDetails.length;
        case 'totalQuantity':
          return sum +
              report.purDetails.fold(
                0,
                (qSum, detail) => qSum + (int.tryParse(detail.quantity) ?? 0),
              );
        default:
          return sum;
      }
    });
  }

  Widget _buildPaginationControls() {
    // Show pagination controls even with 1 page
    // if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                      _updateSelectAllState();
                    });
                    // Reset table scroll position
                    _tableScrollController.jumpTo(0.0);
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            color: _currentPage > 1 ? Color(0xFF0D1845) : Colors.grey,
            tooltip: 'Previous Page',
          ),

          // Page numbers
          ..._buildPageNumbers(),

          // Next button
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                      _updateSelectAllState();
                    });
                    // Reset table scroll position
                    _tableScrollController.jumpTo(0.0);
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            color: _currentPage < _totalPages ? Color(0xFF0D1845) : Colors.grey,
            tooltip: 'Next Page',
          ),

          // Page info
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF0D1845).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: TextStyle(
                color: Color(0xFF0D1845),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];
    int startPage = 1;
    int endPage = _totalPages;

    // Show max 10 page numbers at a time
    if (_totalPages > 10) {
      if (_currentPage <= 5) {
        endPage = 10;
      } else if (_currentPage >= _totalPages - 4) {
        startPage = _totalPages - 9;
      } else {
        startPage = _currentPage - 4;
        endPage = _currentPage + 5;
      }
    }

    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(
        InkWell(
          onTap: () {
            setState(() {
              _currentPage = i;
              _updateSelectAllState();
            });
            // Reset table scroll position
            _tableScrollController.jumpTo(0.0);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _currentPage == i ? Color(0xFF0D1845) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _currentPage == i
                    ? Color(0xFF0D1845)
                    : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Text(
              i.toString(),
              style: TextStyle(
                color: _currentPage == i ? Colors.white : Color(0xFF0D1845),
                fontWeight: _currentPage == i
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return pageNumbers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPurchaseReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredReports = _getFilteredReports();

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
            // Enhanced Header
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
                          'Purchase Report',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comprehensive purchase transactions and supplier analytics',
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
                      // TODO: Implement export functionality
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export Report'),
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

            // Summary Cards
            Row(
              children: [
                _buildSummaryCard(
                  'Total Purchases',
                  '${filteredReports.length}',
                  Icons.shopping_bag,
                  Colors.blue,
                ),
                _buildSummaryCard(
                  'Total Items',
                  '${_calculateTotalInt('totalItems')}',
                  Icons.inventory,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Total Amount',
                  'Rs. ${_calculateTotal('grandTotal').toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
                _buildSummaryCard(
                  'Total Paid',
                  'Rs. ${_calculateTotal('paidAmount').toStringAsFixed(2)}',
                  Icons.payments,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Enhanced Filters Section
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
                      // Period Filter
                      Expanded(
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
                                    Icons.date_range,
                                    size: 16,
                                    color: Color(0xFF0D1845),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Time Period',
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
                                value: _selectedPeriod,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
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
                                    ['Last 7 Days', 'Last 30 Days', 'All Time']
                                        .map(
                                          (period) => DropdownMenuItem(
                                            value: period,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.schedule,
                                                  color: Color(0xFF0D1845),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  period,
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
                                      _selectedPeriod = value;
                                      _currentPage = 1;
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
                      // Supplier Filter
                      Expanded(
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
                                    Icons.business,
                                    size: 16,
                                    color: Color(0xFF0D1845),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Supplier',
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
                                value: _selectedSupplier,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
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
                                          ..._purchaseReports
                                              .map(
                                                (report) => report.vendorName,
                                              )
                                              .toSet()
                                              .toList(),
                                        ]
                                        .map(
                                          (supplier) => DropdownMenuItem(
                                            value: supplier,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  supplier == 'All'
                                                      ? Icons.business_center
                                                      : Icons.business,
                                                  color: supplier == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : Color(0xFF0D1845),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  supplier,
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
                                      _selectedSupplier = value;
                                      _currentPage = 1;
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
                      // Status Filter
                      Expanded(
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
                                    'Status',
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
                                          ..._purchaseReports
                                              .map(
                                                (report) =>
                                                    report.paymentStatus,
                                              )
                                              .toSet()
                                              .toList(),
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
                                                      : status.toLowerCase() ==
                                                            'paid'
                                                      ? Icons
                                                            .check_circle_rounded
                                                      : status.toLowerCase() ==
                                                            'unpaid'
                                                      ? Icons.cancel_rounded
                                                      : Icons.pending,
                                                  color: status == 'All'
                                                      ? Color(0xFF6C757D)
                                                      : status.toLowerCase() ==
                                                            'paid'
                                                      ? Color(0xFF28A745)
                                                      : status.toLowerCase() ==
                                                            'unpaid'
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
                                      _selectedStatus = value;
                                      _currentPage = 1;
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

            // Enhanced Table Section
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
                          'Purchase Report Details',
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
                                Icons.receipt,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${filteredReports.length} Records',
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
                    controller: _tableScrollController,
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
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Reference')),
                        DataColumn(label: Text('Supplier')),
                        DataColumn(label: Text('Items')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Subtotal')),
                        DataColumn(label: Text('Tax')),
                        DataColumn(label: Text('Discount')),
                        DataColumn(label: Text('Shipping')),
                        DataColumn(label: Text('Grand Total')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Due')),
                        DataColumn(label: Text('Payment Method')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Received By')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _getPaginatedReports().map((report) {
                        final isSelected = _selectedReports.any(
                          (r) => r.purInvId == report.purInvId,
                        );
                        return DataRow(
                          selected: isSelected,
                          cells: [
                            DataCell(
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _toggleReportSelection(report),
                                activeColor: Color(0xFF0D1845),
                              ),
                            ),
                            DataCell(
                              Text(
                                DateFormat('dd MMM yyyy').format(
                                  DateTime.tryParse(report.purDate) ??
                                      DateTime.now(),
                                ),
                              ),
                            ),
                            DataCell(Text(report.venInvNo)),
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF0D1845).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.business,
                                      color: Color(0xFF0D1845),
                                      size: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(report.vendorName),
                                ],
                              ),
                            ),
                            DataCell(Text(report.purDetails.length.toString())),
                            DataCell(
                              Text(_calculateTotalQuantity(report).toString()),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${double.tryParse(report.invAmount)?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            ),
                            DataCell(Text('Rs. ${report.invDiscAmount}')),
                            DataCell(Text('Rs. ${report.invDiscAmount}')),
                            DataCell(
                              Text('Rs. 0.00'), // No shipping in API
                            ),
                            DataCell(
                              Text(
                                'Rs. ${double.tryParse(report.invAmount)?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report.paymentStatus.toLowerCase() == 'paid' ? (double.tryParse(report.invAmount)?.toStringAsFixed(2) ?? '0.00') : '0.00'}',
                              ),
                            ),
                            DataCell(
                              Text(
                                'Rs. ${report.paymentStatus.toLowerCase() == 'unpaid' ? (double.tryParse(report.invAmount)?.toStringAsFixed(2) ?? '0.00') : '0.00'}',
                              ),
                            ),
                            DataCell(Text(report.paymentStatus)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    report.paymentStatus,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  report.paymentStatus,
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      report.paymentStatus,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text('N/A')), // No received by in API
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
                                      // TODO: Implement view details
                                    },
                                    tooltip: 'View Details',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.print,
                                      color: Color(0xFF28A745),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement print
                                    },
                                    tooltip: 'Print',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  // Pagination Controls
                  _buildPaginationControls(),
                ],
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
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEE2E6), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF343A40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

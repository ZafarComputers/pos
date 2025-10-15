import 'package:flutter/material.dart';
import '../../services/vendor_reporting_service.dart';

enum VendorReportType { all, due }

class VendorReportPage extends StatefulWidget {
  const VendorReportPage({super.key});

  @override
  State<VendorReportPage> createState() => _VendorReportPageState();
}

class _VendorReportPageState extends State<VendorReportPage> {
  // Report type state
  VendorReportType _currentReportType = VendorReportType.all;

  // Data states
  List<VendorAllReport> _allReports = [];
  List<VendorDueReport> _dueReports = [];
  List<dynamic> _selectedReports = [];
  bool _selectAll = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;

  // Table scroll controller
  final ScrollController _tableScrollController = ScrollController();

  // Filter states
  String _sortBy = 'Vendor Name';

  @override
  void initState() {
    super.initState();
    _loadVendorReport();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (_currentReportType) {
        case VendorReportType.all:
          final response = await VendorReportingService.getAllReports();
          _allReports = response.data;
          break;
        case VendorReportType.due:
          final response = await VendorReportingService.getDueReports();
          _dueReports = response.data;
          break;
      }
      // Calculate total pages and reset pagination
      final totalItems = _getTotalItems();
      _totalPages = (totalItems / _itemsPerPage).ceil();
      _currentPage = 1;
      _selectedReports.clear();
      _selectAll = false;
    } catch (e) {
      // Only show error for All Report API failures, Due Report API failures are handled in service
      if (_currentReportType == VendorReportType.all) {
        _errorMessage = 'Failed to load vendor report: $e';
        // Set mock data for All Report when API fails
        _setMockData();
      }
      // For Due Report API failures, the service already returns mock data
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeReportType(VendorReportType reportType) {
    if (_currentReportType != reportType) {
      setState(() {
        _currentReportType = reportType;
        _selectedReports.clear();
        _selectAll = false;
        _sortBy = 'Vendor Name';
        _currentPage = 1; // Reset to first page when changing report type
      });
      // Reset table scroll position
      _tableScrollController.jumpTo(0.0);
      _loadVendorReport();
    }
  }

  void _toggleReportSelection(dynamic report) {
    setState(() {
      final reportId = _getReportId(report);
      final existingIndex = _selectedReports.indexWhere(
        (r) => _getReportId(r) == reportId,
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
    final filteredReports = _getFilteredReports();
    final paginatedReports = _getPaginatedReports(filteredReports);
    _selectAll =
        paginatedReports.isNotEmpty &&
        _selectedReports.length == paginatedReports.length;
  }

  int _getTotalItems() {
    switch (_currentReportType) {
      case VendorReportType.all:
        return _allReports.length;
      case VendorReportType.due:
        return _dueReports.length;
    }
  }

  void _setMockData() {
    // Generate mock data for All Report when API fails
    _allReports = List.generate(
      25,
      (index) => VendorAllReport(
        id: index + 1,
        vendorName: 'Vendor ${index + 1}',
        purchases: List.generate(
          3,
          (pIndex) => Purchase(
            id: pIndex + 1,
            barcode: 'BAR${(index + 1).toString().padLeft(6, '0')}$pIndex',
            invoiceNo: 'INV${(index + 1).toString().padLeft(3, '0')}$pIndex',
            invDate: '2025-01-${(index % 28 + 1).toString().padLeft(2, '0')}',
            total: '${(index + 1) * 1000 + pIndex * 500}.00',
            details: List.generate(
              2,
              (dIndex) => PurchaseDetail(
                productId: '${dIndex + 1}',
                productName: 'Product ${dIndex + 1}',
                quantity: '${(index + 1) * 2}',
                price: '${(index + 1) * 50}.00',
              ),
            ),
          ),
        ),
      ),
    );

    final totalItems = _getTotalItems();
    _totalPages = (totalItems / _itemsPerPage).ceil();
    _currentPage = 1;
    _selectedReports.clear();
    _selectAll = false;
  }

  dynamic _getReportId(dynamic report) {
    switch (_currentReportType) {
      case VendorReportType.all:
        return (report as VendorAllReport).id;
      case VendorReportType.due:
        return (report as VendorDueReport).vendorId;
    }
  }

  List<dynamic> _getFilteredReports() {
    List<dynamic> reports;
    switch (_currentReportType) {
      case VendorReportType.all:
        reports = _allReports;
        break;
      case VendorReportType.due:
        reports = _dueReports;
        break;
    }

    List<dynamic> filtered = reports.where((report) {
      // Add any filtering logic here if needed
      return true;
    }).toList();

    // Sort based on selected criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Vendor Name':
          return _getVendorName(a).compareTo(_getVendorName(b));
        default:
          return _getVendorName(a).compareTo(_getVendorName(b));
      }
    });

    return filtered;
  }

  List<dynamic> _getPaginatedReports(List<dynamic> reports) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return reports.sublist(
      startIndex,
      endIndex > reports.length ? reports.length : endIndex,
    );
  }

  String _getVendorName(dynamic report) {
    switch (_currentReportType) {
      case VendorReportType.all:
        return (report as VendorAllReport).vendorName;
      case VendorReportType.due:
        return (report as VendorDueReport).vendorName;
    }
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
                onPressed: _loadVendorReport,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredReports = _getFilteredReports();
    final paginatedReports = _getPaginatedReports(filteredReports);

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
            // Enhanced Header with Tab Buttons
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getReportIcon(),
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
                              _getReportTitle(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getReportDescription(),
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
                  const SizedBox(height: 20),
                  // Tab Buttons
                  Row(
                    children: [
                      _buildTabButton('All Report', VendorReportType.all),
                      const SizedBox(width: 12),
                      _buildTabButton('Due\'s Report', VendorReportType.due),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards
            _buildSummaryCards(filteredReports),
            const SizedBox(height: 24),

            // Filters Section
            _buildFiltersSection(),
            const SizedBox(height: 24),

            // Table Section
            _buildTableSection(paginatedReports),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, VendorReportType reportType) {
    final isSelected = _currentReportType == reportType;
    return ElevatedButton(
      onPressed: () => _changeReportType(reportType),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Colors.white
            : Colors.white.withOpacity(0.2),
        foregroundColor: isSelected ? const Color(0xFF0D1845) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: isSelected ? 4 : 0,
      ),
      child: Text(title),
    );
  }

  Widget _buildSummaryCards(List<dynamic> filteredReports) {
    switch (_currentReportType) {
      case VendorReportType.all:
        return Row(
          children: [
            _buildSummaryCard(
              'Total Vendors',
              '${filteredReports.length}',
              Icons.business,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Total Purchases',
              '${_calculateTotalPurchases(filteredReports)}',
              Icons.shopping_cart,
              Colors.green,
            ),
            _buildSummaryCard(
              'Total Amount',
              'Rs. ${_calculateTotalAmount(filteredReports)}',
              Icons.attach_money,
              Colors.purple,
            ),
            _buildSummaryCard(
              'Active Vendors',
              '${filteredReports.where((r) => (r as VendorAllReport).purchases.isNotEmpty).length}',
              Icons.check_circle,
              Colors.orange,
            ),
          ],
        );
      case VendorReportType.due:
        return Row(
          children: [
            _buildSummaryCard(
              'Total Vendors',
              '${filteredReports.length}',
              Icons.business,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Total Due Amount',
              'Rs. ${_calculateTotalDue(filteredReports)}',
              Icons.money_off,
              Colors.red,
            ),
            _buildSummaryCard(
              'Paid Amount',
              'Rs. ${_calculateTotalPaid(filteredReports)}',
              Icons.payment,
              Colors.green,
            ),
            _buildSummaryCard(
              'Vendors with Due',
              '${filteredReports.where((r) => (r as VendorDueReport).totalDue > 0).length}',
              Icons.warning,
              Colors.orange,
            ),
          ],
        );
    }
  }

  Widget _buildFiltersSection() {
    return Container(
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
              // Sort By Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 16, color: Color(0xFF0D1845)),
                          SizedBox(width: 6),
                          Text(
                            'Sort By',
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
                        value: _sortBy,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFFDEE2E6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFFDEE2E6)),
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
                        items: ['Vendor Name']
                            .map(
                              (sort) => DropdownMenuItem(
                                value: sort,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: Color(0xFF0D1845),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      sort,
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
                              _sortBy = value;
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
    );
  }

  Widget _buildTableSection(List<dynamic> paginatedReports) {
    return Container(
      height: 600, // Fixed height to prevent overflow
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
                Icon(_getReportIcon(), color: Color(0xFF0D1845), size: 18),
                SizedBox(width: 4),
                Text(
                  _getTableTitle(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF343A40),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Color(0xFF1976D2), size: 12),
                      SizedBox(width: 3),
                      Text(
                        '${paginatedReports.length} Vendors (Page $_currentPage of $_totalPages)',
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _tableScrollController,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Color(0xFFF8F9FA)),
                  dataRowColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Color(0xFF0D1845).withOpacity(0.1);
                    }
                    return Colors.white;
                  }),
                  columns: _getTableColumns(),
                  rows: paginatedReports
                      .map((report) => _buildTableRow(report))
                      .toList(),
                ),
              ),
            ),
          ),
          // Pagination Controls
          _buildPaginationControls(),
        ],
      ),
    );
  }

  String _getTableTitle() {
    switch (_currentReportType) {
      case VendorReportType.all:
        return 'All Vendor Reports Details';
      case VendorReportType.due:
        return 'Vendor Due Reports Details';
    }
  }

  List<DataColumn> _getTableColumns() {
    switch (_currentReportType) {
      case VendorReportType.all:
        return const [
          DataColumn(label: SizedBox(width: 70, child: Text('Select'))),
          DataColumn(label: SizedBox(width: 270, child: Text('Vendor Name'))),
          DataColumn(
            label: SizedBox(width: 145, child: Text('Total Purchases')),
          ),
          DataColumn(label: SizedBox(width: 200, child: Text('Total Amount'))),
          DataColumn(label: SizedBox(width: 135, child: Text('Status'))),
        ];
      case VendorReportType.due:
        return const [
          DataColumn(label: SizedBox(width: 50, child: Text('Select'))),
          DataColumn(label: SizedBox(width: 180, child: Text('Vendor Name'))),
          DataColumn(label: SizedBox(width: 180, child: Text('Email'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Phone'))),
          DataColumn(
            label: SizedBox(width: 120, child: Text('Total Purchases')),
          ),
          DataColumn(label: SizedBox(width: 120, child: Text('Total Paid'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Total Due'))),
        ];
    }
  }

  DataRow _buildTableRow(dynamic report) {
    final isSelected = _selectedReports.any(
      (r) => _getReportId(r) == _getReportId(report),
    );

    switch (_currentReportType) {
      case VendorReportType.all:
        final vendor = report as VendorAllReport;
        final totalPurchases = vendor.purchases.length;
        final totalAmount = vendor.purchases.fold<double>(
          0.0,
          (sum, purchase) => sum + (double.tryParse(purchase.total) ?? 0.0),
        );
        return DataRow(
          selected: isSelected,
          cells: [
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 70,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleReportSelection(report),
                    activeColor: Color(0xFF0D1845),
                  ),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 13),
                child: SizedBox(
                  width: 300,
                  child: _buildVendorCell(vendor.vendorName),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 145,
                  child: Text(totalPurchases.toString()),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 200,
                  child: Text('Rs. ${totalAmount.toStringAsFixed(2)}'),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 135,
                  child: _buildStatusCell(
                    totalPurchases > 0 ? 'Active' : 'Inactive',
                  ),
                ),
              ),
            ),
          ],
        );
      case VendorReportType.due:
        final vendor = report as VendorDueReport;
        return DataRow(
          selected: isSelected,
          cells: [
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 50,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleReportSelection(report),
                    activeColor: Color(0xFF0D1845),
                  ),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 180,
                  child: _buildVendorCell(vendor.vendorName),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 180,
                  child: Text(
                    vendor.email,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 120,
                  child: Text(
                    vendor.phone,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 120,
                  child: Text(
                    'Rs. ${vendor.totalPurchases.toStringAsFixed(2)}',
                  ),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 120,
                  child: Text('Rs. ${vendor.totalPaid.toStringAsFixed(2)}'),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 120,
                  child: _buildDueAmountCell(vendor.totalDue),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildVendorCell(String vendorName) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFF0D1845).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.business, color: Color(0xFF0D1845), size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            vendorName,
            style: TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDueAmountCell(double amount) {
    final color = amount > 0 ? Colors.red : Colors.green;
    return Text(
      'Rs. ${amount.toStringAsFixed(2)}',
      style: TextStyle(fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildStatusCell(String status) {
    final color = status == 'Active' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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

  // Calculation methods
  int _calculateTotalPurchases(List<dynamic> reports) {
    if (_currentReportType != VendorReportType.all) return 0;
    return reports.fold(
      0,
      (sum, report) => sum + (report as VendorAllReport).purchases.length,
    );
  }

  String _calculateTotalAmount(List<dynamic> reports) {
    if (_currentReportType != VendorReportType.all) return '0.00';
    final total = reports.fold<double>(0.0, (sum, report) {
      final vendor = report as VendorAllReport;
      return sum +
          vendor.purchases.fold<double>(
            0.0,
            (pSum, purchase) => pSum + (double.tryParse(purchase.total) ?? 0.0),
          );
    });
    return total.toStringAsFixed(2);
  }

  String _calculateTotalDue(List<dynamic> reports) {
    if (_currentReportType != VendorReportType.due) return '0.00';
    final total = reports.fold<double>(
      0.0,
      (sum, report) => sum + (report as VendorDueReport).totalDue,
    );
    return total.toStringAsFixed(2);
  }

  String _calculateTotalPaid(List<dynamic> reports) {
    if (_currentReportType != VendorReportType.due) return '0.00';
    final total = reports.fold<double>(
      0.0,
      (sum, report) => sum + (report as VendorDueReport).totalPaid,
    );
    return total.toStringAsFixed(2);
  }

  Widget _buildPaginationControls() {
    // Show pagination controls even with 1 page for testing
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

    // Show max 5 page numbers at a time
    if (_totalPages > 5) {
      if (_currentPage <= 3) {
        endPage = 5;
      } else if (_currentPage >= _totalPages - 2) {
        startPage = _totalPages - 4;
      } else {
        startPage = _currentPage - 2;
        endPage = _currentPage + 2;
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

  String _getReportTitle() {
    switch (_currentReportType) {
      case VendorReportType.all:
        return 'All Vendor Reports';
      case VendorReportType.due:
        return 'Vendor Due Reports';
    }
  }

  String _getReportDescription() {
    switch (_currentReportType) {
      case VendorReportType.all:
        return 'Complete vendor purchase history and details';
      case VendorReportType.due:
        return 'Vendor payment status and outstanding dues';
    }
  }

  IconData _getReportIcon() {
    switch (_currentReportType) {
      case VendorReportType.all:
        return Icons.business;
      case VendorReportType.due:
        return Icons.account_balance_wallet;
    }
  }
}

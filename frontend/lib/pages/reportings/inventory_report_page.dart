import 'package:flutter/material.dart';
import '../../services/inventory_reporting_service.dart';

enum InventoryReportType { inHand, history, sold }

class InventoryReportPage extends StatefulWidget {
  const InventoryReportPage({super.key});

  @override
  State<InventoryReportPage> createState() => _InventoryReportPageState();
}

class _InventoryReportPageState extends State<InventoryReportPage> {
  // Report type state
  InventoryReportType _currentReportType = InventoryReportType.inHand;

  // Data states
  List<InHandProduct> _inHandProducts = [];
  List<HistoryProduct> _historyProducts = [];
  List<SoldProduct> _soldProducts = [];
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
  String _selectedCategory = 'All';
  String _selectedStockStatus = 'All';
  String _sortBy = 'Product Name';

  @override
  void initState() {
    super.initState();
    _loadInventoryReport();
  }

  Future<void> _loadInventoryReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (_currentReportType) {
        case InventoryReportType.inHand:
          final response = await InventoryReportingService.getInHandProducts();
          _inHandProducts = response.data;
          break;
        case InventoryReportType.history:
          final response = await InventoryReportingService.getHistoryProducts();
          _historyProducts = response.data;
          break;
        case InventoryReportType.sold:
          final response = await InventoryReportingService.getSoldProducts();
          _soldProducts = response.data;
          break;
      }
      // Calculate total pages and reset pagination
      final totalItems = _getTotalItems();
      _totalPages = (totalItems / _itemsPerPage).ceil();
      _currentPage = 1;
      _selectedReports.clear();
      _selectAll = false;
      _updateSelectAllState(); // Recalculate based on current filters
    } catch (e) {
      _errorMessage = 'Failed to load inventory report: $e';
      // Set mock data for testing
      _setMockData();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeReportType(InventoryReportType reportType) {
    if (_currentReportType != reportType) {
      setState(() {
        _currentReportType = reportType;
        _isLoading = true; // Show loading while switching report types
        _selectedReports.clear();
        _selectAll = false;
        _selectedCategory = 'All';
        _selectedStockStatus = 'All';
        _sortBy = 'Product Name';
        _currentPage = 1; // Reset to first page when changing report type
      });
      // Reset table scroll position
      _tableScrollController.jumpTo(0.0);
      _loadInventoryReport();
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

    // Recalculate total pages based on filtered reports
    _totalPages = (filteredReports.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages && _totalPages > 0) {
      _currentPage = _totalPages;
    }
  }

  int _getTotalItems() {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return _inHandProducts.length;
      case InventoryReportType.history:
        return _historyProducts.length;
      case InventoryReportType.sold:
        return _soldProducts.length;
    }
  }

  void _setMockData() {
    // Generate mock data for testing pagination
    _inHandProducts = List.generate(
      25,
      (index) => InHandProduct(
        id: index + 1,
        productName: 'Product ${index + 1}',
        barcode: 'BAR${(index + 1).toString().padLeft(6, '0')}',
        designCode: 'DC${(index + 1).toString().padLeft(3, '0')}',
        imagePath: null,
        category: Category(
          id: (index % 3) + 1,
          categoryName: index % 3 == 0
              ? 'Bridal'
              : index % 3 == 1
              ? 'Fancy'
              : 'Traditional',
        ),
        subCategory: SubCategory(
          id: (index % 5) + 1,
          subCatName: 'Sub${(index % 5) + 1}',
        ),
        balanceStock: '${50 + index}',
        vendor: Vendor(
          id: (index % 4) + 1,
          vendorName: 'Vendor ${(index % 4) + 1}',
        ),
        productStatus: index % 4 == 0 ? 'Inactive' : 'Active',
      ),
    );

    _historyProducts = List.generate(
      25,
      (index) => HistoryProduct(
        id: index + 1,
        productName: 'Product ${index + 1}',
        barcode: 'BAR${(index + 1).toString().padLeft(6, '0')}',
        designCode: 'DC${(index + 1).toString().padLeft(3, '0')}',
        imagePath: null,
        category: Category(
          id: (index % 3) + 1,
          categoryName: index % 3 == 0
              ? 'Bridal'
              : index % 3 == 1
              ? 'Fancy'
              : 'Traditional',
        ),
        subCategory: SubCategory(
          id: (index % 5) + 1,
          subCatName: 'Sub${(index % 5) + 1}',
        ),
        salePrice: '${(index + 1) * 100}.00',
        openingStock: '${100 + index}',
        newStock: '${20 + index}',
        soldStock: '${15 + index}',
        balanceStock: '${105 + index}',
        vendor: Vendor(
          id: (index % 4) + 1,
          vendorName: 'Vendor ${(index % 4) + 1}',
        ),
        productStatus: index % 4 == 0 ? 'Inactive' : 'Active',
      ),
    );

    _soldProducts = List.generate(
      25,
      (index) => SoldProduct(
        id: index + 1,
        productName: 'Product ${index + 1}',
        barcode: 'BAR${(index + 1).toString().padLeft(6, '0')}',
        designCode: 'DC${(index + 1).toString().padLeft(3, '0')}',
        imagePath: null,
        category: Category(
          id: (index % 3) + 1,
          categoryName: index % 3 == 0
              ? 'Bridal'
              : index % 3 == 1
              ? 'Fancy'
              : 'Traditional',
        ),
        subCategory: SubCategory(
          id: (index % 5) + 1,
          subCatName: 'Sub${(index % 5) + 1}',
        ),
        soldStock: '${10 + index}',
        balanceStock: '${40 + index}',
        vendor: Vendor(
          id: (index % 4) + 1,
          vendorName: 'Vendor ${(index % 4) + 1}',
        ),
        productStatus: index % 4 == 0 ? 'Inactive' : 'Active',
      ),
    );

    final totalItems = _getTotalItems();
    _totalPages = (totalItems / _itemsPerPage).ceil();
    _currentPage = 1;
    _selectedReports.clear();
    _selectAll = false;
    _updateSelectAllState(); // Recalculate based on current filters
  }

  dynamic _getReportId(dynamic report) {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return (report as InHandProduct).id;
      case InventoryReportType.history:
        return (report as HistoryProduct).id;
      case InventoryReportType.sold:
        return (report as SoldProduct).id;
    }
  }

  List<dynamic> _getFilteredReports() {
    List<dynamic> reports;
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        reports = _inHandProducts;
        break;
      case InventoryReportType.history:
        reports = _historyProducts;
        break;
      case InventoryReportType.sold:
        reports = _soldProducts;
        break;
    }

    List<dynamic> filtered = reports.where((report) {
      final categoryMatch =
          _selectedCategory == 'All' ||
          _getCategoryName(report) == _selectedCategory;

      bool stockStatusMatch = true;
      if (_selectedStockStatus != 'All') {
        final balanceStock = _getBalanceStock(report);
        final stockStatus = _getStockStatus(balanceStock);
        stockStatusMatch = stockStatus == _selectedStockStatus;
      }

      return categoryMatch && stockStatusMatch;
    }).toList();

    // Sort based on selected criteria
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'Product Name':
          return _getProductName(a).compareTo(_getProductName(b));
        case 'Current Stock':
          return int.parse(
            _getBalanceStock(b),
          ).compareTo(int.parse(_getBalanceStock(a)));
        case 'Total Value':
          if (_currentReportType == InventoryReportType.history) {
            final aValue =
                double.parse((a as HistoryProduct).salePrice) *
                int.parse(a.balanceStock);
            final bValue =
                double.parse((b as HistoryProduct).salePrice) *
                int.parse(b.balanceStock);
            return bValue.compareTo(aValue);
          }
          return 0;
        default:
          return _getProductName(a).compareTo(_getProductName(b));
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

  String _getProductName(dynamic report) {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return (report as InHandProduct).productName;
      case InventoryReportType.history:
        return (report as HistoryProduct).productName;
      case InventoryReportType.sold:
        return (report as SoldProduct).productName;
    }
  }

  String _getCategoryName(dynamic report) {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return (report as InHandProduct).category.categoryName;
      case InventoryReportType.history:
        return (report as HistoryProduct).category.categoryName;
      case InventoryReportType.sold:
        return (report as SoldProduct).category.categoryName;
    }
  }

  String _getBalanceStock(dynamic report) {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return (report as InHandProduct).balanceStock;
      case InventoryReportType.history:
        return (report as HistoryProduct).balanceStock;
      case InventoryReportType.sold:
        return (report as SoldProduct).balanceStock;
    }
  }

  String _getStockStatus(String balanceStock) {
    final stock = int.tryParse(balanceStock) ?? 0;
    if (stock <= 0) return 'Out of Stock';
    if (stock <= 10) return 'Low Stock';
    return 'In Stock';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Bridal':
        return Icons.diamond;
      case 'Fancy':
        return Icons.star;
      default:
        return Icons.inventory;
    }
  }

  String _getReportTitle() {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return 'In Hand Inventory';
      case InventoryReportType.history:
        return 'Inventory History';
      case InventoryReportType.sold:
        return 'Sold Items';
    }
  }

  String _getReportDescription() {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return 'Current stock levels and inventory status';
      case InventoryReportType.history:
        return 'Stock movement history and transactions';
      case InventoryReportType.sold:
        return 'Items that have been sold';
    }
  }

  IconData _getReportIcon() {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return Icons.inventory_2;
      case InventoryReportType.history:
        return Icons.history;
      case InventoryReportType.sold:
        return Icons.shopping_cart;
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
                onPressed: _loadInventoryReport,
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
                      _buildTabButton('In Hand', InventoryReportType.inHand),
                      const SizedBox(width: 12),
                      _buildTabButton('History', InventoryReportType.history),
                      const SizedBox(width: 12),
                      _buildTabButton('Sold', InventoryReportType.sold),
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

  Widget _buildTabButton(String title, InventoryReportType reportType) {
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
      case InventoryReportType.inHand:
        return Row(
          children: [
            _buildSummaryCard(
              'Total Products',
              '${filteredReports.length}',
              Icons.inventory,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Total Stock',
              '${_calculateTotalStock(filteredReports)}',
              Icons.warehouse,
              Colors.green,
            ),
            _buildSummaryCard(
              'Low Stock Items',
              '${filteredReports.where((r) => _getStockStatus(_getBalanceStock(r)) == 'Low Stock').length}',
              Icons.warning,
              Colors.orange,
            ),
            _buildSummaryCard(
              'Out of Stock',
              '${filteredReports.where((r) => _getStockStatus(_getBalanceStock(r)) == 'Out of Stock').length}',
              Icons.cancel,
              Colors.red,
            ),
          ],
        );
      case InventoryReportType.history:
        return Row(
          children: [
            _buildSummaryCard(
              'Total Products',
              '${filteredReports.length}',
              Icons.inventory,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Total Opening Stock',
              '${_calculateTotalOpeningStock(filteredReports)}',
              Icons.input,
              Colors.green,
            ),
            _buildSummaryCard(
              'Total New Stock',
              '${_calculateTotalNewStock(filteredReports)}',
              Icons.add_circle,
              Colors.purple,
            ),
            _buildSummaryCard(
              'Total Sold',
              '${_calculateTotalSoldStock(filteredReports)}',
              Icons.remove_circle,
              Colors.orange,
            ),
          ],
        );
      case InventoryReportType.sold:
        return Row(
          children: [
            _buildSummaryCard(
              'Total Sold Items',
              '${filteredReports.length}',
              Icons.shopping_cart,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Total Sold Quantity',
              '${_calculateTotalSoldQuantity(filteredReports)}',
              Icons.numbers,
              Colors.green,
            ),
            _buildSummaryCard(
              'Active Items',
              '${filteredReports.where((r) => (r as SoldProduct).productStatus == 'Active').length}',
              Icons.check_circle,
              Colors.green,
            ),
            _buildSummaryCard(
              'Inactive Items',
              '${filteredReports.where((r) => (r as SoldProduct).productStatus == 'Inactive').length}',
              Icons.cancel,
              Colors.red,
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
              // Category Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Color(0xFF0D1845),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Category',
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
                        value: _selectedCategory,
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
                        items: ['All', 'Bridal', 'Fancy']
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    Icon(
                                      category == 'All'
                                          ? Icons.inventory_2
                                          : _getCategoryIcon(category),
                                      color: category == 'All'
                                          ? Color(0xFF6C757D)
                                          : Color(0xFF0D1845),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      category,
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
                              _selectedCategory = value;
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
              // Stock Status Filter (only for In Hand)
              if (_currentReportType == InventoryReportType.inHand)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              size: 16,
                              color: Color(0xFF0D1845),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Stock Status',
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
                          value: _selectedStockStatus,
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
                          items:
                              ['All', 'In Stock', 'Low Stock', 'Out of Stock']
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Row(
                                        children: [
                                          Icon(
                                            status == 'All'
                                                ? Icons.inventory_2_rounded
                                                : status == 'In Stock'
                                                ? Icons.check_circle
                                                : status == 'Low Stock'
                                                ? Icons.warning
                                                : Icons.cancel,
                                            color: status == 'All'
                                                ? Color(0xFF6C757D)
                                                : status == 'In Stock'
                                                ? Color(0xFF28A745)
                                                : status == 'Low Stock'
                                                ? Color(0xFFFFA726)
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
                                _selectedStockStatus = value;
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
                        items: _getSortOptions()
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

  List<String> _getSortOptions() {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return ['Product Name', 'Current Stock'];
      case InventoryReportType.history:
        return ['Product Name', 'Current Stock', 'Total Value'];
      case InventoryReportType.sold:
        return ['Product Name', 'Sold Quantity'];
    }
  }

  Widget _buildTableSection(List<dynamic> paginatedReports) {
    return Container(
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
                      Icon(Icons.inventory, color: Color(0xFF1976D2), size: 12),
                      SizedBox(width: 3),
                      Text(
                        '${paginatedReports.length} Products (Page $_currentPage of $_totalPages)',
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
          // Pagination Controls
          _buildPaginationControls(),
        ],
      ),
    );
  }

  String _getTableTitle() {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return 'In Hand Inventory Details';
      case InventoryReportType.history:
        return 'Inventory History Details';
      case InventoryReportType.sold:
        return 'Sold Items Details';
    }
  }

  List<DataColumn> _getTableColumns() {
    switch (_currentReportType) {
      case InventoryReportType.inHand:
        return const [
          DataColumn(label: SizedBox(width: 50, child: Text('Select'))),
          DataColumn(label: SizedBox(width: 200, child: Text('Product'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Code'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Category'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Balance Stock'))),
          DataColumn(label: SizedBox(width: 150, child: Text('Vendor'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Status'))),
        ];
      case InventoryReportType.history:
        return const [
          DataColumn(label: SizedBox(width: 50, child: Text('Select'))),
          DataColumn(label: SizedBox(width: 200, child: Text('Product'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Code'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Category'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Opening Stock'))),
          DataColumn(label: SizedBox(width: 120, child: Text('New Stock'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Sold Stock'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Balance Stock'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Sale Price'))),
          DataColumn(label: SizedBox(width: 150, child: Text('Vendor'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Status'))),
        ];
      case InventoryReportType.sold:
        return const [
          DataColumn(label: SizedBox(width: 50, child: Text('Select'))),
          DataColumn(label: SizedBox(width: 200, child: Text('Product'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Code'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Category'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Sold Stock'))),
          DataColumn(label: SizedBox(width: 120, child: Text('Balance Stock'))),
          DataColumn(label: SizedBox(width: 150, child: Text('Vendor'))),
          DataColumn(label: SizedBox(width: 100, child: Text('Status'))),
        ];
    }
  }

  DataRow _buildTableRow(dynamic report) {
    final isSelected = _selectedReports.any(
      (r) => _getReportId(r) == _getReportId(report),
    );

    switch (_currentReportType) {
      case InventoryReportType.inHand:
        final product = report as InHandProduct;
        return DataRow(
          selected: isSelected,
          cells: [
            DataCell(
              SizedBox(
                width: 50,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleReportSelection(report),
                  activeColor: Color(0xFF0D1845),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 200,
                child: _buildProductCell(
                  product.productName,
                  product.category.categoryName,
                ),
              ),
            ),
            DataCell(SizedBox(width: 100, child: Text(product.designCode))),
            DataCell(
              SizedBox(
                width: 120,
                child: _buildCategoryCell(product.category.categoryName),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: _buildStockCell(product.balanceStock),
              ),
            ),
            DataCell(
              SizedBox(width: 150, child: Text(product.vendor.vendorName)),
            ),
            DataCell(
              SizedBox(
                width: 100,
                child: _buildStatusCell(product.productStatus),
              ),
            ),
          ],
        );
      case InventoryReportType.history:
        final product = report as HistoryProduct;
        return DataRow(
          selected: isSelected,
          cells: [
            DataCell(
              SizedBox(
                width: 50,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleReportSelection(report),
                  activeColor: Color(0xFF0D1845),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 200,
                child: _buildProductCell(
                  product.productName,
                  product.category.categoryName,
                ),
              ),
            ),
            DataCell(SizedBox(width: 100, child: Text(product.designCode))),
            DataCell(
              SizedBox(
                width: 120,
                child: _buildCategoryCell(product.category.categoryName),
              ),
            ),
            DataCell(SizedBox(width: 120, child: Text(product.openingStock))),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(
                  product.newStock,
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(
                  product.soldStock,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: _buildStockCell(product.balanceStock),
              ),
            ),
            DataCell(
              SizedBox(width: 120, child: Text('Rs. ${product.salePrice}')),
            ),
            DataCell(
              SizedBox(width: 150, child: Text(product.vendor.vendorName)),
            ),
            DataCell(
              SizedBox(
                width: 100,
                child: _buildStatusCell(product.productStatus),
              ),
            ),
          ],
        );
      case InventoryReportType.sold:
        final product = report as SoldProduct;
        return DataRow(
          selected: isSelected,
          cells: [
            DataCell(
              SizedBox(
                width: 50,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleReportSelection(report),
                  activeColor: Color(0xFF0D1845),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 200,
                child: _buildProductCell(
                  product.productName,
                  product.category.categoryName,
                ),
              ),
            ),
            DataCell(SizedBox(width: 100, child: Text(product.designCode))),
            DataCell(
              SizedBox(
                width: 120,
                child: _buildCategoryCell(product.category.categoryName),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(
                  product.soldStock,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: _buildStockCell(product.balanceStock),
              ),
            ),
            DataCell(
              SizedBox(width: 150, child: Text(product.vendor.vendorName)),
            ),
            DataCell(
              SizedBox(
                width: 100,
                child: _buildStatusCell(product.productStatus),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildProductCell(String productName, String categoryName) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFF0D1845).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getCategoryIcon(categoryName),
            color: Color(0xFF0D1845),
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Text(productName, style: TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCategoryCell(String categoryName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        categoryName,
        style: TextStyle(
          color: Color(0xFF1976D2),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStockCell(String stock) {
    final stockInt = int.tryParse(stock) ?? 0;
    final color = stockInt <= 0
        ? Colors.red
        : stockInt <= 10
        ? Colors.orange
        : Colors.green;
    return Text(
      stock,
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
  int _calculateTotalStock(List<dynamic> reports) {
    return reports.fold(
      0,
      (sum, report) => sum + (int.tryParse(_getBalanceStock(report)) ?? 0),
    );
  }

  int _calculateTotalOpeningStock(List<dynamic> reports) {
    if (_currentReportType != InventoryReportType.history) return 0;
    return reports.fold(
      0,
      (sum, report) =>
          sum + (int.tryParse((report as HistoryProduct).openingStock) ?? 0),
    );
  }

  int _calculateTotalNewStock(List<dynamic> reports) {
    if (_currentReportType != InventoryReportType.history) return 0;
    return reports.fold(
      0,
      (sum, report) =>
          sum + (int.tryParse((report as HistoryProduct).newStock) ?? 0),
    );
  }

  int _calculateTotalSoldStock(List<dynamic> reports) {
    if (_currentReportType != InventoryReportType.history) return 0;
    return reports.fold(
      0,
      (sum, report) =>
          sum + (int.tryParse((report as HistoryProduct).soldStock) ?? 0),
    );
  }

  int _calculateTotalSoldQuantity(List<dynamic> reports) {
    if (_currentReportType != InventoryReportType.sold) return 0;
    return reports.fold(
      0,
      (sum, report) =>
          sum + (int.tryParse((report as SoldProduct).soldStock) ?? 0),
    );
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

  @override
  void dispose() {
    _tableScrollController.dispose();
    super.dispose();
  }
}

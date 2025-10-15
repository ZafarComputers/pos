import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/providers.dart';
import 'inventory/product_list_page.dart';
import 'inventory/add_product_page.dart';
import 'inventory/category_list_page.dart';
import 'inventory/sub_category_list_page.dart';
import 'inventory/color_list_page.dart';
import 'inventory/size_list_page.dart';
import 'inventory/season_list_page.dart';
import 'inventory/material_list_page.dart';
import 'inventory/low_stock_products_page.dart';
import 'inventory/vendors_page.dart';
import 'inventory/print_barcode_page.dart';
import 'profile/user_profile_page.dart';
import 'sales/sales_return_page.dart';
import 'sales/sales_page.dart';
import 'sales/invoices_page.dart';
import 'purchase/purchase_listing_page.dart';
import 'purchase/purchase_return_page.dart';
import '../services/services.dart';
import '../services/dashboard_service.dart';
import 'reportings/sales_report_page.dart';
import 'reportings/best_seller_report_page.dart';
import 'reportings/purchase_report_page.dart';
import 'reportings/inventory_report_page.dart';
import 'reportings/vendor_report_page.dart';
import 'reportings/invoice_report_page.dart';
import 'reportings/supplier_report_page.dart';
import 'reportings/product_report_page.dart';
import 'reportings/expense_report_page.dart';
import 'reportings/income_report_page.dart';
import 'reportings/tax_report_page.dart';
import 'reportings/profit_loss_report_page.dart';
import 'reportings/annual_report_page.dart';
import 'peoples/credit_customer_page.dart';
import 'users/users_page.dart';
import 'users/roles_permissions_page.dart';
import 'finance & accounts/expenses_page.dart';
import 'finance & accounts/expense_category_page.dart';
import 'finance & accounts/income_category_page.dart';
import 'finance & accounts/income_page.dart';
import 'finance & accounts/bank_account_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  String currentContent = 'Admin Dashboard';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSidebarOpen = true;
  Map<String, AnimationController> _animationControllers = {};
  String selectedTimeRange = '1M'; // Default time range
  String selectedTopSellingPeriod = 'Today'; // Default period for top selling

  // Dashboard data
  DashboardMetrics? _metrics;
  OverallInformation? _overallInfo;
  List<TopSellingProduct> _topSellingProducts = [];
  List<LowStockProduct> _lowStockProducts = [];
  List<RecentSale> _recentSales = [];
  SalesStatics? _salesStatics;
  List<RecentTransaction> _recentTransactions = [];
  List<TopCustomer> _topCustomers = [];
  List<TopCategory> _topCategories = [];
  OrderStatistics? _orderStatistics;

  bool _isLoading = true;

  Future<Uint8List?> _loadImageBytes(String path) async {
    try {
      return await File('${Directory.current.path}/$path').readAsBytes();
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Load user profile and dashboard data after ensuring auth is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for auth initialization to complete
      await authProvider.initAuth();

      if (authProvider.userProfile == null) {
        authProvider.getUserProfile();
      }
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Load all dashboard data in parallel
      final results = await Future.wait([
        DashboardService.getDashboardMetrics(),
        DashboardService.getOverallInformation(),
        DashboardService.getTopSellingProducts(),
        DashboardService.getLowStockProducts(),
        DashboardService.getRecentSales(),
        DashboardService.getSalesStatics(),
        DashboardService.getRecentTransactions(),
        DashboardService.getTopCustomers(),
        DashboardService.getTopCategories(),
        DashboardService.getOrderStatistics(),
      ]);

      setState(() {
        _metrics = results[0] as DashboardMetrics;
        _overallInfo = results[1] as OverallInformation;
        _topSellingProducts = results[2] as List<TopSellingProduct>;
        _lowStockProducts = results[3] as List<LowStockProduct>;
        _recentSales = results[4] as List<RecentSale>;
        _salesStatics = results[5] as SalesStatics;
        _recentTransactions = results[6] as List<RecentTransaction>;
        _topCustomers = results[7] as List<TopCustomer>;
        _topCategories = results[8] as List<TopCategory>;
        _orderStatistics = results[9] as OrderStatistics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void updateContent(String content) {
    setState(() {
      currentContent = content;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void updateTimeRange(String range) {
    setState(() {
      selectedTimeRange = range;
    });
    // Here you would typically fetch new data based on the selected time range
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Time range updated to $range'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void updateTopSellingPeriod(String period) {
    setState(() {
      selectedTopSellingPeriod = period;
    });
    // Here you would typically fetch new data for the selected period
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Top selling period updated to $period'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (currentContent) {
      case 'Products':
        return ProductListPage();
      case 'Create Product':
        return AddProductPage();
      case 'Low Stock Products':
        return LowStockProductsPage();
      case 'Category':
        return CategoryListPage();
      case 'Sub Category':
        return SubCategoryListPage();
      case 'Color':
        return ColorListPage();
      case 'Sizes':
        return SizeListPage();
      case 'Seasons':
        return SeasonListPage();
      case 'Material':
        return MaterialListPage();
      case 'Vendor':
        return VendorsPage();
      case 'Print Barcode':
        return PrintBarcodePage();
      case 'Sales Return':
        return const SalesReturnPage();
      case 'Sales':
        return const SalesPage();
      case 'Invoices':
        return const InvoicesPage();
      case 'Purchase Listing':
        return const PurchaseListingPage();
      case 'Purchase Return':
        return const PurchaseReturnPage();
      case 'Credit Customers':
        return const CreditCustomerPage();
      case 'Sales Report':
        return const SalesReportPage();
      case 'Best Seller':
        return const BestSellerReportPage();
      case 'Purchase Report':
        return const PurchaseReportPage();
      case 'Inventory Report':
        return const InventoryReportPage();
      case 'Vendor Report':
        return const VendorReportPage();
      case 'Invoice Report':
        return const InvoiceReportPage();
      case 'Supplier Report':
        return const SupplierReportPage();
      case 'Product Report':
        return const ProductReportPage();
      case 'Expense Report':
        return const ExpenseReportPage();
      case 'Income Report':
        return const IncomeReportPage();
      case 'Tax Report':
        return const TaxReportPage();
      case 'Profit & Loss':
        return const ProfitLossReportPage();
      case 'Annual Report':
        return const AnnualReportPage();
      case 'Expenses':
        return const ExpensesPage();
      case 'Expense Category':
        return const ExpenseCategoryPage();
      case 'Income Category':
        return const IncomeCategoryPage();
      case 'Income':
        return const IncomePage();
      case 'Bank Accounts':
        return const BankAccountPage();
      case 'Users':
        return const UsersPage();
      case 'Roles & Permissions':
        return const RolesPermissionsPage();
      case 'POS':
        // Navigate to POS page instead of showing content
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/pos');
        });
        return _buildDashboardContent(); // Show dashboard temporarily
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message with user name
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
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
                        'Welcome back, ${user?.fullName ?? 'User'}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${user?.roleId == '1' ? 'Admin' : 'User'} | Status: ${user?.status ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Metrics Cards
          Row(
            children: [
              _buildMetricCard(
                'Total Sales Return',
                'Rs ${_metrics?.totalSalesReturn.toStringAsFixed(0) ?? '0'}',
                Icons.undo,
                Colors.green,
                '+22%',
              ),
              _buildMetricCard(
                'Total Purchase',
                'Rs ${_metrics?.totalPurchase.toStringAsFixed(0) ?? '0'}',
                Icons.shopping_cart,
                Colors.blue,
                '-22%',
              ),
              _buildMetricCard(
                'Total Purchase Return',
                'Rs ${_metrics?.totalPurchaseReturn.toStringAsFixed(0) ?? '0'}',
                Icons.assignment_return,
                Colors.green,
                '+22%',
              ),
              _buildMetricCard(
                'Profit',
                'Rs ${_metrics?.profit.toStringAsFixed(0) ?? '0'}',
                Icons.trending_up,
                Colors.purple,
                '+35%',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMetricCard(
                'Invoice Due',
                'Rs ${_metrics?.invoiceDue.toStringAsFixed(0) ?? '0'}',
                Icons.receipt,
                Colors.orange,
                '+35%',
              ),
              _buildMetricCard(
                'Total Expenses',
                'Rs ${_metrics?.totalExpenses.toStringAsFixed(0) ?? '0'}',
                Icons.money_off,
                Colors.red,
                '+41%',
              ),
              _buildMetricCard(
                'Total Payment Returns',
                'Rs ${_metrics?.totalPaymentReturns.toStringAsFixed(0) ?? '0'}',
                Icons.refresh,
                Colors.red,
                '-20%',
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Overall Information
          Row(
            children: [
              _buildInfoCard(
                'Total Vendors',
                _overallInfo?.totalVendors.toString() ?? '0',
                Icons.business,
              ),
              _buildInfoCard(
                'Credit Customers',
                _overallInfo?.customers.toString() ?? '0',
                Icons.people,
              ),
              _buildInfoCard(
                'Orders',
                _overallInfo?.orders.toString() ?? '0',
                Icons.shopping_bag,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Top Selling Products and Low Stock Products in a row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Selling Products
              Expanded(
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF1F5F9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Top Selling Products',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            _buildDropdownButton('Today'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._topSellingProducts.map(
                          (product) => _buildProductItem(
                            product.name,
                            product.price,
                            product.sales,
                            product.change == '+25%'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Low Stock Products
              Expanded(
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF1F5F9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Low Stock Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._lowStockProducts.map(
                          (product) => _buildLowStockItem(
                            product.name,
                            product.id,
                            product.stock,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Sales and Sales Statics in a row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Sales
              Expanded(
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF1F5F9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Sales',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            _buildDropdownButton('Weekly'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._recentSales.map(
                          (sale) => _buildRecentSaleItem(
                            sale.productName,
                            sale.category,
                            sale.price,
                            sale.date,
                            sale.status,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Sales Statics
              Expanded(
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF1F5F9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sales Statics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            _buildDropdownButton('2025'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSalesStaticItem(
                                'Revenue',
                                'Rs ${_salesStatics?.revenue.toStringAsFixed(0) ?? '0'}',
                                '+25%',
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSalesStaticItem(
                                'Expense',
                                'Rs ${_salesStatics?.expense.toStringAsFixed(0) ?? '0'}',
                                '+25%',
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Transactions
          Card(
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF343A40),
                        ),
                      ),
                      Row(
                        children: [
                          _buildFilterChip('Sale'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Purchase'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Quotation'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Expenses'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Invoices'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Amount')),
                      ],
                      rows: _recentTransactions.map((transaction) {
                        return DataRow(
                          cells: [
                            DataCell(Text(transaction.date)),
                            DataCell(Text(transaction.customerName)),
                            DataCell(_buildStatusChip(transaction.status)),
                            DataCell(
                              Text(
                                'Rs ${transaction.amount.toStringAsFixed(0)}',
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
          ),
          const SizedBox(height: 32),

          // Top Customers and Top Categories in a row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Customers
              Expanded(
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF1F5F9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top Customers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._topCustomers.map(
                          (customer) => _buildTopCustomerItem(
                            customer.name,
                            customer.location,
                            customer.orders,
                            customer.amount,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Top Categories and Order Statistics
              Expanded(
                child: Column(
                  children: [
                    // Top Categories
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF1F5F9)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Top Categories',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                                _buildDropdownButton('Weekly'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._topCategories.map(
                              (category) => _buildTopCategoryItem(
                                category.name,
                                category.sales,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Order Statistics
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF1F5F9)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildOrderStatItem(
                                    'Total Number Of Categories',
                                    _orderStatistics?.totalCategories
                                            .toString() ??
                                        '0',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildOrderStatItem(
                                    'Total Number Of Products',
                                    _orderStatistics?.totalProducts
                                            .toString() ??
                                        '0',
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
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.dashboard, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'POS',
              style: TextStyle(
                color: Color(0xFF343A40),
                fontWeight: FontWeight.bold,
                fontFamily: 'Groote',
              ),
            ),
            const SizedBox(width: 20),
            Container(
              width: 350,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xFFDEE2E6), width: 1),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF6C757D),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6C757D),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(
                    left: 40,
                    right: 16,
                    top: 12,
                    bottom: 12,
                  ),
                ),
                style: const TextStyle(color: Color(0xFF343A40)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            tooltip: 'Exit Application',
            onPressed: () async {
              await windowManager.close();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFF6C757D)),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfilePage(),
                    ),
                  );
                  break;
                case 'logout':
                  // Call logout API and then logout locally
                  try {
                    await ApiService.logoutUser();
                    // Also clear provider state
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } catch (e) {
                    // Even if API fails, show error and redirect
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logout completed with warning: $e'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      // Still clear provider state and redirect
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                  break;
              }
            },
            offset: const Offset(20, 50),
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    String? imageUrl;
                    String initial = 'A'; // Default

                    if (authProvider.user != null) {
                      if (authProvider.user!.firstName.isNotEmpty) {
                        initial = authProvider.user!.firstName[0].toUpperCase();
                      }
                      // Check for profile picture in userProfile first, then user imgPath
                      imageUrl =
                          authProvider.userProfile?.profilePicture ??
                          authProvider.user!.imgPath;
                    }

                    return FutureBuilder<Uint8List?>(
                      future: imageUrl != null && !imageUrl.startsWith('http')
                          ? _loadImageBytes(imageUrl)
                          : Future.value(null),
                      builder: (context, snapshot) {
                        Uint8List? bytes = snapshot.data;
                        return CircleAvatar(
                          key: ValueKey(
                            '${imageUrl ?? 'default'}_${authProvider.imageVersion}',
                          ),
                          backgroundColor: const Color(0xFF0D1845),
                          backgroundImage: bytes != null
                              ? MemoryImage(bytes)
                              : null,
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? Text(
                                  initial,
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                height: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1845).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF0D1845),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'User Profile',
                        style: TextStyle(
                          color: Color(0xFF343A40),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<String>(
                value: 'logout',
                height: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFF343A40),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSidebarOpen ? 280 : 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    // Header - Always visible
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _isSidebarOpen
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.dashboard,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        secondChild: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.dashboard,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Section Divider
                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Inventory Section
                    _buildMainSectionTile(Icons.inventory_2, 'Inventory', [
                      _buildPrimarySubTile('Products', Icons.inventory),
                      _buildPrimarySubTile('Create Product', Icons.add_circle),
                      _buildPrimarySubTile(
                        'Low Stock Products',
                        Icons.warning_amber,
                      ),
                      _buildSectionDivider(isSubDivider: true),
                      _buildPrimarySubTile('Category', Icons.category),
                      _buildPrimarySubTile(
                        'Sub Category',
                        Icons.subdirectory_arrow_right,
                      ),
                      _buildPrimarySubTile('Vendor', Icons.business_center),
                      _buildPrimarySubTile(
                        'Print Barcode',
                        Icons.qr_code_scanner,
                      ),
                      _buildSectionDivider(isSubDivider: true),
                      // Variants Subsection
                      _buildSubHeaderTile('Variants', Icons.palette),
                      _buildSecondarySubTile('Color', Icons.color_lens),
                      _buildSecondarySubTile('Sizes', Icons.straighten),
                      _buildSecondarySubTile('Seasons', Icons.wb_sunny),
                      _buildSecondarySubTile('Material', Icons.texture),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Sales Section
                    _buildMainSectionTile(Icons.shopping_cart, 'Sales', [
                      _buildPrimarySubTile('Invoices', Icons.receipt_long),
                      _buildPrimarySubTile('Sales Return', Icons.undo),
                      _buildPrimarySubTile('POS', Icons.smartphone),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Purchase Section
                    _buildMainSectionTile(Icons.shopping_bag, 'Purchase', [
                      _buildPrimarySubTile('Purchase Listing', Icons.list_alt),
                      _buildPrimarySubTile(
                        'Purchase Return',
                        Icons.assignment_return,
                      ),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Finance Section
                    _buildMainSectionTile(
                      Icons.account_balance_wallet,
                      'Finance & Accounts',
                      [
                        _buildParentSubTile('Expenses', Icons.money_off, [
                          _buildNestedSubTile('Expenses', Icons.receipt_long),
                          _buildNestedSubTile(
                            'Expense Category',
                            Icons.category,
                          ),
                        ]),
                        _buildParentSubTile('Income', Icons.trending_up, [
                          _buildNestedSubTile('Income', Icons.attach_money),
                          _buildNestedSubTile(
                            'Income Category',
                            Icons.category,
                          ),
                        ]),
                        _buildPrimarySubTile(
                          'Bank Accounts',
                          Icons.account_balance,
                        ),
                        _buildPrimarySubTile('Trial Balance', Icons.balance),
                        _buildPrimarySubTile(
                          'Account Statement',
                          Icons.description,
                        ),
                        _buildPrimarySubTile(
                          'Cashflow',
                          Icons.account_balance_wallet,
                        ),
                      ],
                    ),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // People Section
                    _buildMainSectionTile(Icons.people_alt, 'Peoples', [
                      _buildPrimarySubTile('Credit Customers', Icons.people),
                      _buildPrimarySubTile('Suppliers', Icons.business),
                      _buildPrimarySubTile('Employees (HRM)', Icons.badge),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Reports Section
                    _buildMainSectionTile(Icons.analytics, 'Reports', [
                      _buildBulletPointTile('Sales Report'),
                      _buildBulletPointTile('Best Seller'),
                      _buildSectionDivider(isSubDivider: true),
                      _buildSecondarySubTile(
                        'Purchase Report',
                        Icons.bar_chart,
                      ),
                      _buildSecondarySubTile(
                        'Inventory Report',
                        Icons.inventory_2,
                      ),
                      _buildSecondarySubTile('Invoice Report', Icons.receipt),
                      _buildSecondarySubTile('Supplier Report', Icons.business),
                      _buildSecondarySubTile('Vendor Report', Icons.people),
                      _buildSecondarySubTile('Product Report', Icons.inventory),
                      _buildSecondarySubTile('Expense Report', Icons.money_off),
                      _buildSecondarySubTile(
                        'Income Report',
                        Icons.trending_up,
                      ),
                      _buildSecondarySubTile(
                        'Tax Report',
                        Icons.account_balance,
                      ),
                      _buildSecondarySubTile('Profit & Loss', Icons.show_chart),
                      _buildSecondarySubTile(
                        'Annual Report',
                        Icons.calendar_today,
                      ),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Users Section
                    _buildMainSectionTile(Icons.admin_panel_settings, 'Users', [
                      _buildPrimarySubTile('Users', Icons.group),
                      _buildPrimarySubTile(
                        'Roles & Permissions',
                        Icons.security,
                      ),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Settings Section
                    _buildMainSectionTile(Icons.settings, 'Settings', [
                      _buildPrimarySubTile('General Settings', Icons.settings),
                      _buildPrimarySubTile('System Settings', Icons.computer),
                      _buildPrimarySubTile(
                        'Financial Settings',
                        Icons.account_balance_wallet,
                      ),
                      _buildPrimarySubTile('Other Settings', Icons.more_horiz),
                      _buildSectionDivider(isSubDivider: true),
                      _buildLogoutTile('Logout', Icons.logout),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Quick Actions
                    _buildQuickActionTile(Icons.point_of_sale, 'POS', [
                      _buildPrimarySubTile('Cash', Icons.payments),
                      _buildPrimarySubTile('Card', Icons.credit_card),
                      _buildPrimarySubTile('Bank', Icons.account_balance),
                    ]),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildMainContent(),
                ),
              ),
            ],
          ),
          // Toggle Button - Always on top
          Positioned(
            left: (_isSidebarOpen ? 280 : 60) - 15,
            top: 40,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1845),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: AnimatedRotation(
                  turns: _isSidebarOpen ? 0.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: toggleSidebar,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: DropdownButton<String>(
        value: selectedTopSellingPeriod,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C757D)),
        items: ['Today', 'This Week', 'This Month', 'This Year']
            .map(
              (period) => DropdownMenuItem(
                value: period,
                child: Text(
                  period,
                  style: const TextStyle(color: Color(0xFF6C757D)),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            updateTopSellingPeriod(value);
          }
        },
      ),
    );
  }

  // New sidebar methods for improved design
  Widget _buildSectionDivider({bool isSubDivider = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isSubDivider ? 4 : 8),
      height: 1,
      color: Colors.white.withOpacity(isSubDivider ? 0.2 : 0.3),
    );
  }

  Widget _buildMainSectionTile(
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSidebarOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_isSidebarOpen) ...children,
      ],
    );
  }

  Widget _buildPrimarySubTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
      child: InkWell(
        onTap: () => updateContent(title),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: _isSidebarOpen
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.05),
          ),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSidebarOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.8), size: 12),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondarySubTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 32, right: 16, bottom: 4),
      child: InkWell(
        onTap: () => updateContent(title),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: _isSidebarOpen
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSidebarOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.7), size: 10),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.7), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubHeaderTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6, top: 6),
      child: Container(
        padding: _isSidebarOpen
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white.withOpacity(0.08),
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isSidebarOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 12),
            ],
          ),
          secondChild: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPointTile(String title) {
    return Container(
      margin: const EdgeInsets.only(left: 32, right: 16, bottom: 4),
      child: InkWell(
        onTap: () => updateContent(title),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: _isSidebarOpen
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSidebarOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90E2),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90E2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSidebarOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (children.isNotEmpty)
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (_isSidebarOpen && children.isNotEmpty) ...children,
      ],
    );
  }

  Widget _buildLogoutTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
      child: InkWell(
        onTap: () async {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.logout();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: _isSidebarOpen
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.red.withOpacity(0.1),
          ),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSidebarOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.red.withOpacity(0.8), size: 12),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, color: Colors.red.withOpacity(0.8), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentSubTile(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
          child: Container(
            padding: _isSidebarOpen
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withOpacity(0.05),
            ),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isSidebarOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white.withOpacity(0.8), size: 12),
                ],
              ),
              secondChild: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isSidebarOpen) ...children,
      ],
    );
  }

  Widget _buildNestedSubTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 40, right: 16, bottom: 4),
      child: InkWell(
        onTap: () => updateContent(title),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      change,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
                  fontSize: 28,
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

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF7F7F7)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEE2E6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C757D),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF343A40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
    String name,
    String price,
    String sales,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image, color: Colors.grey),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
          ),
        ),
        subtitle: Text(
          '$price\n$sales',
          style: const TextStyle(color: Color(0xFF6C757D)),
        ),
        trailing: Icon(Icons.trending_up, color: color),
      ),
    );
  }

  Widget _buildLowStockItem(String name, String id, String stock) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory, color: Colors.grey),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
          ),
        ),
        subtitle: Text(
          'ID: $id\nInstock: $stock',
          style: const TextStyle(color: Color(0xFF6C757D)),
        ),
      ),
    );
  }

  Widget _buildRecentSaleItem(
    String productName,
    String category,
    String price,
    String date,
    String status,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_bag, color: Colors.grey),
        ),
        title: Text(
          productName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: const TextStyle(color: Color(0xFF6C757D))),
            Text(
              '$price • $date',
              style: const TextStyle(color: Color(0xFF6C757D)),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesStaticItem(
    String label,
    String value,
    String change,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF343A40),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                change.startsWith('+')
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTopCustomerItem(
    String name,
    String location,
    int orders,
    double amount,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.person, color: Colors.grey),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF000000),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF6C757D),
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(color: Color(0xFF6C757D)),
                ),
              ],
            ),
            Text(
              '$orders Orders',
              style: const TextStyle(color: Color(0xFF6C757D)),
            ),
          ],
        ),
        trailing: Text(
          'Rs ${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF343A40),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCategoryItem(String name, int sales) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.category, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF343A40),
              ),
            ),
          ),
          Text(
            '${sales}Sales',
            style: const TextStyle(color: Color(0xFF6C757D)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF343A40),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

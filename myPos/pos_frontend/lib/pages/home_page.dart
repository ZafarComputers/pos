// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../widgets/sidebar.dart';

// Import all your pages (same as before)
import 'dashboard_page.dart';
import 'inventory/products_page.dart';
import 'inventory/expired_products_page.dart';
import 'inventory/low_stock_page.dart';
import 'inventory/category_page.dart';
import 'inventory/sub_category_page.dart';
import 'inventory/brands_page.dart';
import 'inventory/variants_page.dart';
import 'inventory/attributes_page.dart';
import 'inventory/barcode_page.dart';
import 'inventory/qr_code_page.dart';
import 'sales/pos_sales_page.dart';
import 'sales/invoice_page.dart';
import 'sales/sales_return_page.dart';
import 'purchases/purchases_page.dart';
import 'purchases/purchase_order_page.dart';
import 'purchases/purchase_return_page.dart';
import 'finance_accounts/income_category_page.dart';
import 'finance_accounts/balance_sheet_page.dart';
import 'finance_accounts/trial_balance_page.dart';
import 'finance_accounts/cashflow_page.dart';
import 'finance_accounts/account_statement_page.dart';
import 'people/customers_page.dart';
import 'people/suppliers_page.dart';
import 'people/employees_page.dart';
import 'reports/sales_report_page.dart';
import 'reports/purchase_report_page.dart';
import 'reports/inventory_report_page.dart';
import 'reports/invoice_report_page.dart';
import 'reports/supplier_report_page.dart';
import 'reports/customer_report_page.dart';
import 'reports/product_report_page.dart';
import 'reports/expense_report_page.dart';
import 'reports/income_report_page.dart';
import 'user_management/users_page.dart';
import 'user_management/roles_permissions_page.dart';
import 'user_management/deleted_account_requests_page.dart';
import 'settings/general_settings_page.dart';
import 'settings/system_settings_page.dart';
import 'settings/financial_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ✅ Map of menu item titles → page widgets
  final Map<String, Widget> _pages = {
    'Dashboard': const DashboardPage(),
    'Products': const ProductsPage(),
    'Expired Products': const ExpiredProductsPage(),
    'Low Stock': const LowStockPage(),
    'Category': const CategoryPage(),
    'Sub-Category': const SubCategoryPage(),
    'Brands': const BrandsPage(),
    'Variants': const VariantsPage(),
    'Attributes': const AttributesPage(),
    'Barcode': const BarcodePage(),
    'QR Code': const QRCodePage(),
    'POS Sales': const POSalesPage(),
    'Invoice': const InvoicePage(),
    'Sales Return': const SalesReturnPage(),
    'Purchases': const PurchasesPage(),
    'Purchase Order': const PurchaseOrderPage(),
    'Purchase Return': const PurchaseReturnPage(),
    // 'Expense': const ExpensePage(),
    // 'Expense Category': const ExpenseCategoryPage(),
    // 'Income': const IncomePage(),
    'Income Category': const IncomeCategoryPage(),
    // 'Bank Account': const BankAccountPage(),
    'Balance Sheet': const BalanceSheetPage(),
    'Trial Balance': const TrialBalancePage(),
    'Cashflow': const CashflowPage(),
    'Account Statement': const AccountStatementPage(),
    'Customers': const CustomersPage(),
    'Suppliers': const SuppliersPage(),
    'Employees': const EmployeesPage(),
    'Sales Report': const SalesReportPage(),
    'Purchase Report': const PurchaseReportPage(),
    'Inventory Report': const InventoryReportPage(),
    'Invoice Report': const InvoiceReportPage(),
    'Supplier Report': const SupplierReportPage(),
    'Customer Report': const CustomerReportPage(),
    'Product Report': const ProductReportPage(),
    'Expense Report': const ExpenseReportPage(),
    'Income Report': const IncomeReportPage(),
    'Users': const UsersPage(),
    'Roles & Permissions': const RolesPermissionsPage(),
    'Deleted Account Requests': const DeletedAccountRequestsPage(),
    'General Settings': const GeneralSettingsPage(),
    'System Settings': const SystemSettingsPage(),
    'Financial Settings': const FinancialSettingsPage(),
  };

  Widget _currentPage = const DashboardPage(); // default

  void _onMenuItemSelected(String pageTitle) {
    if (pageTitle == 'Logout') {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      _currentPage = _pages[pageTitle] ??
          Center(child: Text('Page not found: $pageTitle'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Row(
              children: [
                Sidebar(onMenuItemSelected: _onMenuItemSelected),
                Expanded(child: _currentPage),
              ],
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Dashboard',
      theme: ThemeData(
        primaryColor: const Color(0xFF007BFF), // Bootstrap primary blue
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Light gray
        cardColor: Colors.white,
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const DashboardPage(),
    );
  }
}

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
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                  colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
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
            icon: Icon(
              _isSidebarOpen ? Icons.menu_open : Icons.menu,
              color: const Color(0xFF6C757D),
            ),
            onPressed: toggleSidebar,
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFF6C757D)),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF007BFF),
              child: Text('A', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarOpen ? 280 : 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF7722), Color(0xFFBF5F1B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                Visibility(
                  visible: _isSidebarOpen,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                _buildSidebarTile(Icons.inventory, 'Inventory', [
                  _buildSubTile('Products', Icons.inventory),
                  _buildSubTile('Create Product', Icons.add),
                  _buildSubTile('Expired Products', Icons.warning),
                  _buildSubTile('Category', Icons.category),
                  _buildSubTile('Sub Category', Icons.subdirectory_arrow_right),
                  _buildSubTile('Vendor', Icons.business),
                  _buildSubTile('Variants', Icons.style),
                  _buildSubTile('Size', Icons.straighten),
                  _buildSubTile('Color', Icons.color_lens),
                  _buildSubTile('Season', Icons.calendar_view_month),
                  _buildSubTile('Material', Icons.texture),
                  _buildSubTile('Print Barcode', Icons.qr_code),
                ]),
                _buildSidebarTile(Icons.shopping_cart, 'Sales', [
                  _buildSubTile('Sales', Icons.point_of_sale),
                  _buildSubTile('Invoices', Icons.receipt),
                  _buildSubTile('Sales Return', Icons.undo),
                  _buildSubTile('POS', Icons.point_of_sale),
                ]),
                _buildSidebarTile(Icons.shopping_bag, 'Purchase', [
                  _buildSubTile('Purchase Listing', Icons.list),
                  _buildSubTile('Purchases', Icons.shopping_bag),
                  _buildSubTile('Purchase Create', Icons.add),
                  _buildSubTile('Purchase Return', Icons.undo),
                ]),
                _buildSidebarTile(Icons.account_balance, 'Finance & Accounts', [
                  _buildSubTile('Expenses', Icons.money_off),
                  _buildSubTile('Income', Icons.attach_money),
                  _buildSubTile('Bank Accounts', Icons.account_balance),
                  _buildSubTile('Trial Balance', Icons.balance),
                  _buildSubTile('Account Statement', Icons.description),
                ]),
                _buildSidebarTile(Icons.people, 'Peoples', [
                  _buildSubTile('Customer', Icons.people),
                  _buildSubTile('Suppliers', Icons.business),
                  _buildSubTile('Employees (HRM)', Icons.person),
                ]),
                _buildSidebarTile(Icons.bar_chart, 'Reports', [
                  _buildSmallSubTile('Sales Report'),
                  _buildSmallSubTile('Best Seller'),
                  _buildSubTile('Purchase Report', Icons.bar_chart),
                  _buildSubTile('Inventory Report', Icons.bar_chart),
                  _buildSubTile('Invoice Report', Icons.bar_chart),
                  _buildSubTile('Supplier Report', Icons.bar_chart),
                  _buildSubTile('Customer Report', Icons.bar_chart),
                  _buildSubTile('Product Report', Icons.bar_chart),
                  _buildSubTile('Expense Report', Icons.bar_chart),
                  _buildSubTile('Income Report', Icons.bar_chart),
                  _buildSubTile('Tax Report', Icons.bar_chart),
                  _buildSubTile('Profit & Loss', Icons.bar_chart),
                  _buildSubTile('Annual Report', Icons.bar_chart),
                ]),
                _buildSidebarTile(Icons.admin_panel_settings, 'Users', [
                  _buildSubTile('Users', Icons.people),
                  _buildSubTile('Roles & Permissions', Icons.security),
                  _buildSubTile('Delete Account Request', Icons.delete),
                ]),
                _buildSidebarTile(Icons.settings, 'Settings', [
                  _buildSubTile('General Settings', Icons.settings),
                  _buildSubTile('System Settings', Icons.computer),
                  _buildSubTile(
                    'Financial Settings',
                    Icons.account_balance_wallet,
                  ),
                  _buildSubTile('Other Settings', Icons.more_horiz),
                  _buildSubTile('Logout', Icons.logout),
                ]),
                _buildSidebarTile(Icons.add, 'Add New', []),
                _buildSidebarTile(Icons.point_of_sale, 'POS', [
                  _buildSubTile('Cash', Icons.money),
                  _buildSubTile('Card', Icons.credit_card),
                  _buildSubTile('Bank', Icons.account_balance),
                ]),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metrics Cards
                    Row(
                      children: [
                        _buildMetricCard(
                          'Total Sales',
                          '\$48,988,078',
                          Icons.trending_up,
                          Colors.green,
                          '+22%',
                        ),
                        _buildMetricCard(
                          'Total Purchase',
                          '\$16,478,145',
                          Icons.trending_down,
                          Colors.red,
                          '-22%',
                        ),
                        _buildMetricCard(
                          'Total Purchase Return',
                          '\$24,145,789',
                          Icons.undo,
                          Colors.green,
                          '+22%',
                        ),
                        _buildMetricCard(
                          'Profit',
                          '\$8,458,798',
                          Icons.attach_money,
                          Colors.blue,
                          '+35%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildMetricCard(
                          'Invoice Due',
                          '\$48,988,78',
                          Icons.receipt,
                          Colors.orange,
                          '+35%',
                        ),
                        _buildMetricCard(
                          'Total Expenses',
                          '\$8,980,097',
                          Icons.money_off,
                          Colors.red,
                          '+41%',
                        ),
                        _buildMetricCard(
                          'Total Payment Returns',
                          '\$78,458,798',
                          Icons.refresh,
                          Colors.red,
                          '-20%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Chart
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
                              'Sales & Purchase',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            Row(
                              children: [
                                _buildTimeButton('1D'),
                                _buildTimeButton('1W'),
                                _buildTimeButton('1M'),
                                _buildTimeButton('3M'),
                                _buildTimeButton('6M'),
                                _buildTimeButton('1Y'),
                              ],
                            ),
                            SizedBox(
                              height: 250,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        const FlSpot(0, 3),
                                        const FlSpot(1, 1),
                                        const FlSpot(2, 4),
                                        const FlSpot(3, 2),
                                        const FlSpot(4, 5),
                                      ],
                                      isCurved: true,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF007BFF),
                                          Color(0xFF0056B3),
                                        ],
                                      ),
                                      barWidth: 4,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFF007BFF,
                                            ).withOpacity(0.3),
                                            const Color(
                                              0xFF0056B3,
                                            ).withOpacity(0.1),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildChartSummary(
                                  Icons.shopping_cart,
                                  'Total Purchase',
                                  '3K',
                                ),
                                _buildChartSummary(
                                  Icons.sell,
                                  'Total Sales',
                                  '1K',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Overall Information
                    Row(
                      children: [
                        _buildInfoCard('Suppliers', '6987', Icons.business),
                        _buildInfoCard('Customers', '4896', Icons.people),
                        _buildInfoCard('Orders', '487', Icons.shopping_bag),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Top Selling Products
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
                              'Top Selling Products',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            Row(children: [_buildDropdownButton('Today')]),
                            _buildProductItem(
                              'Charger Cable - Lighting',
                              '\$187',
                              '247+ Sales',
                              Colors.green,
                            ),
                            _buildProductItem(
                              'Yves Saint Eau De Parfum',
                              '\$145',
                              '289+ Sales',
                              Colors.green,
                            ),
                            _buildProductItem(
                              'Apple Airpods 2',
                              '\$458',
                              '300+ Sales',
                              Colors.green,
                            ),
                            _buildProductItem(
                              'Vacuum Cleaner',
                              '\$139',
                              '225+ Sales',
                              Colors.orange,
                            ),
                            _buildProductItem(
                              'Samsung Galaxy S21 Fe 5g',
                              '\$898',
                              '365+ Sales',
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Low Stock Products
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
                              'Low Stock Products',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            _buildLowStockItem('Dell XPS 13', '#665814', '08'),
                            _buildLowStockItem(
                              'Vacuum Cleaner Robot',
                              '#940004',
                              '14',
                            ),
                            _buildLowStockItem(
                              'KitchenAid Stand Mixer',
                              '#325569',
                              '21',
                            ),
                            _buildLowStockItem(
                              'Levi\'s Trucker Jacket',
                              '#124588',
                              '12',
                            ),
                            _buildLowStockItem(
                              'Lay\'s Classic',
                              '#365586',
                              '10',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(IconData icon, String title, List<Widget> children) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Visibility(
            visible: _isSidebarOpen,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          onTap: () => updateContent(title),
        ),
        ...(_isSidebarOpen ? children : []),
      ],
    );
  }

  Widget _buildSubTile(String title, IconData icon) {
    return Visibility(
      visible: _isSidebarOpen,
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 16),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        onTap: () => updateContent(title),
      ),
    );
  }

  Widget _buildSmallSubTile(String title) {
    return Visibility(
      visible: _isSidebarOpen,
      child: ListTile(
        leading: const Icon(Icons.bar_chart, size: 16, color: Colors.white70),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        onTap: () => updateContent(title),
      ),
    );
  }

  Widget _buildTimeButton(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF6C757D))),
      ),
    );
  }

  Widget _buildDropdownButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE2E6)),
      ),
      child: Row(
        children: [
          Text(text, style: const TextStyle(color: Color(0xFF6C757D))),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF6C757D)),
        ],
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
                  colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
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

  Widget _buildChartSummary(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Color(0xFF6C757D))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF343A40),
          ),
        ),
      ],
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
}

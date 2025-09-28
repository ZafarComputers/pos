import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
            icon: const Icon(Icons.notifications, color: Color(0xFF6C757D)),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF0D1845),
              child: Text('A', style: TextStyle(color: Colors.white)),
            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _isSidebarOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
                      _buildPrimarySubTile('Expired Products', Icons.warning_amber),
                      _buildSectionDivider(isSubDivider: true),
                      _buildPrimarySubTile('Category', Icons.category),
                      _buildPrimarySubTile('Sub Category', Icons.subdirectory_arrow_right),
                      _buildPrimarySubTile('Vendor', Icons.business_center),
                      _buildPrimarySubTile('Print Barcode', Icons.qr_code_scanner),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Sales Section
                    _buildMainSectionTile(Icons.shopping_cart, 'Sales', [
                      _buildPrimarySubTile('Sales', Icons.point_of_sale),
                      _buildPrimarySubTile('Invoices', Icons.receipt_long),
                      _buildPrimarySubTile('Sales Return', Icons.undo),
                      _buildPrimarySubTile('POS', Icons.smartphone),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Purchase Section
                    _buildMainSectionTile(Icons.shopping_bag, 'Purchase', [
                      _buildPrimarySubTile('Purchase Listing', Icons.list_alt),
                      _buildPrimarySubTile('Purchases', Icons.shopping_bag),
                      _buildPrimarySubTile('Purchase Create', Icons.add_shopping_cart),
                      _buildPrimarySubTile('Purchase Return', Icons.assignment_return),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Finance Section
                    _buildMainSectionTile(Icons.account_balance_wallet, 'Finance & Accounts', [
                      _buildPrimarySubTile('Expenses', Icons.money_off),
                      _buildPrimarySubTile('Income', Icons.trending_up),
                      _buildPrimarySubTile('Bank Accounts', Icons.account_balance),
                      _buildPrimarySubTile('Trial Balance', Icons.balance),
                      _buildPrimarySubTile('Account Statement', Icons.description),
                      _buildPrimarySubTile('Cashflow', Icons.account_balance_wallet),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // People Section
                    _buildMainSectionTile(Icons.people_alt, 'Peoples', [
                      _buildPrimarySubTile('Customer', Icons.people),
                      _buildPrimarySubTile('Suppliers', Icons.business),
                      _buildPrimarySubTile('Employees (HRM)', Icons.badge),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Reports Section
                    _buildMainSectionTile(Icons.analytics, 'Reports', [
                      _buildBulletPointTile('Sales Report'),
                      _buildBulletPointTile('Best Seller'),
                      _buildSectionDivider(isSubDivider: true),
                      _buildSecondarySubTile('Purchase Report', Icons.bar_chart),
                      _buildSecondarySubTile('Inventory Report', Icons.inventory_2),
                      _buildSecondarySubTile('Invoice Report', Icons.receipt),
                      _buildSecondarySubTile('Supplier Report', Icons.business),
                      _buildSecondarySubTile('Customer Report', Icons.people),
                      _buildSecondarySubTile('Product Report', Icons.inventory),
                      _buildSecondarySubTile('Expense Report', Icons.money_off),
                      _buildSecondarySubTile('Income Report', Icons.trending_up),
                      _buildSecondarySubTile('Tax Report', Icons.account_balance),
                      _buildSecondarySubTile('Profit & Loss', Icons.show_chart),
                      _buildSecondarySubTile('Annual Report', Icons.calendar_today),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Users Section
                    _buildMainSectionTile(Icons.admin_panel_settings, 'Users', [
                      _buildPrimarySubTile('Users', Icons.group),
                      _buildPrimarySubTile('Roles & Permissions', Icons.security),
                      _buildPrimarySubTile('Delete Account Request', Icons.delete_forever),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Settings Section
                    _buildMainSectionTile(Icons.settings, 'Settings', [
                      _buildPrimarySubTile('General Settings', Icons.settings),
                      _buildPrimarySubTile('System Settings', Icons.computer),
                      _buildPrimarySubTile('Financial Settings', Icons.account_balance_wallet),
                      _buildPrimarySubTile('Other Settings', Icons.more_horiz),
                      _buildSectionDivider(isSubDivider: true),
                      _buildLogoutTile('Logout', Icons.logout),
                    ]),

                    if (_isSidebarOpen) _buildSectionDivider(),

                    // Quick Actions
                    _buildQuickActionTile(Icons.add_circle, 'Add New', []),
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
                                              Color(0xFF0D1845),
                                              Color(0xFF0A1238),
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

  // New sidebar methods for improved design
  Widget _buildSectionDivider({bool isSubDivider = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isSubDivider ? 4 : 8),
      height: 1,
      color: Colors.white.withOpacity(isSubDivider ? 0.2 : 0.3),
    );
  }

  Widget _buildMainSectionTile(IconData icon, String title, List<Widget> children) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSidebarOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
            crossFadeState: _isSidebarOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  size: 12,
                ),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
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
            crossFadeState: _isSidebarOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.7),
                  size: 10,
                ),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.7),
                  size: 14,
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
            crossFadeState: _isSidebarOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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

  Widget _buildQuickActionTile(IconData icon, String title, List<Widget> children) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isSidebarOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
        onTap: () => updateContent(title),
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
            crossFadeState: _isSidebarOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.red.withOpacity(0.8),
                  size: 12,
                ),
              ],
            ),
            secondChild: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  icon,
                  color: Colors.red.withOpacity(0.8),
                  size: 16,
                ),
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

  Widget _buildChartSummary(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
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
            color: Color(0xFF0D1845),
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

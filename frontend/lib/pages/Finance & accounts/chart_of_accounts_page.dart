import 'package:flutter/material.dart';
import '../../services/chart_of_accounts_service.dart';
import 'create_coa_page.dart';

class ChartOfAccountsPage extends StatefulWidget {
  const ChartOfAccountsPage({super.key});

  @override
  State<ChartOfAccountsPage> createState() => _ChartOfAccountsPageState();
}

class _ChartOfAccountsPageState extends State<ChartOfAccountsPage> {
  // New: All COAs from API
  List<ChartOfAccount> _allCoas = [];
  List<ChartOfAccount> _filteredCoas = [];

  // Hierarchical data from new API
  List<MainHeadOfAccountWithSubs> _mainHeadAccountsWithSubs = [];
  List<SubHeadOfAccountWithAccounts> _subHeadAccountsWithAccounts = [];

  bool _isLoading = true;

  // Filter states
  MainHeadAccount? _selectedMainHead; // For direct COA selection
  AccountOfSubHead? _selectedHead;
  MainHeadOfAccountWithSubs?
  _selectedHierarchicalMainHead; // For hierarchical filtering
  SubHeadOfAccountWithAccounts? _selectedHierarchicalSubHead;

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 10;
  List<ChartOfAccount> _paginatedCoas = [];

  @override
  void initState() {
    super.initState();
    _loadMainHeadAccounts();
  }

  // Load main head accounts
  Future<void> _loadMainHeadAccounts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load all COAs from the API
      _allCoas = await ChartOfAccountsService.getAllChartOfAccounts();

      // Load hierarchical main head accounts with subs from new API
      _mainHeadAccountsWithSubs =
          await ChartOfAccountsService.getAllMainHeadAccounts();

      setState(() {
        _filteredCoas = _allCoas; // Initially show all COAs
        _applyPagination(); // Apply pagination to all COAs
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load chart of accounts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load sub head accounts when main head is selected
  Future<void> _loadSubHeadAccounts(int mainHeadId) async {
    try {
      // Find the selected main head with subs from the hierarchical data
      final selectedMainHead = _mainHeadAccountsWithSubs.firstWhere(
        (mainHead) => mainHead.id == mainHeadId,
        orElse: () => throw Exception('Main head not found'),
      );

      // The subs are already loaded in the hierarchical data
      _subHeadAccountsWithAccounts = selectedMainHead.subs;

      setState(() {
        _filteredCoas = _allCoas
            .where((coa) => coa.main.id == mainHeadId)
            .toList();
        _applyPagination();
        _selectedHierarchicalSubHead = null; // Reset sub head selection
        _selectedHead = null; // Reset head selection
      });
    } catch (e) {
      setState(() {
        _selectedHierarchicalSubHead = null;
        _selectedHead = null;
        _subHeadAccountsWithAccounts = [];
        _paginatedCoas = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load sub head accounts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load head accounts when sub head is selected
  Future<void> _loadHeadAccounts(int subHeadId) async {
    try {
      // Find the selected sub head with accounts from the hierarchical data
      SubHeadOfAccountWithAccounts? selectedSubHead;
      for (final mainHead in _mainHeadAccountsWithSubs) {
        try {
          selectedSubHead = mainHead.subs.firstWhere(
            (sub) => sub.id == subHeadId,
          );
          break;
        } catch (e) {
          // Continue to next main head
          continue;
        }
      }

      if (selectedSubHead == null) {
        throw Exception('Sub head not found');
      }

      setState(() {
        // Filter COAs by sub head
        _filteredCoas = _allCoas
            .where((coa) => coa.sub.id == subHeadId)
            .toList();
        _applyPagination();
        _selectedHead = null; // Reset head selection
      });
    } catch (e) {
      setState(() {
        _selectedHead = null;
        _paginatedCoas = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load head accounts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Apply pagination to COAs
  void _applyPagination() {
    if (_filteredCoas.isEmpty) {
      setState(() {
        _paginatedCoas = [];
      });
      return;
    }

    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;

    if (startIndex >= _filteredCoas.length) {
      setState(() {
        currentPage = 1;
      });
      _applyPagination();
      return;
    }

    setState(() {
      _paginatedCoas = _filteredCoas.sublist(
        startIndex,
        endIndex > _filteredCoas.length ? _filteredCoas.length : endIndex,
      );
    });
  }

  // Handle page changes
  void _changePage(int newPage) {
    setState(() {
      currentPage = newPage;
    });
    _applyPagination();
  }

  // Create new sub head account
  Future<void> _createNewSubHead(String name) async {
    if (_selectedHierarchicalMainHead == null) return;

    try {
      await ChartOfAccountsService.createCoaSub({
        'title': name,
        'coa_main_id': _selectedHierarchicalMainHead!.id,
        'status': 'active',
      });

      // Reload the hierarchical data to include the new sub head
      final reloadedData =
          await ChartOfAccountsService.getAllMainHeadAccounts();

      // Find the currently selected main head in the reloaded data to maintain selection
      final currentMainHeadId = _selectedHierarchicalMainHead!.id;
      final updatedMainHead = reloadedData.firstWhere(
        (mainHead) => mainHead.id == currentMainHeadId,
        orElse: () => reloadedData.isNotEmpty
            ? reloadedData.first
            : _selectedHierarchicalMainHead!,
      );

      setState(() {
        _mainHeadAccountsWithSubs = reloadedData;
        _selectedHierarchicalMainHead = updatedMainHead;
      });

      _loadSubHeadAccounts(updatedMainHead.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sub head account created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create sub head account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Create new head account
  Future<void> _createNewHead(String name) async {
    if (_selectedHierarchicalSubHead == null) return;

    try {
      await ChartOfAccountsService.createHeadAccount({
        'name': name,
        'code': name.toUpperCase().replaceAll(' ', '_'),
        'sub_head_id': _selectedHierarchicalSubHead!.id,
        'main_head_id': _selectedHierarchicalMainHead!.id,
        'status': 'active',
      });

      // Reload the hierarchical data to include the new head account
      final reloadedData =
          await ChartOfAccountsService.getAllMainHeadAccounts();

      // Find the currently selected main head in the reloaded data to maintain selection
      final currentMainHeadId = _selectedHierarchicalMainHead!.id;
      final updatedMainHead = reloadedData.firstWhere(
        (mainHead) => mainHead.id == currentMainHeadId,
        orElse: () => reloadedData.isNotEmpty
            ? reloadedData.first
            : _selectedHierarchicalMainHead!,
      );

      setState(() {
        _mainHeadAccountsWithSubs = reloadedData;
        _selectedHierarchicalMainHead = updatedMainHead;
      });

      _loadSubHeadAccounts(updatedMainHead.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Head account created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create head account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show create new item dialog
  Future<void> _showCreateNewDialog(
    String type,
    Function(String) onCreate,
  ) async {
    final TextEditingController controller = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New $type'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: '$type Name',
              hintText: 'Enter $type name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                onCreate(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  int _getTotalPages() {
    if (_filteredCoas.isEmpty) return 1;
    return (_filteredCoas.length / itemsPerPage).ceil();
  }

  bool _canGoToNextPage() {
    return currentPage < _getTotalPages();
  }

  List<Widget> _buildFilterRow() {
    List<Widget> widgets = [];

    // Main Head of Account Filter (hierarchical)
    widgets.add(
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 16,
                    color: Color(0xFF0D1845),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Main Head of Account',
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
              child: DropdownButtonFormField<MainHeadOfAccountWithSubs>(
                value: _selectedHierarchicalMainHead,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Select main head account',
                  hintStyle: TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
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
                    borderSide: BorderSide(color: Color(0xFF0D1845), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: _mainHeadAccountsWithSubs.map((mainHead) {
                  return DropdownMenuItem<MainHeadOfAccountWithSubs>(
                    value: mainHead,
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: Color(0xFF0D1845),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${mainHead.code} - ${mainHead.title}',
                          style: TextStyle(
                            color: Color(0xFF343A40),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedHierarchicalMainHead = value;
                    if (value != null) {
                      _loadSubHeadAccounts(value.id);
                    } else {
                      _selectedHierarchicalSubHead = null;
                      _selectedHead = null;
                      _subHeadAccountsWithAccounts = [];
                      _filteredCoas =
                          _allCoas; // Show all COAs when nothing selected
                      _applyPagination();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );

    // Sub Head of Account Filter (only show when main head is selected in hierarchy)
    if (_selectedHierarchicalMainHead != null) {
      widgets.add(const SizedBox(width: 16));
      widgets.add(
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_tree,
                      size: 16,
                      color: Color(0xFF0D1845),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Sub Head of Account',
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
                child: DropdownButtonFormField<SubHeadOfAccountWithAccounts>(
                  value: _selectedHierarchicalSubHead,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Select sub head account',
                    hintStyle: TextStyle(
                      color: Color(0xFFADB5BD),
                      fontSize: 14,
                    ),
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
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add, color: Color(0xFF0D1845), size: 20),
                      onPressed: () => _showCreateNewDialog(
                        'Sub Head Account',
                        _createNewSubHead,
                      ),
                      tooltip: 'Create New Sub Head Account',
                    ),
                  ),
                  items: _subHeadAccountsWithAccounts.map((subHead) {
                    return DropdownMenuItem<SubHeadOfAccountWithAccounts>(
                      value: subHead,
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_tree,
                            color: Color(0xFF0D1845),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${subHead.code} - ${subHead.title}',
                            style: TextStyle(
                              color: Color(0xFF343A40),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHierarchicalSubHead = value;
                      if (value != null) {
                        _loadHeadAccounts(value.id);
                      } else {
                        _selectedHead = null;
                        _paginatedCoas = [];
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Head of Account Filter (only show when sub head is selected in hierarchy)
    if (_selectedHierarchicalSubHead != null) {
      widgets.add(const SizedBox(width: 16));
      widgets.add(
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Color(0xFF0D1845)),
                    SizedBox(width: 6),
                    Text(
                      'Head of Account',
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
                child: DropdownButtonFormField<AccountOfSubHead>(
                  value: _selectedHead,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Select head account',
                    hintStyle: TextStyle(
                      color: Color(0xFFADB5BD),
                      fontSize: 14,
                    ),
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
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add, color: Color(0xFF0D1845), size: 20),
                      onPressed: () =>
                          _showCreateNewDialog('Head Account', _createNewHead),
                      tooltip: 'Create New Head Account',
                    ),
                  ),
                  items:
                      _selectedHierarchicalSubHead?.accounts.map((account) {
                        return DropdownMenuItem<AccountOfSubHead>(
                          value: account,
                          child: Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: Color(0xFF0D1845),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${account.code} - ${account.title}',
                                style: TextStyle(
                                  color: Color(0xFF343A40),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList() ??
                      [],
                  onChanged: (value) {
                    setState(() {
                      _selectedHead = value;
                      if (value != null) {
                        // Filter COAs by head account
                        _filteredCoas = _allCoas
                            .where((coa) => coa.id == value.id)
                            .toList();
                        _applyPagination();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildPageButtons() {
    final totalPages = _getTotalPages();
    final current = currentPage;

    const maxButtons = 5;
    final halfRange = maxButtons ~/ 2;

    int startPage = (current - halfRange).clamp(1, totalPages);
    int endPage = (startPage + maxButtons - 1).clamp(1, totalPages);

    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = (endPage - maxButtons + 1).clamp(1, totalPages);
    }

    List<Widget> buttons = [];

    for (int i = startPage; i <= endPage; i++) {
      buttons.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          child: ElevatedButton(
            onPressed: i == current ? null : () => _changePage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor: i == current
                  ? const Color(0xFF17A2B8)
                  : Colors.white,
              foregroundColor: i == current
                  ? Colors.white
                  : const Color(0xFF6C757D),
              elevation: i == current ? 2 : 0,
              side: i == current
                  ? null
                  : const BorderSide(color: Color(0xFFDEE2E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(32, 32),
            ),
            child: Text(
              i.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart of Account'),
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
                      Icons.account_tree,
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
                          'Chart of Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and organize your account hierarchy',
                          style: TextStyle(
                            fontSize: 12,
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
                          builder: (context) => const CreateCoaPage(),
                        ),
                      );
                      if (result == true) {
                        // Refresh the COAs list
                        _loadMainHeadAccounts();
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Account'),
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
                        children: [Row(children: _buildFilterRow())],
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
                            flex: 1,
                            child: Text('Account ID', style: _headerStyle()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Head of Account',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Head of Account ID',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Sub Head of Account',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Sub Head of Account ID',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Main Head of Account',
                              style: _headerStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Main Head of Account ID',
                              style: _headerStyle(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _paginatedCoas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No accounts found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _paginatedCoas.length,
                              itemBuilder: (context, index) {
                                final coa = _paginatedCoas[index];

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          coa.id.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF0D1845),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${coa.code} - ${coa.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          coa.id.toString(),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${coa.sub.code} - ${coa.sub.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          coa.sub.id.toString(),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${coa.main.code} - ${coa.main.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          coa.main.id.toString(),
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Pagination Controls
                    ...(_filteredCoas.isNotEmpty
                        ? [
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
                                      side: BorderSide(
                                        color: Color(0xFFDEE2E6),
                                      ),
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
                                      elevation: _canGoToNextPage() ? 2 : 0,
                                      side: _canGoToNextPage()
                                          ? null
                                          : BorderSide(
                                              color: Color(0xFFDEE2E6),
                                            ),
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
                                      'Page $currentPage of ${_getTotalPages()} (${_filteredCoas.length} total)',
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
                          ]
                        : []),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle() {
    return const TextStyle(
      fontWeight: FontWeight.w600,
      color: Color(0xFF343A40),
      fontSize: 13,
    );
  }
}

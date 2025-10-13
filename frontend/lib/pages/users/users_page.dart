import 'package:flutter/material.dart';
import 'models.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late List<User> _users = [];
  late bool _isLoading = false;
  late String _errorMessage = '';
  late bool _showCreateUserDialog = false;
  late bool _showEditUserDialog = false;
  late User? _currentUser = null;
  late bool _isSubmitting = false;

  // Form controllers
  late TextEditingController _usernameController = TextEditingController();
  late TextEditingController _emailController = TextEditingController();
  late TextEditingController _passwordController = TextEditingController();
  late TextEditingController _pictureController = TextEditingController();

  // Pagination variables
  int currentPage = 1;
  final int itemsPerPage = 10;
  List<User> _filteredUsers = [];

  // Selection state
  Set<int> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pictureController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Dummy data for now
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _users = [
          User(
            id: 1,
            username: 'admin',
            email: 'admin@pos.com',
            password: '********',
            picture: 'https://via.placeholder.com/50',
            isActive: true,
          ),
          User(
            id: 2,
            username: 'manager',
            email: 'manager@pos.com',
            password: '********',
            picture: 'https://via.placeholder.com/50',
            isActive: true,
          ),
          User(
            id: 3,
            username: 'cashier',
            email: 'cashier@pos.com',
            password: '********',
            picture: 'https://via.placeholder.com/50',
            isActive: false,
          ),
          User(
            id: 4,
            username: 'sales_rep',
            email: 'sales@pos.com',
            password: '********',
            picture: 'https://via.placeholder.com/50',
            isActive: true,
          ),
        ];
        _isLoading = false;
        _applyPagination();
      });
    });
  }

  void _applyPagination() {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    setState(() {
      _filteredUsers = _users.sublist(
        startIndex,
        endIndex > _users.length ? _users.length : endIndex,
      );
    });
  }

  void _changePage(int page) {
    if (page < 1 || page > _getTotalPages()) return;
    setState(() {
      currentPage = page;
    });
    _applyPagination();
  }

  int _getTotalPages() {
    return (_users.length / itemsPerPage).ceil();
  }

  bool _canGoToNextPage() {
    return currentPage < _getTotalPages();
  }

  void _openCreateUserDialog() {
    setState(() {
      _showCreateUserDialog = true;
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _pictureController.clear();
    });
  }

  void _openEditUserDialog(User user) {
    setState(() {
      _showEditUserDialog = true;
      _currentUser = user;
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _passwordController.text = user.password;
      _pictureController.text = user.picture;
    });
  }

  void _closeDialogs() {
    setState(() {
      _showCreateUserDialog = false;
      _showEditUserDialog = false;
      _currentUser = null;
    });
  }

  void _submitCreateUser() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final picture = _pictureController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final newUser = User(
      id: _users.length + 1,
      username: username,
      email: email,
      password: password,
      picture: picture.isNotEmpty ? picture : 'https://via.placeholder.com/50',
      isActive: true,
    );

    setState(() {
      _users.add(newUser);
      _isSubmitting = false;
      _showCreateUserDialog = false;
      _applyPagination();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User created successfully')),
    );
  }

  void _submitEditUser() async {
    if (_currentUser == null) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final picture = _pictureController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final updatedUser = User(
      id: _currentUser!.id,
      username: username,
      email: email,
      password: password,
      picture: picture.isNotEmpty ? picture : _currentUser!.picture,
      isActive: _currentUser!.isActive,
    );

    setState(() {
      final index = _users.indexWhere((u) => u.id == _currentUser!.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      _isSubmitting = false;
      _showEditUserDialog = false;
      _currentUser = null;
      _applyPagination();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User updated successfully')),
    );
  }

  void viewUser(User user) {
    // Navigate to user details page or show dialog
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for ${user.username}')),
    );
  }

  void deleteUser(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete ${user.username}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _users.removeWhere((u) => u.id == user.id);
                  _selectedUserIds.remove(user.id);
                  _applyPagination();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.username} deleted successfully')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _toggleUserSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _toggleSelectAllUsers() {
    setState(() {
      if (_selectedUserIds.length == _filteredUsers.length) {
        // Deselect all
        _selectedUserIds.clear();
      } else {
        // Select all visible users
        _selectedUserIds.addAll(_filteredUsers.map((user) => user.id));
      }
    });
  }

  bool _isAllUsersSelected() {
    return _filteredUsers.isNotEmpty && _selectedUserIds.length == _filteredUsers.length;
  }

  bool _isUserSelected(int userId) {
    return _selectedUserIds.contains(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
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
        child: Stack(
          children: [
            Column(
              children: [
                // Header with margin
                Container(
                  margin: const EdgeInsets.all(24),
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
                          Icons.people,
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
                              'User Management',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage system users and their access permissions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openCreateUserDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Create User'),
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

                // Error message display
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = '';
                            });
                          },
                          icon: Icon(Icons.close, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Table Section
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      child: Checkbox(
                                        value: _isAllUsersSelected(),
                                        onChanged: (value) => _toggleSelectAllUsers(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'UserName',
                                        style: _headerStyle(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          'Picture',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Email',
                                        style: _headerStyle(),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          'Password',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                        child: Text(
                                          'Status',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Actions',
                                        style: _headerStyle(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Table Body
                              Expanded(
                                child: _filteredUsers.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.people,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No users found',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _filteredUsers.length,
                                        itemBuilder: (context, index) {
                                          final user = _filteredUsers[index];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey[200]!,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 50,
                                                  child: Checkbox(
                                                    value: _isUserSelected(user.id),
                                                    onChanged: (value) => _toggleUserSelection(user.id),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    user.username,
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                    child: CircleAvatar(
                                                      radius: 20,
                                                      backgroundImage: NetworkImage(user.picture),
                                                      onBackgroundImageError: (_, __) =>
                                                          const Icon(Icons.person),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    user.email,
                                                    style: _cellStyle(),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                    child: Text(
                                                      '••••••••',
                                                      style: _cellStyle(),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  flex: 1,
                                                  child: Center(
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: user.isActive
                                                            ? Colors.green.withOpacity(0.1)
                                                            : Colors.red.withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        user.isActive ? 'Active' : 'Inactive',
                                                        style: TextStyle(
                                                          color: user.isActive
                                                              ? Colors.green[800]
                                                              : Colors.red[800],
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                SizedBox(
                                                  width: 60,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.edit,
                                                          color: Colors.blue,
                                                          size: 16,
                                                        ),
                                                        onPressed: () => _openEditUserDialog(user),
                                                        tooltip: 'Edit',
                                                        padding: const EdgeInsets.all(4),
                                                        constraints: const BoxConstraints(),
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

                              // Pagination Controls
                              if (_users.isNotEmpty) ...[
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
                                        icon: const Icon(
                                          Icons.chevron_left,
                                          size: 14,
                                        ),
                                        label: Text(
                                          'Previous',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: currentPage > 1
                                              ? const Color(0xFF17A2B8)
                                              : const Color(0xFF6C757D),
                                          elevation: 0,
                                          side: BorderSide(
                                            color: const Color(0xFFDEE2E6),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          padding: const EdgeInsets.symmetric(
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
                                        icon: const Icon(
                                          Icons.chevron_right,
                                          size: 14,
                                        ),
                                        label: Text(
                                          'Next',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _canGoToNextPage()
                                              ? const Color(0xFF17A2B8)
                                              : Colors.grey.shade300,
                                          foregroundColor: _canGoToNextPage()
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          elevation: _canGoToNextPage() ? 2 : 0,
                                          side: _canGoToNextPage()
                                              ? null
                                              : BorderSide(
                                                  color: const Color(0xFFDEE2E6),
                                                ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                        ),
                                      ),

                                      // Page info
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FA),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Page $currentPage of ${_getTotalPages()} (${_users.length} total)',
                                          style: const TextStyle(
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
                            ],
                          ),
                  ),
                ),
              ],
            ),

            // Create User Dialog
            ...(_showCreateUserDialog ? [_buildCreateUserDialog()] : []),

            // Edit User Dialog
            ...(_showEditUserDialog ? [_buildEditUserDialog()] : []),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    final totalPages = _getTotalPages();
    final current = currentPage;

    // Show max 5 page buttons centered around current page
    const maxButtons = 5;
    final halfRange = maxButtons ~/ 2;

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

  Widget _buildCreateUserDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.6,
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1845),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Create New User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _closeDialogs,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Dialog Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      const Text(
                        'Username *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email
                      const Text(
                        'Email *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter email address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Password
                      const Text(
                        'Password *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Picture URL
                      const Text(
                        'Picture URL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pictureController,
                        decoration: InputDecoration(
                          labelText: 'Picture URL',
                          hintText: 'Enter picture URL (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.image),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitCreateUser,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isSubmitting ? 'Creating...' : 'Create User',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D1845),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: _closeDialogs,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Cancel'),
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
      ),
    );
  }

  Widget _buildEditUserDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.6,
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1845),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Edit User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _closeDialogs,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Dialog Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      const Text(
                        'Username *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Email
                      const Text(
                        'Email *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter email address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Password
                      const Text(
                        'Password *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Picture URL
                      const Text(
                        'Picture URL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pictureController,
                        decoration: InputDecoration(
                          labelText: 'Picture URL',
                          hintText: 'Enter picture URL (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.image),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitEditUser,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isSubmitting ? 'Updating...' : 'Update User',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D1845),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: _closeDialogs,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Cancel'),
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
      ),
    );
  }
}
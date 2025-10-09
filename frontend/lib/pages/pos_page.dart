import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../widgets/pos_navbar.dart';
import '../widgets/pos_order_list.dart';
import '../widgets/pos_payment_methods.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sub_category.dart';
import '../services/inventory_service.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> with AutomaticKeepAliveClientMixin {
  String selectedCategory = 'all';
  String searchQuery = '';
  List<Map<String, dynamic>> orderItems = [];
  Map<String, dynamic>? selectedCustomer;
  double currentTotal = 0.0;

  // Data from inventory pages
  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  List<Product> products = [];
  bool isLoadingCategories = false;
  bool isLoadingSubCategories = false;
  bool isLoadingProducts = false;

  // Performance optimizations - optimized for better performance
  List<Product> _filteredProducts = [];
  Timer? _searchDebounceTimer;
  final Map<String, ImageProvider> _imageCache = {};
  static const int _maxCacheSize =
      3; // Reduced cache size for memory optimization

  // Pagination for products - reduced for better performance
  static const int _productsPerPage = 15; // Reduced for better performance
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  final ScrollController _productsScrollController = ScrollController();

  // Sequential loading states
  bool _isInitializing = true;
  String _loadingMessage = 'Loading products...';

  @override
  void initState() {
    super.initState();
    _productsScrollController.addListener(_onProductsScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize window for fullscreen
      final windowProvider = Provider.of<WindowProvider>(
        context,
        listen: false,
      );
      await windowProvider.initWindow();
      await windowProvider.toggleFullScreen();

      // Fetch data sequentially for better performance
      await _initializeDataSequentially();
    });
  }

  Future<void> _initializeDataSequentially() async {
    try {
      // Step 1: Load products first (most important for POS)
      setState(() {
        _loadingMessage = 'Loading products...';
      });
      await _fetchProducts();

      // Step 2: Load categories
      setState(() {
        _loadingMessage = 'Loading categories...';
      });
      await _fetchCategories();

      // Step 3: Load subcategories
      setState(() {
        _loadingMessage = 'Loading subcategories...';
      });
      await _fetchSubCategories();

      // Mark initialization complete
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Error during sequential initialization: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _productsScrollController.dispose();
    _clearImageCache();
    final windowProvider = Provider.of<WindowProvider>(context, listen: false);
    windowProvider.exitFullScreen();
    super.dispose();
  }

  void _clearImageCache() {
    _imageCache.clear();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });

    try {
      final response = await InventoryService.getCategories(limit: 1000);
      setState(() {
        categories = response.data;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchSubCategories() async {
    setState(() {
      isLoadingSubCategories = true;
    });

    try {
      final response = await InventoryService.getSubCategories(limit: 1000);
      setState(() {
        subCategories = response.data;
        isLoadingSubCategories = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSubCategories = false;
      });
      print('Error fetching subcategories: $e');
    }
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMoreProducts)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        isLoadingProducts = true;
        _currentPage = 0;
        _hasMoreProducts = true;
      }
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final response = await InventoryService.getProducts(
        limit: _productsPerPage,
        page: page,
      );

      setState(() {
        if (loadMore) {
          products.addAll(response.data);
          _currentPage = page;
          _hasMoreProducts = response.data.length == _productsPerPage;
          _isLoadingMore = false;
        } else {
          products = response.data;
          _currentPage = 1;
          _hasMoreProducts = response.data.length == _productsPerPage;
          _updateFilteredProducts();
          isLoadingProducts = false;
        }
      });
    } catch (e) {
      setState(() {
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          isLoadingProducts = false;
        }
      });
      print('Error fetching products: $e');
    }
  }

  void _onProductsScroll() {
    if (_productsScrollController.position.pixels >=
        _productsScrollController.position.maxScrollExtent - 200) {
      _fetchProducts(loadMore: true);
    }
  }

  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
    _resetAndFilterProducts();
  }

  void _resetAndFilterProducts() {
    // Reset pagination when filters change
    _currentPage = 0;
    _hasMoreProducts = true;
    _updateFilteredProducts();

    // If we don't have enough products for current filters, load more
    if (_filteredProducts.length < _productsPerPage && _hasMoreProducts) {
      _fetchProducts(loadMore: true);
    }
  }

  void _updateFilteredProducts() {
    setState(() {
      _filteredProducts = _getFilteredProducts();
    });
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });

    // Debounce search to avoid excessive filtering - optimized delay for better performance
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      // Reduced from 300ms for better responsiveness
      _updateFilteredProducts();
    });
  }

  void addToOrder(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = orderItems.indexWhere(
        (item) => item['id'] == product['id'],
      );
      if (existingIndex >= 0) {
        orderItems[existingIndex]['quantity'] =
            (orderItems[existingIndex]['quantity'] ?? 1) + 1;
      } else {
        orderItems.add({...product, 'quantity': 1});
      }
    });
  }

  void updateOrderItemQuantity(String itemId, int quantity) {
    setState(() {
      final index = orderItems.indexWhere((item) => item['id'] == itemId);
      if (index >= 0) {
        if (quantity <= 0) {
          orderItems.removeAt(index);
        } else {
          orderItems[index]['quantity'] = quantity;
        }
      }
    });
  }

  void removeOrderItem(String itemId) {
    setState(() {
      orderItems.removeWhere((item) => item['id'] == itemId);
    });
  }

  void selectCustomer(String customerName) {
    setState(() {
      selectedCustomer = {'name': customerName};
    });
  }

  void onPaymentComplete(String method, double amount) {
    // TODO: Handle payment completion
    // Clear order after successful payment
    setState(() {
      orderItems.clear();
      selectedCustomer = null;
    });
  }

  double getSubtotal() {
    return orderItems.fold(
      0.0,
      (sum, item) => sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Show loading screen during initialization
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1845),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                _loadingMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1845),
      body: Column(
        children: [
          // Custom POS Navbar
          const PosNavbar(),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Left Side - Categories Only
                Container(
                  width: 220,
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Categories Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D1845),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.category,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Categories',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Categories List
                      Expanded(
                        child: isLoadingCategories
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0D1845),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                physics:
                                    const BouncingScrollPhysics(), // Changed for smoother scrolling
                                itemCount:
                                    categories.length +
                                    1, // +1 for "All" category
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    // "All" category
                                    return _buildCategoryItem(
                                      'all',
                                      'All',
                                      Icons.grid_view,
                                      selectedCategory == 'all',
                                    );
                                  } else {
                                    final category = categories[index - 1];
                                    return _buildCategoryItem(
                                      category.id.toString(),
                                      category.title,
                                      _getCategoryIcon(category.title),
                                      selectedCategory ==
                                          category.id.toString(),
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // Center - Products Grid with Subcategories at Bottom
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Products Header with Search
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Message and Date
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final user = authProvider.user;
                                  final userName = user?.fullName ?? 'User';
                                  final currentDate = DateFormat(
                                    'EEEE, MMMM d, yyyy',
                                  ).format(DateTime.now());

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Welcome, $userName',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D1845),
                                        ),
                                      ),
                                      Text(
                                        currentDate,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Search Bar
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: onSearchChanged,
                                      decoration: InputDecoration(
                                        hintText: 'Search products...',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Products Grid - optimized for performance
                        Expanded(
                          child: isLoadingProducts
                              ? const Center(child: CircularProgressIndicator())
                              : GridView.builder(
                                  controller: _productsScrollController,
                                  padding: const EdgeInsets.all(16),
                                  physics:
                                      const BouncingScrollPhysics(), // Changed to bouncing for smoother scrolling
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            4, // Increased back to 4 for better space utilization
                                        crossAxisSpacing: 8, // Reduced spacing
                                        mainAxisSpacing: 8, // Reduced spacing
                                        childAspectRatio:
                                            0.75, // Optimized aspect ratio
                                      ),
                                  itemCount:
                                      _filteredProducts.length +
                                      (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _filteredProducts.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    final product = _filteredProducts[index];
                                    return _buildProductCard(product);
                                  },
                                ),
                        ),

                        // Subcategories Section at Bottom
                        Container(
                          height: 95, // Slightly more bigger
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(
                              top: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Subcategories Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8, // More padding
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.subdirectory_arrow_right,
                                      color: Colors.grey[600],
                                      size: 14, // Bigger icon
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Subcategories',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13, // Bigger font
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Subcategories Horizontal List
                              Expanded(
                                child: isLoadingSubCategories
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : _buildSubCategoriesList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Side - Order Details (No Footer)
                Container(
                  width: 350,
                  color: const Color(0xFFF8F9FA),
                  child: Column(
                    children: [
                      // Order Details (Scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          physics:
                              const BouncingScrollPhysics(), // Changed for smoother scrolling
                          child: Column(
                            children: [
                              // Order List
                              PosOrderList(
                                orderItems: orderItems,
                                onUpdateQuantity: updateOrderItemQuantity,
                                onRemoveItem: removeOrderItem,
                                onSelectCustomer: selectCustomer,
                                onTotalChanged: (total) {
                                  setState(() {
                                    currentTotal = total;
                                  });
                                },
                              ),

                              // Payment Methods
                              PosPaymentMethods(
                                totalAmount: currentTotal,
                                onPaymentComplete: onPaymentComplete,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesList() {
    // Filter subcategories based on selected category
    List<SubCategory> filteredSubCategories;
    if (selectedCategory == 'all') {
      // When "All" is selected, show all unique subcategories
      filteredSubCategories = subCategories
          .toSet()
          .toList(); // Remove duplicates
    } else {
      // When a specific category is selected, show only its subcategories
      filteredSubCategories = subCategories
          .where((sub) => sub.categoryId.toString() == selectedCategory)
          .toSet() // Remove duplicates
          .toList();
    }

    if (filteredSubCategories.isEmpty) {
      return const Center(
        child: Text(
          'No subcategories',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10, // Smaller font for empty state
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 30,
      ), // Much smaller constraint
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics:
            const BouncingScrollPhysics(), // Changed for smoother scrolling
        child: Row(
          children: filteredSubCategories.map((subCategory) {
            return _buildSubCategoryItem(subCategory);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubCategoryItem(SubCategory subCategory) {
    final isSelected = selectedCategory == subCategory.id.toString();

    return Container(
      width: 90, // Reduced width
      margin: const EdgeInsets.only(right: 6), // Reduced margin
      child: Material(
        elevation: isSelected ? 2 : 0,
        borderRadius: BorderRadius.circular(6), // Smaller border radius
        child: InkWell(
          onTap: () => onCategorySelected(subCategory.id.toString()),
          borderRadius: BorderRadius.circular(6),
          splashColor: const Color(0xFF0D1845).withOpacity(0.1),
          highlightColor: const Color(0xFF0D1845).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 8,
            ), // Reduced padding
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0D1845) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? const Color(0xFF0D1845) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.subdirectory_arrow_right,
                  size: 12, // Smaller icon
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(height: 2), // Reduced spacing
                Text(
                  subCategory.title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 9, // Smaller font
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    String categoryId,
    String title,
    IconData icon,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Material(
        elevation: isSelected ? 4 : 1,
        borderRadius: BorderRadius.circular(12),
        shadowColor: isSelected
            ? const Color(0xFF0D1845).withOpacity(0.3)
            : Colors.grey.withOpacity(0.2),
        child: InkWell(
          onTap: () => onCategorySelected(categoryId),
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF0D1845).withOpacity(0.1),
          highlightColor: const Color(0xFF0D1845).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0D1845) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF0D1845) : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF0D1845),
                        const Color(0xFF1A237E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFF0D1845),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Pre-compute values to avoid repeated calculations
    final price = double.tryParse(product.salePrice) ?? 0.0;
    final stock = int.tryParse(product.openingStockQuantity) ?? 0;
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;

    return RepaintBoundary(
      // Add RepaintBoundary to prevent unnecessary repaints
      child: Card(
        elevation: 1, // Reduced elevation for better performance
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: InkWell(
          onTap: () => addToOrder({
            'id': product.id,
            'name': product.title,
            'price': product.salePrice,
            'image': product.imagePath ?? '',
          }),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with caching
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: hasImage
                        ? _buildCachedImage(product.imagePath!)
                        : const Icon(
                            Icons.inventory_2,
                            size: 32,
                            color: Color(0xFFB0B0B0),
                          ),
                  ),
                ),

                const SizedBox(height: 6),

                // Product Name
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1845),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Product Price
                Text(
                  'Rs${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                // Stock Info
                Text(
                  'Stock: $stock',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCachedImage(String imageUrl) {
    // Use cached image if available
    if (_imageCache.containsKey(imageUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image(
          image: _imageCache[imageUrl]!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.inventory_2, size: 32, color: Colors.grey[400]);
          },
        ),
      );
    }

    // Load and cache the image with optimized settings for memory
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 100, // Reduced cache size for memory optimization
        cacheHeight: 100,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Cache the loaded image efficiently
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_imageCache.containsKey(imageUrl)) {
                // Implement LRU cache eviction more efficiently
                if (_imageCache.length >= _maxCacheSize) {
                  // Remove oldest entries (simple FIFO for better performance)
                  final keysToRemove = _imageCache.keys.take(1).toList();
                  for (final key in keysToRemove) {
                    _imageCache.remove(key);
                  }
                }
                _imageCache[imageUrl] = NetworkImage(imageUrl);
              }
            });
            return child;
          }
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.inventory_2, size: 32, color: Colors.grey[400]);
        },
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    // Map common category names to appropriate icons
    if (name.contains('food') ||
        name.contains('meal') ||
        name.contains('restaurant')) {
      return Icons.restaurant;
    } else if (name.contains('drink') ||
        name.contains('beverage') ||
        name.contains('coffee') ||
        name.contains('tea')) {
      return Icons.local_drink;
    } else if (name.contains('snack') ||
        name.contains('chips') ||
        name.contains('candy')) {
      return Icons.cookie;
    } else if (name.contains('fruit') ||
        name.contains('vegetable') ||
        name.contains('organic')) {
      return Icons.eco;
    } else if (name.contains('bakery') ||
        name.contains('bread') ||
        name.contains('cake')) {
      return Icons.cake;
    } else if (name.contains('dairy') ||
        name.contains('milk') ||
        name.contains('cheese')) {
      return Icons.egg;
    } else if (name.contains('meat') ||
        name.contains('chicken') ||
        name.contains('beef')) {
      return Icons.restaurant_menu;
    } else if (name.contains('frozen') || name.contains('ice cream')) {
      return Icons.ac_unit;
    } else if (name.contains('cleaning') || name.contains('household')) {
      return Icons.cleaning_services;
    } else if (name.contains('personal') ||
        name.contains('care') ||
        name.contains('beauty')) {
      return Icons.spa;
    } else if (name.contains('electronics') || name.contains('gadget')) {
      return Icons.devices;
    } else if (name.contains('clothing') ||
        name.contains('fashion') ||
        name.contains('wear')) {
      return Icons.checkroom;
    } else if (name.contains('book') || name.contains('stationery')) {
      return Icons.menu_book;
    } else if (name.contains('toy') || name.contains('game')) {
      return Icons.toys;
    } else if (name.contains('sport') || name.contains('fitness')) {
      return Icons.sports;
    } else {
      // Default icon for unknown categories
      return Icons.category;
    }
  }

  List<Product> _getFilteredProducts() {
    // Use efficient filtering with early returns and optimized logic
    if (selectedCategory == 'all' && searchQuery.isEmpty) {
      return products;
    }

    // Pre-process search query for better performance
    final query = searchQuery.toLowerCase().trim();
    final hasSearchQuery = query.isNotEmpty;
    final categoryFilter = selectedCategory;

    // Use more efficient filtering with less allocations and early returns
    return products
        .where((product) {
          // Category filter - check first as it's faster
          if (categoryFilter != 'all' &&
              product.subCategoryId != categoryFilter) {
            return false;
          }

          // Search filter - only if there's a query
          if (hasSearchQuery) {
            final title = product.title.toLowerCase();
            final designCode = product.designCode.toLowerCase();

            // Use contains for better performance than regex
            return title.contains(query) || designCode.contains(query);
          }

          return true;
        })
        .toList(
          growable: false,
        ); // Use non-growable list for better performance
  }
}

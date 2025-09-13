import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pos_frontend/models/product_model.dart';
import 'package:pos_frontend/widgets/header_widget.dart';
import 'package:pos_frontend/widgets/search_filter_widget.dart';
import 'package:pos_frontend/widgets/table_header_product_widget.dart';
import 'package:pos_frontend/widgets/data_table_product_widget.dart';
import 'package:pos_frontend/widgets/pagination_widget.dart';
import 'package:pos_frontend/utils/product_utils.dart';
import 'package:pos_frontend/widgets/add_product_dialog.dart';
import 'package:pos_frontend/widgets/edit_product_dialog.dart';
import 'package:pos_frontend/widgets/delete_product_dialog.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  ProductsPageState createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  // List of products (dummy data)
  final List<ProductModel> products = List.generate(
    25,
    (index) => ProductModel(
      imageProduct: 'assets/images/img01.jpg',
      nameProduct: 'Product ${index + 1}',
      category: 'Category ${index % 6 + 1}',
      vendor: 'Vendor ${index % 4 + 1}',
      price: (index + 1) * 10.5,
      quantity: (index + 1) * 5,
      imageUser: 'assets/images/user${(index % 3) + 1}.jpg',
      createdBy: 'User ${index % 5 + 1}',
      status: index % 3 == 0 ? 'Inactive' : 'Active',
    ),
  );

  // State variables
  late List<bool> selectedProducts;
  int rowsPerPage = 10;
  int currentPage = 1;
  String? selectedStatus;
  String sortColumn = 'category';
  bool sortAscending = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    selectedProducts = List.filled(products.length, false);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounces search input to reduce unnecessary rebuilds
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        selectedProducts = List.filled(filteredProducts.length, false);
        currentPage = 1;
      });
    });
  }

  /// Sorts products based on the selected column
  void _sortProducts(String column) {
    setState(() {
      sortColumn = column;
      sortAscending = sortColumn == column ? !sortAscending : true;
      currentPage = 1;
      selectedProducts = List.filled(filteredProducts.length, false);
    });
  }

  /// Filters products based on search query and status
  List<ProductModel> get filteredProducts {
    final query = _searchController.text.toLowerCase();
    final filtered = products.where((item) {
      final matchesStatus = selectedStatus == null ||
          selectedStatus == 'All' ||
          item.status == selectedStatus;
      final matchesSearch = query.isEmpty ||
          item.nameProduct.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.vendor.toLowerCase().contains(query) ||
          item.createdBy.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case 'nameProduct':
          cmp = a.nameProduct.compareTo(b.nameProduct);
          break;
        case 'category':
          cmp = a.category.compareTo(b.category);
          break;
        case 'vendor':
          cmp = a.vendor.compareTo(b.vendor);
          break;
        case 'price':
          cmp = a.price.compareTo(b.price);
          break;
        case 'quantity':
          cmp = a.quantity.compareTo(b.quantity);
          break;
        case 'createdBy':
          cmp = a.createdBy.compareTo(b.createdBy);
          break;
        case 'status':
          cmp = a.status.compareTo(b.status);
          break;
        default:
          cmp = a.category.compareTo(b.category);
      }
      return sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  /// Calculates total pages for pagination
  int get totalPages => filteredProducts.isEmpty
      ? 1
      : (filteredProducts.length / rowsPerPage).ceil();

  /// Calculates start index for current page
  int get startIndex => (currentPage - 1) * rowsPerPage;

  /// Calculates end index for current page
  int get endIndex => math.min(startIndex + rowsPerPage, filteredProducts.length);

  /// Generates a PDF report
  Future<void> _generatePDF(BuildContext context, {required bool onlySelected}) async {
    await generatePDF(
      context,
      onlySelected: onlySelected,
      filteredProducts: filteredProducts,
      selectedProducts: selectedProducts,
      setLastGeneratedPdfPath: (_) {},
    );
  }

  /// Generates an Excel report
  Future<void> _generateExcel(BuildContext context, {required bool onlySelected}) async {
    await generateExcel(
      context,
      onlySelected: onlySelected,
      filteredProducts: filteredProducts,
      selectedProducts: selectedProducts,
      setLastGeneratedExcelPath: (_) {},
    );
  }

  /// Shows dialog to choose PDF export options
  Future<void> _showPDFExportDialog(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export PDF'),
        content: const Text('Do you want to export all current records or only selected records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'selected'),
            child: const Text('Selected Records'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text('All Records'),
          ),
        ],
      ),
    );

    if (choice == 'all') {
      await _generatePDF(context, onlySelected: false);
    } else if (choice == 'selected') {
      await _generatePDF(context, onlySelected: true);
    }
  }

  /// Shows dialog to choose Excel export options
  Future<void> _showExcelExportDialog(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Excel'),
        content: const Text('Do you want to export all current records or only selected records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'selected'),
            child: const Text('Selected Records'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text('All Records'),
          ),
        ],
      ),
    );

    if (choice == 'all') {
      await _generateExcel(context, onlySelected: false);
    } else if (choice == 'selected') {
      await _generateExcel(context, onlySelected: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync selectedProducts with filtered list
    if (selectedProducts.length != filteredProducts.length) {
      selectedProducts = List.filled(filteredProducts.length, false);
    }

    final pageItems = filteredProducts.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  HeaderWidget(
                    title: 'Product Attributes',
                    subtitle: 'Manage your Products here',
                    onGeneratePDF: () => _showPDFExportDialog(context),
                    onGenerateExcel: () => _showExcelExportDialog(context),
                    onAddItem: () => showAddProductDialog(
                      context,
                      products: products,
                      setStateCallback: setState,
                      totalPages: totalPages,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SearchFilterWidget(
                    searchController: _searchController,
                    selectedStatus: selectedStatus,
                    onStatusChanged: (value) => setState(() {
                      selectedStatus = value;
                      currentPage = 1;
                      selectedProducts = List.filled(filteredProducts.length, false);
                    }),
                  ),
                  const SizedBox(height: 12),
                  TableHeaderWidget(
                    sortColumn: sortColumn,
                    sortAscending: sortAscending,
                    onSort: _sortProducts,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: DataTableWidget<ProductModel>(
                      filteredItems: pageItems,
                      selectedItems: selectedProducts.sublist(startIndex, endIndex),
                      searchQuery: _searchController.text,
                      fieldAccessors: [
                        (product) => product.imageProduct,
                        (product) => product.nameProduct,
                        (product) => product.category,
                        (product) => product.vendor,
                        (product) => product.price,
                        (product) => product.quantity,
                        (product) => product.imageUser,
                        (product) => product.createdBy,
                        (product) => product.status,
                      ],
                      onCheckboxChanged: (index, value) {
                        setState(() => selectedProducts[startIndex + index] = value);
                      },
                      onStatusToggled: (index) {
                        setState(() {
                          final model = filteredProducts[startIndex + index];
                          final actualIndex = products.indexOf(model);
                          if (actualIndex != -1) {
                            products[actualIndex] = ProductModel(
                              imageProduct: model.imageProduct,
                              nameProduct: model.nameProduct,
                              category: model.category,
                              vendor: model.vendor,
                              price: model.price,
                              quantity: model.quantity,
                              imageUser: model.imageUser,
                              createdBy: model.createdBy,
                              status: model.status == 'Active' ? 'Inactive' : 'Active',
                            );
                          }
                        });
                      },
                      onEdit: (index) => showEditProductDialog(
                        context,
                        filteredProducts: filteredProducts,
                        index: startIndex + index,
                        products: products,
                        setStateCallback: setState,
                      ),
                      onDelete: (index) => showDeleteProductDialog(
                        context,
                        filteredProducts: filteredProducts,
                        index: startIndex + index,
                        products: products,
                        setStateCallback: setState,
                        totalPages: totalPages,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PaginationWidget(
                    rowsPerPage: rowsPerPage,
                    currentPage: currentPage,
                    totalPages: totalPages,
                    onRowsPerPageChanged: (value) => setState(() {
                      rowsPerPage = value;
                      currentPage = 1;
                      selectedProducts = List.filled(filteredProducts.length, false);
                    }),
                    onPageChanged: (page) => setState(() => currentPage = page),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
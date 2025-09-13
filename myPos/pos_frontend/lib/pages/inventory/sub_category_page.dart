// ignore_for_file: use_build_context_synchronously, unused_field

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pos_frontend/models/sub_category_model.dart';
import 'package:pos_frontend/widgets/header_widget.dart';
import 'package:pos_frontend/widgets/search_filter_widget.dart';
import 'package:pos_frontend/widgets/table_header_subcat_widget.dart';
import 'package:pos_frontend/widgets/data_table_subcat_widget.dart';
import 'package:pos_frontend/widgets/pagination_widget.dart';
import 'package:pos_frontend/utils/sub_category_utils.dart';
import 'package:pos_frontend/widgets/add_sub_category_dialog.dart'; // New import
import 'package:pos_frontend/widgets/edit_sub_category_dialog.dart'; // New import
import 'package:pos_frontend/widgets/delete_confirmation_dialog.dart'; // New import

class SubCategoryPage extends StatefulWidget {
  const SubCategoryPage({super.key});

  @override
  SubCategoryPageState createState() => SubCategoryPageState();
}

class SubCategoryPageState extends State<SubCategoryPage> {
  // Dummy data for testing purposes
  final List<SubCategoryModel> subCategories = List.generate(
    25,
    (index) => SubCategoryModel(
      image: 'assets/images/img01.jpg',
      subCategory: 'SubCategory ${index + 1}',
      category: 'Category ${index % 6 + 1}',
      description: 'Description for SubCategory ${index + 1}',
      createdDate: '2025-${(index % 12 + 1).toString().padLeft(2, '0')}-01',
      status: index % 3 == 0 ? 'Inactive' : 'Active',
    ),
  );

  // State variables
  late List<bool> selectedCategories;
  int rowsPerPage = 10;
  int currentPage = 1;
  String? selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String sortColumn = 'category';
  bool sortAscending = true;
  String? _lastGeneratedPdfPath;
  String? _lastGeneratedExcelPath;

  @override
  void initState() {
    super.initState();
    selectedCategories = List.filled(subCategories.length, false);
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
      setState(() {
        selectedCategories = List.filled(filteredSubCategories.length, false);
        currentPage = 1;
      });
    });
  }

  /// Sorts categories based on the selected column
  void _sortCategories(String column) {
    setState(() {
      sortColumn = column;
      sortAscending = sortColumn == column ? !sortAscending : true;
      currentPage = 1;
      selectedCategories = List.filled(filteredSubCategories.length, false);
    });
  }

  /// Filters subcategories based on search query and status
  List<SubCategoryModel> get filteredSubCategories {
    final query = _searchController.text.toLowerCase();
    final filtered = subCategories.where((item) {
      final matchesStatus = selectedStatus == null ||
          selectedStatus == 'All' ||
          item.status == selectedStatus;
      final matchesSearch = query.isEmpty ||
          item.subCategory.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case 'subCategory':
          cmp = a.subCategory.compareTo(b.subCategory);
          break;
        case 'category':
          cmp = a.category.compareTo(b.category);
          break;
        case 'createdDate':
          cmp = a.createdDate.compareTo(b.createdDate);
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
  int get totalPages => filteredSubCategories.isEmpty
      ? 1
      : (filteredSubCategories.length / rowsPerPage).ceil();

  /// Calculates start index for current page
  int get startIndex => (currentPage - 1) * rowsPerPage;

  /// Calculates end index for current page
  int get endIndex => math.min(startIndex + rowsPerPage, filteredSubCategories.length);

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSubCategoryDialog(
        onSave: (newModel) => setState(() {
          subCategories.add(newModel);
          selectedCategories = List.filled(filteredSubCategories.length, false);
        }),
      ),
    );
  }

  void _showEditDialog(int listIndexInFiltered) {
    final model = filteredSubCategories[listIndexInFiltered];
    showDialog(
      context: context,
      builder: (context) => EditSubCategoryDialog(
        model: model,
        onUpdate: (updatedModel) => setState(() {
          final actualIndex = subCategories.indexOf(model);
          if (actualIndex != -1) {
            subCategories[actualIndex] = updatedModel;
          }
          selectedCategories = List.filled(filteredSubCategories.length, false);
        }),
      ),
    );
  }

  void _showDeleteDialog(int listIndexInFiltered) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        onDelete: () => setState(() {
          final model = filteredSubCategories[listIndexInFiltered];
          final actualIndex = subCategories.indexOf(model);
          if (actualIndex != -1) {
            subCategories.removeAt(actualIndex);
          }
          selectedCategories = List.filled(filteredSubCategories.length, false);
          if (filteredSubCategories.isEmpty) {
            currentPage = 1;
          } else if (startIndex >= filteredSubCategories.length) {
            currentPage = totalPages;
          }
        }),
      ),
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
      await generatePDF(
        context,
        onlySelected: false,
        filteredCategories: filteredSubCategories,
        selectedCategories: selectedCategories,
        setLastGeneratedPdfPath: (path) => setState(() => _lastGeneratedPdfPath = path),
      );
    } else if (choice == 'selected') {
      await generatePDF(
        context,
        onlySelected: true,
        filteredCategories: filteredSubCategories,
        selectedCategories: selectedCategories,
        setLastGeneratedPdfPath: (path) => setState(() => _lastGeneratedPdfPath = path),
      );
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
      await generateExcel(
        context,
        onlySelected: false,
        filteredCategories: filteredSubCategories,
        selectedCategories: selectedCategories,
        setLastGeneratedExcelPath: (path) => setState(() => _lastGeneratedExcelPath = path),
      );
    } else if (choice == 'selected') {
      await generateExcel(
        context,
        onlySelected: true,
        filteredCategories: filteredSubCategories,
        selectedCategories: selectedCategories,
        setLastGeneratedExcelPath: (path) => setState(() => _lastGeneratedExcelPath = path),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync selectedCategories with filtered list
    if (selectedCategories.length != filteredSubCategories.length) {
      selectedCategories = List.filled(filteredSubCategories.length, false);
    }

    final pageItems = filteredSubCategories.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            HeaderWidget(
              title: 'Sub Category Attributes',
              subtitle: 'Manage your Sub Category here',
              onGeneratePDF: () => _showPDFExportDialog(context),
              onGenerateExcel: () => _showExcelExportDialog(context),
              onAddItem: _showAddDialog,
            ),
            const SizedBox(height: 12),
            SearchFilterWidget(
              searchController: _searchController,
              selectedStatus: selectedStatus,
              onStatusChanged: (value) => setState(() {
                selectedStatus = value;
                currentPage = 1;
                selectedCategories = List.filled(filteredSubCategories.length, false);
              }),
            ),
            const SizedBox(height: 12),
            TableHeaderWidget(
              sortColumn: sortColumn,
              sortAscending: sortAscending,
              onSort: _sortCategories,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DataTableSubcatWidget<SubCategoryModel>(
                items: pageItems,
                selected: selectedCategories.sublist(startIndex, endIndex),
                searchQuery: _searchController.text,
                fieldAccessors: [
                  (sub) => sub.image,
                  (sub) => sub.subCategory,
                  (sub) => sub.category,
                  (sub) => sub.description,
                  (sub) => sub.createdDate,
                  (sub) => sub.status,
                ],
                onCheckboxChanged: (index, value) {
                  setState(() => selectedCategories[startIndex + index] = value);
                },
                onStatusToggled: (index) {
                  setState(() {
                    final model = filteredSubCategories[startIndex + index];
                    final actualIndex = subCategories.indexOf(model);
                    if (actualIndex != -1) {
                      subCategories[actualIndex] = SubCategoryModel(
                        image: model.image,
                        subCategory: model.subCategory,
                        category: model.category,
                        description: model.description,
                        createdDate: model.createdDate,
                        status: model.status == 'Active' ? 'Inactive' : 'Active',
                      );
                    }
                  });
                },
                onEdit: (index) => _showEditDialog(startIndex + index),
                onDelete: (index) => _showDeleteDialog(startIndex + index),
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
                selectedCategories = List.filled(filteredSubCategories.length, false);
              }),
              onPageChanged: (page) => setState(() => currentPage = page),
            ),
          ],
        ),
      ),
    );
  }
}
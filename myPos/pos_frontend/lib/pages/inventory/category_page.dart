import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io' show File;
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart' show Excel, TextCellValue;
import 'package:pos_frontend/models/category_model.dart';
import 'package:pos_frontend/widgets/header_widget.dart';
import 'package:pos_frontend/widgets/search_filter_widget.dart';
import 'package:pos_frontend/widgets/table_header_widget.dart';
import 'package:pos_frontend/widgets/data_table_widget.dart';
import 'package:pos_frontend/widgets/pagination_widget.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  CategoryPageState createState() => CategoryPageState();
}

class CategoryPageState extends State<CategoryPage> {
  // Dummy data
  final List<CategoryModel> categories = List.generate(
    25,
    (index) => CategoryModel(
      name: "Category ${index + 1}",
      category: "Category ${index + 1}",
      createdDate: "2025-${(index % 12 + 1).toString().padLeft(2, '0')}-01",
      status: index % 3 == 0 ? "Inactive" : "Active",
    ),
  );

  // State variables
  late List<bool> selectedCategories;
  int rowsPerPage = 10;
  int currentPage = 1;
  String? selectedStatus;

  // ignore: unused_field
  String? _lastGeneratedPdfPath;
 
  // ignore: unused_field
  String? _lastGeneratedExcelPath;
  
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String sortColumn = 'categoryName';
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    selectedCategories = List.filled(categories.length, false);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        selectedCategories = List.filled(filteredCategories.length, false);
        currentPage = 1;
      });
    });
  }

  void _sortCategories(String column) {
    setState(() {
      if (sortColumn == column) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = column;
        sortAscending = true;
      }
      currentPage = 1;
      selectedCategories = List.filled(filteredCategories.length, false);
    });
  }

  List<CategoryModel> get filteredCategories {
    final query = _searchController.text.toLowerCase();
    final filtered = categories.where((category) {
      final matchesStatus =
          selectedStatus == null || category.status == selectedStatus;
      final matchesSearch =
          query.isEmpty || category.category.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (sortColumn) {
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

  int get totalPages =>
      filteredCategories.isEmpty ? 1 : (filteredCategories.length / rowsPerPage).ceil();
  int get startIndex => (currentPage - 1) * rowsPerPage;
  int get endIndex =>
      (startIndex + rowsPerPage).clamp(0, filteredCategories.length);

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Category Name"),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty || categoryController.text.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill in all fields")),
                );
                return;
              }

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Add"),
                  content: const Text("Are you sure you want to add this category?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                if (!mounted) return;
                setState(() {
                  categories.add(CategoryModel(
                    name: nameController.text,
                    category: categoryController.text,
                    createdDate:
                        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
                    status: "Active",
                  ));
                  selectedCategories = List.filled(filteredCategories.length, false);
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    final nameController = TextEditingController(text: categories[index].category);
    final categoryController = TextEditingController(
      text: categories[index].category,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Category Name"),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Edit"),
                  content: const Text(
                    "Are you sure you want to save changes to this category?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                if (!mounted) return;
                setState(() {
                  categories[index].category = nameController.text;
                  selectedCategories = List.filled(filteredCategories.length, false);
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this category?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() {
        categories.removeAt(index);
        selectedCategories = List.filled(filteredCategories.length, false);
        if (filteredCategories.isEmpty) {
          currentPage = 1;
        } else if (startIndex >= filteredCategories.length) {
          currentPage = totalPages;
        }
      });
    }
  }

  Future<void> _generatePDF(
    BuildContext context, {
    required bool onlySelected,
  }) async {
    final pdf = pw.Document();
    final headers = ['Name', 'Category', 'Created Date', 'Status'];
    final pdfCategories = onlySelected
        ? filteredCategories
            .asMap()
            .entries
            .where((e) => selectedCategories[e.key])
            .map((e) => e.value)
            .toList()
        : filteredCategories;

    if (pdfCategories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onlySelected ? "No records selected" : "No records available",
          ),
        ),
      );
      return;
    }

    final data = pdfCategories
        .map(
          (category) => [
            category.category,
            category.createdDate,
            category.status,
          ],
        )
        .toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          border: pw.TableBorder.all(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(4),
        ),
      ),
    );

    final bytes = await pdf.save();
    String filePath;
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      filePath = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = filePath
        ..download = 'categories_${DateTime.now().millisecondsSinceEpoch}.pdf';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(filePath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      filePath =
          "${output.path}/categories_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await OpenFile.open(filePath);
    }
    if (!mounted) return;
    setState(() => _lastGeneratedPdfPath = filePath);
  }

  Future<void> _generateExcel(
    BuildContext context, {
    required bool onlySelected,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    final headers = <TextCellValue>[
      TextCellValue('Name'),
      TextCellValue('Category'),
      TextCellValue('Created Date'),
      TextCellValue('Status'),
    ];
    sheet.appendRow(headers);

    // Add data
    final excelCategories = onlySelected
        ? filteredCategories
            .asMap()
            .entries
            .where((e) => selectedCategories[e.key])
            .map((e) => e.value)
            .toList()
        : filteredCategories;

    if (excelCategories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onlySelected ? "No records selected" : "No records available",
          ),
        ),
      );
      return;
    }

    for (var category in excelCategories) {
      sheet.appendRow(<TextCellValue>[
        TextCellValue(category.category),
        TextCellValue(category.createdDate),
        TextCellValue(category.status),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate Excel file")),
      );
      return;
    }

    String filePath;
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      filePath = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = filePath
        ..download = 'categories_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(filePath);
    } else {
      final output = await getApplicationDocumentsDirectory();
      filePath =
          "${output.path}/categories_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await OpenFile.open(filePath);
    }
    if (!mounted) return;
    setState(() => _lastGeneratedExcelPath = filePath);
  }

  Future<void> _showPDFExportDialog(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Export PDF"),
        content: const Text(
          "Do you want to export all current records or only selected records?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'selected'),
            child: const Text("Selected Records"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text("All Records"),
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

  Future<void> _showExcelExportDialog(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Excel'),
        content: const Text(
          'Do you want to export all current records or only selected records?',
        ),
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
    if (selectedCategories.length != filteredCategories.length) {
      selectedCategories = List.filled(filteredCategories.length, false);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            HeaderWidget(
              title: "Category Attributes",
              subtitle: "Manage your Category here",
              onGeneratePDF: () => _showPDFExportDialog(context),
              onGenerateExcel: () => _showExcelExportDialog(context),
              onAddItem: _showAddCategoryDialog,
            ),
            const SizedBox(height: 12),
            SearchFilterWidget(
              searchController: _searchController,
              selectedStatus: selectedStatus,
              onStatusChanged: (value) => setState(() {
                selectedStatus = value;
                currentPage = 1;
                selectedCategories = List.filled(filteredCategories.length, false);
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
              child: DataTableWidget<CategoryModel>(
                filteredItems: filteredCategories.sublist(startIndex, endIndex),
                selectedItems: selectedCategories.sublist(startIndex, endIndex),
                searchQuery: _searchController.text,
                columnNames: ['Select', 'Category', 'Created Date', 'Status', 'Actions'],
                fieldAccessors: [
                  (category) => category.category,
                  (category) => category.createdDate,
                  (category) => category.status,
                ],
                onCheckboxChanged: (index, value) =>
                    setState(() => selectedCategories[startIndex + index] = value),
                onStatusToggled: (index) => setState(() {
                  final categoryIndex = categories.indexOf(
                    filteredCategories[startIndex + index],
                  );
                  categories[categoryIndex].status =
                      categories[categoryIndex].status == "Active"
                          ? "Inactive"
                          : "Active";
                  selectedCategories = List.filled(filteredCategories.length, false);
                }),
                onEdit: (index) => _showEditDialog(
                  categories.indexOf(filteredCategories[startIndex + index]),
                ),
                onDelete: (index) => _deleteCategory(
                  categories.indexOf(filteredCategories[startIndex + index]),
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
                selectedCategories = List.filled(filteredCategories.length, false);
              }),
              onPageChanged: (page) => setState(() => currentPage = page),
            ),
          ],
        ),
      ),
    );
  }
}
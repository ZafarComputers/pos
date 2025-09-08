// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pos_frontend/models/vendor_model.dart';
import 'package:pos_frontend/widgets/header_widget.dart';
import 'package:pos_frontend/widgets/search_filter_widget.dart';
import 'package:pos_frontend/widgets/table_header_vendor_widget.dart';
import 'package:pos_frontend/widgets/data_table_vendor_widget.dart';
import 'package:pos_frontend/widgets/pagination_widget.dart';
import 'package:pos_frontend/utils/vendor_utils.dart';
import 'dart:async';

// The main VendorsPage widget for managing vendors
class VendorsPage extends StatefulWidget {
  const VendorsPage({super.key});

  @override
  VendorsPageState createState() => VendorsPageState();
}

class VendorsPageState extends State<VendorsPage> {
  // Dummy data for vendors
  final List<VendorModel> vendors = List.generate(
    25,
    (index) => VendorModel(
      name: "Vendor ${index + 1}",
      address: "Vendor Address ${index + 1}",
      createdDate: "2025-${(index % 12 + 1).toString().padLeft(2, '0')}-01",
      status: index % 3 == 0 ? "Inactive" : "Active",
    ),
  );

  // State variables
  late List<bool> selectedVendors;
  int rowsPerPage = 10;
  int currentPage = 1;
  String? selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String sortColumn = 'vendorName';
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    selectedVendors = List.filled(vendors.length, false);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Debounce search input to prevent excessive rebuilds
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        selectedVendors = List.filled(filteredVendors.length, false);
        currentPage = 1;
      });
    });
  }

  // Sort vendors by column
  void _sortCategories(String column) {
    setState(() {
      if (sortColumn == column) {
        sortAscending = !sortAscending;
      } else {
        sortColumn = column;
        sortAscending = true;
      }
      currentPage = 1;
      selectedVendors = List.filled(filteredVendors.length, false);
    });
  }

  // Filter vendors based on search query and status
  List<VendorModel> get filteredVendors {
    final query = _searchController.text.toLowerCase();
    final filtered = vendors.where((vendor) {
      final matchesStatus =
          selectedStatus == null || vendor.status == selectedStatus;
      final matchesSearch =
          query.isEmpty || vendor.name.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (sortColumn) {
        case 'vendorName':
          cmp = a.name.compareTo(b.name);
          break;
        case 'createdDate':
          cmp = a.createdDate.compareTo(b.createdDate);
          break;
        case 'status':
          cmp = a.status.compareTo(b.status);
          break;
        default:
          cmp = a.address.compareTo(b.address);
      }
      return sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  // Calculate total pages for pagination
  int get totalPages =>
      filteredVendors.isEmpty ? 1 : (filteredVendors.length / rowsPerPage).ceil();
  int get startIndex => (currentPage - 1) * rowsPerPage;
  int get endIndex =>
      (startIndex + rowsPerPage).clamp(0, filteredVendors.length);

  // Show dialog to add a new vendor
  void _showAddVendorDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    bool isActive = true; // Default status is Active

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Vendor"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Vendor Name *", style: TextStyle(color: Colors.red)),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Address", style: TextStyle(color: Colors.black)),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text("Active Status *",
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a vendor name")),
                );
                return;
              }

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Add"),
                  content: const Text("Are you sure you want to add this vendor?"),
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
                  vendors.add(VendorModel(
                    name: nameController.text,
                    address: addressController.text,
                    createdDate:
                        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
                    status: isActive ? "Active" : "Inactive",
                  ));
                  selectedVendors = List.filled(filteredVendors.length, false);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Add Vendor"),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit an existing vendor
  void _showEditDialog(int index) {
    if (index < 0 || index >= vendors.length) return;
    final nameController = TextEditingController(text: vendors[index].name);
    final addressController = TextEditingController(text: vendors[index].address);
    bool isActive = vendors[index].status == "Active";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Vendor"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Vendor Name *", style: TextStyle(color: Colors.red)),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Address", style: TextStyle(color: Colors.black)),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text("Active Status *",
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a vendor name")),
                );
                return;
              }

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Edit"),
                  content:
                      const Text("Are you sure you want to save changes to this vendor?"),
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
                  vendors[index].name = nameController.text;
                  vendors[index].address = addressController.text;
                  vendors[index].status = isActive ? "Active" : "Inactive";
                  selectedVendors = List.filled(filteredVendors.length, false);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Delete a vendor with confirmation
  Future<void> _deleteVendor(int index) async {
    if (index < 0 || index >= vendors.length) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this vendor?"),
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
        vendors.removeAt(index);
        selectedVendors = List.filled(filteredVendors.length, false);
        if (filteredVendors.isEmpty) {
          currentPage = 1;
        } else if (startIndex >= filteredVendors.length) {
          currentPage = totalPages;
        }
      });
    }
  }

  // Show dialog to choose PDF export options
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
      await generatePDF(
        context,
        onlySelected: false,
        filteredVendors: filteredVendors,
        selectedVendors: selectedVendors,
        setLastGeneratedPdfPath: (path) {},
      );
    } else if (choice == 'selected') {
      await generatePDF(
        context,
        onlySelected: true,
        filteredVendors: filteredVendors,
        selectedVendors: selectedVendors,
        setLastGeneratedPdfPath: (path) {},
      );
    }
  }

  // Show dialog to choose Excel export options
  Future<void> _showExcelExportDialog(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Export Excel"),
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
      await generateExcel(
        context,
        onlySelected: false,
        filteredVendors: filteredVendors,
        selectedVendors: selectedVendors,
        setLastGeneratedExcelPath: (path) {},
      );
    } else if (choice == 'selected') {
      await generateExcel(
        context,
        onlySelected: true,
        filteredVendors: filteredVendors,
        selectedVendors: selectedVendors,
        setLastGeneratedExcelPath: (path) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure selectedVendors matches filteredVendors length
    if (selectedVendors.length != filteredVendors.length) {
      selectedVendors = List.filled(filteredVendors.length, false);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            HeaderWidget(
              title: "Vendor Attributes",
              subtitle: "Manage your vendors here",
              onGeneratePDF: () => _showPDFExportDialog(context),
              onGenerateExcel: () => _showExcelExportDialog(context),
              onAddItem: _showAddVendorDialog,
            ),
            const SizedBox(height: 12),
            SearchFilterWidget(
              searchController: _searchController,
              selectedStatus: selectedStatus,
              onStatusChanged: (value) => setState(() {
                selectedStatus = value;
                currentPage = 1;
                selectedVendors = List.filled(filteredVendors.length, false);
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
              child: DataTableWidget<VendorModel>(
                filteredItems: filteredVendors.sublist(startIndex, endIndex),
                selectedItems: selectedVendors.sublist(startIndex, endIndex),
                searchQuery: _searchController.text,
                columnNames: ['Select', 'Vendor Name', 'Address', 'Created Date', 'Status', 'Actions'],
                fieldAccessors: [
                  (vendor) => vendor.name, // For highlighting
                  (vendor) => vendor.address,
                  (vendor) => vendor.createdDate,
                  (vendor) => vendor.status,
                ],
                onCheckboxChanged: (index, value) =>
                    setState(() => selectedVendors[startIndex + index] = value),
                onStatusToggled: (index) => setState(() {
                  final vendorIndex = vendors.indexOf(
                    filteredVendors[startIndex + index],
                  );
                  if (vendorIndex >= 0 && vendorIndex < vendors.length) {
                    vendors[vendorIndex].status =
                        vendors[vendorIndex].status == "Active"
                            ? "Inactive"
                            : "Active";
                    selectedVendors = List.filled(filteredVendors.length, false);
                  }
                }),
                onEdit: (index) => _showEditDialog(
                  vendors.indexOf(filteredVendors[startIndex + index]),
                ),
                onDelete: (index) => _deleteVendor(
                  vendors.indexOf(filteredVendors[startIndex + index]),
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
                selectedVendors = List.filled(filteredVendors.length, false);
              }),
              onPageChanged: (page) => setState(() => currentPage = page),
            ),
          ],
        ),
      ),
    );
  }
}
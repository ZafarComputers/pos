// lib/pages/inventory/variants_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add to pubspec.yaml: intl: ^0.18.0

class VariantsPage extends StatefulWidget {
  const VariantsPage({super.key});

  @override
  State<VariantsPage> createState() => _VariantsPageState();
}

class _VariantsPageState extends State<VariantsPage> {
  // Dummy data for variants
  final List<Map<String, dynamic>> _variants = [
    {
      'variant': 'Size',
      'values': 'XS, S, M, L, XL',
      'createdDate': DateTime(2024, 12, 24),
      'status': true,
    },
    {
      'variant': 'Color',
      'values': 'Red, Blue, Green',
      'createdDate': DateTime(2024, 12, 10),
      'status': true,
    },
    {
      'variant': 'Capacity',
      'values': 'Small, Medium, Large',
      'createdDate': DateTime(2024, 11, 27),
      'status': true,
    },
    {
      'variant': 'Material',
      'values': 'Cotton, Leather, Synthetic',
      'createdDate': DateTime(2024, 11, 18),
      'status': true,
    },
    {
      'variant': 'Weight',
      'values': 'Light, Heavy',
      'createdDate': DateTime(2024, 11, 6),
      'status': true,
    },
    {
      'variant': 'Style',
      'values': 'Casual, Formal, Sporty',
      'createdDate': DateTime(2024, 10, 25),
      'status': true,
    },
    {
      'variant': 'Pattern',
      'values': 'Solid, Striped, Printed',
      'createdDate': DateTime(2024, 10, 14),
      'status': true,
    },
    {
      'variant': 'Memory',
      'values': '8 GB, 16 GB, 36 GB',
      'createdDate': DateTime(2024, 10, 3),
      'status': true,
    },
    {
      'variant': 'Storage',
      'values': '128 GB, 256 GB, 512 GB, 1 TB',
      'createdDate': DateTime(2024, 9, 20),
      'status': true,
    },
    {
      'variant': 'Length',
      'values': 'Short, Regular, Long',
      'createdDate': DateTime(2024, 9, 10),
      'status': true,
    },
  ];

  // State variables
  String _searchQuery = '';
  String _selectedStatus = 'Status';
  int _rowsPerPage = 10;
  int _currentPage = 0;
  List<bool> _selectedRows = [];

  @override
  void initState() {
    super.initState();
    _selectedRows = List<bool>.filled(_variants.length, false);
  }

  // Filtered variants based on search and status
  List<Map<String, dynamic>> get _filteredVariants {
    return _variants.where((variant) {
      final matchesSearch = variant['variant'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == 'Status' ||
          (_selectedStatus == 'Active' && variant['status']) ||
          (_selectedStatus == 'Inactive' && !variant['status']);
      return matchesSearch && matchesStatus;
    }).toList();
  }

  // Show add/edit dialog
  void _showVariantDialog({Map<String, dynamic>? variant, int? index}) {
    final isEdit = variant != null;
    final formKey = GlobalKey<FormState>();
    String variantName = isEdit ? variant['variant'] : '';
    String values = isEdit ? variant['values'] : '';
    bool status = isEdit ? variant['status'] : true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Variant' : 'Add Variant'),
          content: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: variantName,
                      decoration: const InputDecoration(
                        labelText: 'Variant *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (val) => variantName = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: values,
                      decoration: const InputDecoration(
                        labelText: 'Values *',
                        border: OutlineInputBorder(),
                        helperText: 'Enter value separated by comma',
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                      onChanged: (val) => values = val,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status'),
                        Switch(
                          value: status,
                          onChanged: (val) {
                            setDialogState(() {
                              status = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newVariant = {
                    'variant': variantName,
                    'values': values,
                    'createdDate': isEdit ? variant['createdDate'] : DateTime.now(),
                    'status': status,
                  };
                  setState(() {
                    if (isEdit) {
                      _variants[index!] = newVariant;
                    } else {
                      _variants.add(newVariant);
                      _selectedRows.add(false);
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isEdit ? 'Variant updated' : 'Variant added'),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(isEdit ? 'Save Changes' : 'Add Variant', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Delete variant with confirmation
  void _deleteVariant(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this variant?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _variants.removeAt(index);
                _selectedRows.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Variant deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredVariants;
    final totalPages = (filteredList.length / _rowsPerPage).ceil();
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, filteredList.length);
    final currentVariants = filteredList.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Variant Attributes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your variant attributes',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  // Export icons
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export to PDF')));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.table_chart, color: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export to Excel')));
                    },
                  ),
                  const SizedBox(width: 8),
                  // Add Variant button
                  ElevatedButton.icon(
                    onPressed: () => _showVariantDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Variant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search and status filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'Status', child: Text('Status')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                    _currentPage = 0;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // DataTable
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('')), // Checkbox column
                  DataColumn(label: Text('Variant')),
                  DataColumn(label: Text('Values')),
                  DataColumn(label: Text('Created Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('')), // Actions
                ],
                rows: List.generate(currentVariants.length, (index) {
                  final variant = currentVariants[index];
                  final globalIndex = _variants.indexOf(variant);
                  return DataRow(
                    selected: _selectedRows[globalIndex],
                    onSelectChanged: (selected) {
                      setState(() {
                        _selectedRows[globalIndex] = selected!;
                      });
                    },
                    cells: [
                      DataCell.empty, // Empty cell for checkbox (handled by DataTable)
                      DataCell(Text(variant['variant'])),
                      DataCell(Text(variant['values'])),
                      DataCell(Text(DateFormat('dd MMM yyyy').format(variant['createdDate']))),
                      DataCell(Chip(
                        label: Text(variant['status'] ? 'Active' : 'Inactive'),
                        backgroundColor: variant['status'] ? Colors.green : Colors.grey,
                        labelStyle: const TextStyle(color: Colors.white),
                      )),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16),
                            onPressed: () => _showVariantDialog(variant: variant, index: globalIndex),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            onPressed: () => _deleteVariant(globalIndex),
                          ),
                        ],
                      )),
                    ],
                  );
                }),
              ),
            ),
          ),
          // Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Row Per Page: '),
                  DropdownButton<int>(
                    value: _rowsPerPage,
                    items: [10, 20, 50].map((val) => DropdownMenuItem(value: val, child: Text('$val'))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _rowsPerPage = value!;
                        _currentPage = 0;
                      });
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  ),
                  Text('${_currentPage + 1}'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
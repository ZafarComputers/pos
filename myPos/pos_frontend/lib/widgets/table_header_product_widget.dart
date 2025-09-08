import 'package:flutter/material.dart';

class TableHeaderWidget extends StatelessWidget {
  final String sortColumn;
  final bool sortAscending;
  final Function(String) onSort;

  const TableHeaderWidget({
    super.key,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  /// Builds a sortable header with an optional sort indicator.
  Widget _buildHeader(String title, String column) {
    return InkWell(
      onTap: () => onSort(column),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (sortColumn == column)
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 55, child: _buildHeader('Select', 'select')),
        const SizedBox(width: 10),
        // SizedBox(width: 45, child: _buildHeader('Image', 'imageProduct')),
        // const SizedBox(width: 20),
        SizedBox(width: 120, child: _buildHeader('Product Name', 'nameProduct')),
        const SizedBox(width: 120),
        SizedBox(width: 80, child: _buildHeader('Category', 'category')),
        const SizedBox(width: 120),
        SizedBox(width: 60, child: _buildHeader('Vendor', 'vendor')),
        const SizedBox(width: 40),
        SizedBox(width: 50, child: _buildHeader('Price', 'price')),
        const SizedBox(width: 45),
        SizedBox(width: 50, child: _buildHeader('Qty', 'qty')),
        const SizedBox(width: 40),
        SizedBox(width: 100, child: _buildHeader('Created By', 'createdBy')),
        // const SizedBox(width: 60),
        // Expanded(flex: 2, child: _buildHeader('Created By', 'createdBy')),
        const SizedBox(width: 150),
        SizedBox(width: 100, child: _buildHeader('Status', 'status')),
        const SizedBox(width: 20),
        SizedBox(width: 80, child: _buildHeader('Actions', 'actions')),
      ],
    );
  }
}
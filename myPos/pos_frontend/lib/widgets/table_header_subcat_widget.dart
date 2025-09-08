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

  Widget buildHeader(String title, String column) {
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
              size: 16,
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
        SizedBox(width: 60, child: buildHeader("Select", "select")),
        const SizedBox(width: 60), // Spacing after "Select"
        Expanded(flex: 2, child: buildHeader("Image", "image")),
        const SizedBox(width: 20), // Custom spacing after "Image"
        Expanded(flex: 2, child: buildHeader("Sub Category", "subCategory")),
        const SizedBox(width: 60), // Custom spacing after "Sub Category"
        Expanded(flex: 2, child: buildHeader("Category", "category")),
        const SizedBox(width: 60), // Spacing after "Category"
        Expanded(flex: 2, child: buildHeader("Description", "description")),
        const SizedBox(width: 70), // Spacing after "Description"
        Expanded(flex: 2, child: buildHeader("Created Date", "createdDate")),
        const SizedBox(width: 60), // Spacing after "Created Date"
        SizedBox(width: 120, child: buildHeader("Status", "status")),
        const SizedBox(width: 60), // Spacing after "Status"
        SizedBox(width: 100, child: buildHeader("Actions", "actions")),
      ],
    );
  }
}
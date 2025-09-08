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
        const SizedBox(width: 20),
        Expanded(flex: 2, child: buildHeader("Name", "name")),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: buildHeader("Address", "address")),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: buildHeader("Created Date", "createdDate")),
        const SizedBox(width: 20),
        SizedBox(width: 120, child: buildHeader("Status", "status")),
        const SizedBox(width: 20),
        SizedBox(width: 100, child: buildHeader("Actions", "actions")),
      ],
    );
  }
}
// data_table_widget.dart
import 'package:flutter/material.dart';

class DataTableWidget<T> extends StatefulWidget {
  final List<T> filteredItems;
  final List<bool> selectedItems;
  final String searchQuery;
  final List<String> columnNames;
  final List<String Function(T)> fieldAccessors;
  final Function(int, bool) onCheckboxChanged;
  final Function(int) onStatusToggled;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const DataTableWidget({
    super.key,
    required this.filteredItems,
    required this.selectedItems,
    required this.searchQuery,
    required this.columnNames,
    required this.fieldAccessors,
    required this.onCheckboxChanged,
    required this.onStatusToggled,
    required this.onEdit,
    required this.onDelete,
  }) : assert(fieldAccessors.length >= 3, 'fieldAccessors must provide at least 3 accessors (name, date, status).');

  @override
  DataTableWidgetState<T> createState() => DataTableWidgetState<T>();
}

class DataTableWidgetState<T> extends State<DataTableWidget<T>> {
  Widget buildHighlightedText(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    if (!lowerText.contains(lowerQuery)) return Text(text);

    final spans = <TextSpan>[];
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      );
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filteredItems.isEmpty) {
      return const Center(child: Text("No items available"));
    }
    return ListView.separated(
      itemCount: widget.filteredItems.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),
      itemBuilder: (context, index) {
        if (index >= widget.filteredItems.length ||
            index >= widget.selectedItems.length) {
          return const SizedBox.shrink();
        }
        return Container(
          color: Colors.white,
          child: InkWell(
            onTap: () =>
                widget.onCheckboxChanged(index, !widget.selectedItems[index]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 60,
                    child: Checkbox(
                      value: widget.selectedItems[index],
                      onChanged: (value) =>
                          widget.onCheckboxChanged(index, value ?? false),
                      activeColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: buildHighlightedText(
                      widget.fieldAccessors[0](widget.filteredItems[index]),
                      widget.searchQuery,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.fieldAccessors[1](widget.filteredItems[index]),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.fieldAccessors[2](widget.filteredItems[index]), // STATUS accessor
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => widget.onStatusToggled(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.fieldAccessors[2](widget.filteredItems[index]) == "Active"
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        minimumSize: const Size(100, 40),
                        elevation: 2,
                        shadowColor: Colors.black12,
                      ),
                      child: Text(
                        widget.fieldAccessors[2](widget.filteredItems[index]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => widget.onEdit(index),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => widget.onDelete(index),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

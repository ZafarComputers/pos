import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

// Defines spacing for each column to match TableHeaderWidget
const _columnSpacings = [
  20.0, // After Select
  20.0, // After Vendor's Name
  20.0, // After Address
  20.0, // After Created Date
  20.0, // After Status
];

// A widget to display a data table for vendors
class DataTableWidget<T> extends StatefulWidget {
  final List<T> filteredItems;
  final List<bool> selectedItems;
  final String searchQuery;
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
    required this.fieldAccessors,
    required this.onCheckboxChanged,
    required this.onStatusToggled,
    required this.onEdit,
    required this.onDelete,
    required List<String> columnNames,
  }) : assert(
         fieldAccessors.length >= 4,
         'fieldAccessors must provide at least 4 accessors (name, address, createdDate, status).',
       );

  @override
  State<DataTableWidget<T>> createState() => DataTableWidgetState<T>();
}

class DataTableWidgetState<T> extends State<DataTableWidget<T>> {
  // Highlights matching text from search query
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

  // Renders a cell as an image or text
  Widget buildCell(String value, {bool highlight = false}) {
    if (value.toLowerCase().endsWith('.png') ||
        value.toLowerCase().endsWith('.jpg') ||
        value.toLowerCase().endsWith('.jpeg')) {
      // Handle local asset or file path
      if (value.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            value,
            width: 24,
            height: 35,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              developer.log(
                'Failed to load asset image: $value, error: $error',
              );
              return const Icon(
                Icons.broken_image,
                size: 24,
                color: Colors.grey,
              );
            },
          ),
        );
      } else {
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(value),
              width: 24,
              height: 35,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                developer.log(
                  'Failed to load file image: $value, error: $error',
                );
                return const Icon(
                  Icons.broken_image,
                  size: 24,
                  color: Colors.grey,
                );
              },
            ),
          );
        } catch (e) {
          developer.log('Error processing image file: $value, error: $e');
          return const Icon(Icons.broken_image, size: 24, color: Colors.grey);
        }
      }
    }
    return highlight
        ? buildHighlightedText(value, widget.searchQuery)
        : Text(value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filteredItems.isEmpty) {
      return const Center(child: Text('No items available'));
    }

    return ListView.separated(
      itemCount: widget.filteredItems.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),
      itemBuilder: (context, index) {
        if (index >= widget.filteredItems.length ||
            index >= widget.selectedItems.length ||
            widget.fieldAccessors.length < 4) {
          return const SizedBox.shrink();
        }

        final item = widget.filteredItems[index];
        final isSelected = widget.selectedItems[index];
        final status = widget.fieldAccessors[3](item);

        return Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox column
                SizedBox(
                  width: 50,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) =>
                        widget.onCheckboxChanged(index, value ?? false),
                    activeColor: Colors.blue,
                  ),
                ),
                SizedBox(width: _columnSpacings[0]),

                // Vendor's Name column
                Expanded(
                  flex: 2,
                  child: buildCell(
                    widget.fieldAccessors[0](item),
                    highlight: true,
                  ),
                ),
                SizedBox(width: _columnSpacings[1]),

                // Address column
                Expanded(
                  flex: 2,
                  child: buildCell(
                    widget.fieldAccessors[1](item),
                    highlight: true,
                  ),
                ),
                SizedBox(width: _columnSpacings[2]),

                // Created Date column
                Expanded(flex: 2, child: Text(widget.fieldAccessors[2](item))),
                SizedBox(width: _columnSpacings[3]),

                // Status column
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => widget.onStatusToggled(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.fieldAccessors[3](item) == "Active"
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
                    ),
                    child: Text(status, textAlign: TextAlign.center),
                  ),
                ),
                SizedBox(width: _columnSpacings[4]),

                // Actions column
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
        );
      },
    );
  }
}

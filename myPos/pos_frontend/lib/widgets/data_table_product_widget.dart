import 'dart:io';
import 'package:flutter/material.dart';

/// Defines spacing for each column to match the table header layout.
final _columnSpacings = [
  05.0, // After Select (reduced for tighter fit)
  05.0, // After Product Image (reduced)
  05.0, // After Product Name
  20.0, // After Category
  20.0, // After Brand
  15.0, // After Price
  15.0, // After Quantity
  10.0, // After User Image
  20.0, // After Created By
  20.0, // After Status
  10.0, // After Actions (reduced)
];

class DataTableWidget<T> extends StatefulWidget {
  final List<T> filteredItems;
  final List<bool> selectedItems;
  final String searchQuery;
  final List<dynamic Function(T)> fieldAccessors;
  final Function(int, bool) onCheckboxChanged;
  final Function(int) onStatusToggled;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final List<double>? customColumnSpacings; // Optional custom spacings

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
    this.customColumnSpacings,
  }) : assert(fieldAccessors.length >= 9,
            'fieldAccessors must provide at least 9 accessors (imageProduct, nameProduct, category, brand, price, quantity, imageUser, createdBy, status)');

  @override
  State<DataTableWidget<T>> createState() => _DataTableWidgetState<T>();
}

class _DataTableWidgetState<T> extends State<DataTableWidget<T>> {
  late List<double> effectiveSpacings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    effectiveSpacings = widget.customColumnSpacings ?? _columnSpacings;
  }

  /// Highlights text matching the search query.
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) return Text(text);

    final spans = <TextSpan>[];
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ));
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return RichText(text: TextSpan(children: spans, style: const TextStyle(color: Colors.black)));
  }

  /// Renders a cell as an image, formatted number, or text based on the value.
  Widget _buildCell(dynamic value, {bool highlight = false}) {
    if (value is String) {
      if (value.toLowerCase().endsWith('.png') ||
          value.toLowerCase().endsWith('.jpg') ||
          value.toLowerCase().endsWith('.jpeg')) {
        if (value.startsWith('assets/images/')) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              value,
              width: 24,
              height: 35,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 24, color: Colors.grey),
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
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 24, color: Color.fromARGB(255, 27, 2, 109)),
              ),
            );
          } catch (e) {
            return const Icon(Icons.broken_image, size: 24, color: Color.fromARGB(255, 255, 2, 109));
          }
        }
      }
      return highlight ? _buildHighlightedText(value, widget.searchQuery) : Text(value);
    } else if (value is num) {
      return Text(value.toStringAsFixed(value is double ? 2 : 0));
    }
    return Text(value?.toString() ?? 'N/A');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filteredItems.isEmpty) {
      return const Center(child: Text('No products available'));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 250; // 250 pixels reserved for sidebar

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: availableWidth,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: widget.filteredItems.length,
          separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: Colors.grey[300]),
          itemBuilder: (context, index) {
            if (index >= widget.filteredItems.length || index >= widget.selectedItems.length) {
              return const SizedBox.shrink();
            }

            final item = widget.filteredItems[index];
            final isSelected = widget.selectedItems[index];
            final status = widget.fieldAccessors[8](item) as String;

            return Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Select Checkbox
                    SizedBox(width: 40, child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => widget.onCheckboxChanged(index, value ?? false),
                      activeColor: Colors.blue,
                    )),
                    // SizedBox(width: effectiveSpacings[0]),
                    SizedBox(width: 30),

                    // Product Image
                    SizedBox(width: 25, child: _buildCell(widget.fieldAccessors[0](item))),
                    // SizedBox(width: effectiveSpacings[1]),
                    SizedBox(width: 10),

                    // Product Name
                    SizedBox(width: 100, child: _buildCell(widget.fieldAccessors[1](item), highlight: true)),
                    // SizedBox(width: effectiveSpacings[2]),
                    SizedBox(width: 100),

                    // Category
                    SizedBox(width: 100, child: _buildCell(widget.fieldAccessors[2](item), highlight: true)),
                    SizedBox(width: 100),
                    // SizedBox(width: effectiveSpacings[3]),

                    // Brand
                    SizedBox(width: 50, child: _buildCell(widget.fieldAccessors[3](item), highlight: true)),
                    SizedBox(width: 50),
                    // SizedBox(width: effectiveSpacings[4]),

                    // Price
                    SizedBox(width: 50, child: _buildCell(widget.fieldAccessors[4](item))),
                    SizedBox(width: 50),
                    // SizedBox(width: effectiveSpacings[5]),

                    // Quantity
                    SizedBox(width: 40, child: _buildCell(widget.fieldAccessors[5](item))),
                    SizedBox(width: 40),
                    // SizedBox(width: effectiveSpacings[6]),

                    // User Image
                    SizedBox(width: 20, child: _buildCell(widget.fieldAccessors[6](item))),
                    SizedBox(width: 10),
                    // SizedBox(width: effectiveSpacings[7]),

                    // Created By
                    SizedBox(width: 80, child: _buildCell(widget.fieldAccessors[7](item))),
                    SizedBox(width: 120),
                    // SizedBox(width: effectiveSpacings[8]),

                    // Status
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: () => widget.onStatusToggled(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == 'Active' ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          minimumSize: const Size(100, 40),
                          elevation: 2,
                        ),
                        child: Text(status, textAlign: TextAlign.center),
                      ),
                    ),
                    SizedBox(width: 40),
                    // SizedBox(width: effectiveSpacings[9]),

                    // Actions
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
                          const SizedBox(width: 30),
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
        ),
      ),
    );
  }
}
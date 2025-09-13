// lib/widgets/data_table_subcat_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';

/// Generic data table for SubCategoryModel-like items.
/// fieldAccessors must follow: [image, subCategory, category, description, createdDate, status]
class DataTableSubcatWidget<T> extends StatelessWidget {
  final List<T> items;
  final List<bool> selected;
  final String searchQuery;
  final List<String Function(T)> fieldAccessors;
  final Function(int, bool) onCheckboxChanged;
  final Function(int) onStatusToggled;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const DataTableSubcatWidget({
    super.key,
    required this.items,
    required this.selected,
    required this.searchQuery,
    required this.fieldAccessors,
    required this.onCheckboxChanged,
    required this.onStatusToggled,
    required this.onEdit,
    required this.onDelete,
  }) : assert(fieldAccessors.length >= 6, 'Need 6 accessors (image, subCategory, category, description, createdDate, status)');

  /// Highlights search query matches in text
  Widget _buildHighlighted(String text) {
    if (searchQuery.isEmpty) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final q = searchQuery.toLowerCase();
    if (!lower.contains(q)) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final spans = <TextSpan>[];
    int start = 0;
    int index = lower.indexOf(q);
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + q.length),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ));
      start = index + q.length;
      index = lower.indexOf(q, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(text: TextSpan(children: spans, style: const TextStyle(color: Colors.black)));
  }

  /// Builds image widget from path (asset or file)
  Widget _buildImage(String path) {
    if (path.trim().isEmpty) {
      return const Icon(Icons.broken_image, size: 32, color: Colors.grey);
    }
    final lower = path.toLowerCase();
    if (lower.startsWith('assets/')) {
      try {
        return Image.asset(
          path,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            size: 32,
            color: Colors.grey,
          ),
        );
      } catch (_) {
        return const Icon(Icons.broken_image, size: 32, color: Colors.grey);
      }
    }
    try {
      return Image.file(
        File(path),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image,
          size: 32,
          color: Colors.grey,
        ),
      );
    } catch (_) {
      return const Icon(Icons.broken_image, size: 32, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items available'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
      itemBuilder: (context, i) {
        final item = items[i];
        final isSelected = (i < selected.length) ? selected[i] : false;
        final image = fieldAccessors[0](item);
        final subCategory = fieldAccessors[1](item);
        final category = fieldAccessors[2](item);
        final description = fieldAccessors[3](item);
        final createdDate = fieldAccessors[4](item);
        final status = fieldAccessors[5](item);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 56,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (v) => onCheckboxChanged(i, v ?? false),
                  activeColor: Colors.blue,
                ),
              ),
              // Image
              SizedBox(width: 56, child: _buildImage(image)),
              const SizedBox(width: 12),
              // Sub Category
              Expanded(
                flex: 2,
                child: _buildHighlighted(subCategory),
              ),
              // Category
              Expanded(
                flex: 2,
                child: Text(category, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              // Description
              Expanded(
                flex: 2,
                child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              // Created Date
              Expanded(
                flex: 2,
                child: Text(createdDate),
              ),
              // Status
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () => onStatusToggled(i),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(status == 'Active' ? Colors.green : Colors.red),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 10)),
                  ),
                  child: Text(status),
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => onEdit(i),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => onDelete(i),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
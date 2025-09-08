// import 'dart:io';
// import 'package:flutter/material.dart';

// // Defines spacing for each column to match TableHeaderWidget
// final _columnSpacings = [
//   60.0, // After Select
//   100.0, // After Image
//   60.0, // After Sub Category
//   60.0, // After Category
//   60.0, // After Description
//   60.0, // After Created Date
//   60.0, // After Status
// ];

// class DataTableWidget<T> extends StatefulWidget {
//   final List<T> filteredItems;
//   final List<bool> selectedItems;
//   final String searchQuery;
//   final List<String Function(T)> fieldAccessors;
//   final Function(int, bool) onCheckboxChanged;
//   final Function(int) onStatusToggled;
//   final Function(int) onEdit;
//   final Function(int) onDelete;

//   const DataTableWidget({
//     super.key,
//     required this.filteredItems,
//     required this.selectedItems,
//     required this.searchQuery,
//     required this.fieldAccessors,
//     required this.onCheckboxChanged,
//     required this.onStatusToggled,
//     required this.onEdit,
//     required this.onDelete,
//   }) : assert(fieldAccessors.length >= 5,
//             'fieldAccessors must provide at least 5 accessors (image, subCategory, category, description, createdDate).');

//   @override
//   State<DataTableWidget<T>> createState() => DataTableWidgetState<T>();
// }

// class DataTableWidgetState<T> extends State<DataTableWidget<T>> {
//   /// Highlights matching text from search query
//   Widget buildHighlightedText(String text, String query) {
//     if (query.isEmpty) return Text(text);
//     final lowerText = text.toLowerCase();
//     final lowerQuery = query.toLowerCase();

//     if (!lowerText.contains(lowerQuery)) return Text(text);

//     final spans = <TextSpan>[];
//     int start = 0;
//     int index = lowerText.indexOf(lowerQuery);

//     while (index != -1) {
//       if (index > start) {
//         spans.add(TextSpan(text: text.substring(start, index)));
//       }
//       spans.add(
//         TextSpan(
//           text: text.substring(index, index + query.length),
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.blue,
//           ),
//         ),
//       );
//       start = index + query.length;
//       index = lowerText.indexOf(lowerQuery, start);
//     }

//     if (start < text.length) {
//       spans.add(TextSpan(text: text.substring(start)));
//     }

//     return RichText(
//       text: TextSpan(
//         children: spans,
//         style: const TextStyle(color: Colors.black),
//       ),
//     );
//   }

//   /// Renders a cell as an image or text
//   Widget buildCell(String value, {bool highlight = false}) {
//     if (value.toLowerCase().endsWith('.png') ||
//         value.toLowerCase().endsWith('.jpg') ||
//         value.toLowerCase().endsWith('.jpeg')) {
//       // Handle local asset or file path
//       if (value.startsWith('assets/')) {
//         return ClipRRect(
//           borderRadius: BorderRadius.circular(6),
//           child: Image.asset(
//             value,
//             width: 24,
//             height: 35,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) => const Icon(
//               Icons.broken_image,
//               size: 24,
//               color: Colors.grey,
//             ),
//           ),
//         );
//       } else {
//         try {
//           return ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: Image.file(
//               File(value),
//               width: 24,
//               height: 35,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) => const Icon(
//                 Icons.broken_image,
//                 size: 24,
//                 color: Colors.grey,
//               ),
//             ),
//           );
//         } catch (e) {
//           return const Icon(
//             Icons.broken_image,
//             size: 24,
//             color: Colors.grey,
//           );
//         }
//       }
//     }
//     return highlight ? buildHighlightedText(value, widget.searchQuery) : Text(value);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.filteredItems.isEmpty) {
//       return const Center(child: Text('No items available'));
//     }

//     return ListView.separated(
//       itemCount: widget.filteredItems.length,
//       separatorBuilder: (_, _) => Divider(
//         height: 1,
//         thickness: 1,
//         color: Colors.grey[300],
//       ),
//       itemBuilder: (context, index) {
//         if (index >= widget.filteredItems.length ||
//             index >= widget.selectedItems.length ||
//             widget.fieldAccessors.length < 5) {
//           return const SizedBox.shrink();
//         }

//         final item = widget.filteredItems[index];
//         final isSelected = widget.selectedItems[index];
//         final status = widget.fieldAccessors.length > 5 ? widget.fieldAccessors[5](item) : 'Unknown';

//         return Container(
//           color: Colors.white,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // Checkbox column
//                 SizedBox(
//                   width: 50,
//                   child: Checkbox(
//                     value: isSelected,
//                     onChanged: (value) => widget.onCheckboxChanged(index, value ?? false),
//                     activeColor: Colors.blue,
//                   ),
//                 ),
//                 SizedBox(width: _columnSpacings[0]),

//                 // Image column
//                 SizedBox(
//                   width: 40,
//                   child: buildCell(widget.fieldAccessors[0](item)),
//                 ),
//                 SizedBox(width: _columnSpacings[1]),

//                 // Sub Category column
//                 Expanded(
//                   flex: 2,
//                   child: buildCell(widget.fieldAccessors[1](item), highlight: true),
//                 ),
//                 SizedBox(width: _columnSpacings[2]),

//                 // Category column
//                 Expanded(
//                   flex: 2,
//                   child: buildCell(widget.fieldAccessors[2](item), highlight: true),
//                 ),
//                 SizedBox(width: _columnSpacings[3]),

//                 // Description column
//                 Expanded(
//                   flex: 2,
//                   child: buildCell(widget.fieldAccessors[3](item), highlight: true),
//                 ),
//                 SizedBox(width: _columnSpacings[4]),

//                 // Created Date column
//                 Expanded(
//                   flex: 2,
//                   child: Text(widget.fieldAccessors[4](item)),
//                 ),
//                 SizedBox(width: _columnSpacings[5]),

//                 // Status column
//                 SizedBox(
//                   width: 120,
//                   child: ElevatedButton(
//                     onPressed: () => widget.onStatusToggled(index),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: status == 'Active' ? Colors.green : Colors.red,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                       minimumSize: const Size(100, 40),
//                       elevation: 2,
//                     ),
//                     child: Text(status, textAlign: TextAlign.center),
//                   ),
//                 ),
//                 SizedBox(width: _columnSpacings[6]),

//                 // Actions column
//                 SizedBox(
//                   width: 100,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.edit, color: Colors.blue),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                         onPressed: () => widget.onEdit(index),
//                       ),
//                       const SizedBox(width: 8),
//                       IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.red),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                         onPressed: () => widget.onDelete(index),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// ignore_for_file: deprecated_member_use

// lib/widgets/data_table_subcat_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';

/// Generic data table for SubCategoryModel-like items.
/// fieldAccessors must follow: [imageAccessor, nameAccessor, categoryAccessor, createdDateAccessor, statusAccessor]
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
  }) : assert(fieldAccessors.length >= 5, 'Need 5 accessors (image,name,category,createdDate,status)');

  Widget _buildHighlighted(String text) {
    if (searchQuery.isEmpty) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    final lower = text.toLowerCase();
    final q = searchQuery.toLowerCase();
    if (!lower.contains(q)) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);

    final spans = <TextSpan>[];
    int start = 0;
    int index = lower.indexOf(q);
    while (index != -1) {
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(text: text.substring(index, index + q.length), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)));
      start = index + q.length;
      index = lower.indexOf(q, start);
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return RichText(text: TextSpan(children: spans, style: const TextStyle(color: Colors.black)));
  }

  Widget _buildImage(String path) {
    if (path.trim().isEmpty) {
      return const SizedBox(width: 40, height: 40);
    }
    final lower = path.toLowerCase();
    if (lower.startsWith('assets/') || lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      // asset path
      try {
        return Image.asset(path, width: 48, height: 48, fit: BoxFit.cover);
      } catch (_) {
        // fallback
        return const SizedBox(width: 48, height: 48);
      }
    }
    // try file
    try {
      return Image.file(File(path), width: 48, height: 48, fit: BoxFit.cover);
    } catch (_) {
      return const SizedBox(width: 48, height: 48);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No items available'));

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey[300]),
      itemBuilder: (context, i) {
        final item = items[i];
        final isSelected = (i < selected.length) ? selected[i] : false;
        final image = fieldAccessors[0](item);
        final name = fieldAccessors[1](item);
        final category = fieldAccessors[2](item);
        final created = fieldAccessors[3](item);
        final status = fieldAccessors[4](item);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
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

              // Name & Category
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHighlighted(name),
                    const SizedBox(height: 4),
                    Text(category, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),

              // Created Date
              Expanded(flex: 2, child: Text(created)),

              // Status button
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () => onStatusToggled(i),
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(status == 'Active' ? Colors.green : Colors.red),
                    foregroundColor: const MaterialStatePropertyAll(Colors.white),
                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 10)),
                  ),
                  child: Text(status),
                ),
              ),

              const SizedBox(width: 8),

              // Actions
              Row(
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
            ],
          ),
        );
      },
    );
  }
}

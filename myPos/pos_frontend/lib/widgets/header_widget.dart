// import 'package:flutter/material.dart';

// class HeaderWidget extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final VoidCallback onGeneratePDF;
//   final VoidCallback onGenerateExcel;
//   final VoidCallback onAddItem;

//   const HeaderWidget({
//     super.key,
//     required this.title,
//     required this.subtitle,
//     required this.onGeneratePDF,
//     required this.onGenerateExcel,
//     required this.onAddItem,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         // Left: Title and subtitle
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               style: const TextStyle(fontSize: 14, color: Colors.grey),
//             ),
//           ],
//         ),
//         // Right: Action buttons
//         Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
//               tooltip: 'Generate PDF',
//               onPressed: onGeneratePDF,
//             ),
//             const SizedBox(width: 12),
//             IconButton(
//               icon: const Icon(Icons.table_chart, color: Colors.green),
//               tooltip: 'Generate Excel',
//               onPressed: onGenerateExcel,
//             ),
//             const SizedBox(width: 16),
//             ElevatedButton.icon(
//               onPressed: onAddItem,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 12,
//                 ),
//               ),
//               icon: const Icon(Icons.add, color: Colors.white),
//               label: const Text(
//                 "Add Item",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// lib/widgets/header_widget.dart
import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onAddItem;
  final VoidCallback? onGeneratePDF;
  final VoidCallback? onGenerateExcel;

  const HeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.onAddItem,
    this.onGeneratePDF,
    this.onGenerateExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Title area
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),

        // Buttons
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onGeneratePDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export PDF'),
              style: ButtonStyle(
                backgroundColor: const WidgetStatePropertyAll(Colors.redAccent),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onGenerateExcel,
              icon: const Icon(Icons.grid_on),
              label: const Text('Export Excel'),
              style: ButtonStyle(
                backgroundColor: const WidgetStatePropertyAll(Colors.green),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: ButtonStyle(
                backgroundColor: const WidgetStatePropertyAll(Colors.orange),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

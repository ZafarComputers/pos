// import 'package:flutter/material.dart';

// class PaginationWidget extends StatelessWidget {
//   final int rowsPerPage;
//   final int currentPage;
//   final int totalPages;
//   final Function(int) onRowsPerPageChanged;
//   final Function(int) onPageChanged;

//   const PaginationWidget({
//     super.key,
//     required this.rowsPerPage,
//     required this.currentPage,
//     required this.totalPages,
//     required this.onRowsPerPageChanged,
//     required this.onPageChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             const Text(
//               "Rows Per Page:",
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(width: 12),
//             DropdownButton<int>(
//               value: rowsPerPage,
//               items: [10, 20, 50, 100]
//                   .map(
//                     (value) => DropdownMenuItem<int>(
//                       value: value,
//                       child: Text(
//                         "$value",
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ),
//                   )
//                   .toList(),
//               onChanged: (value) =>
//                   value != null ? onRowsPerPageChanged(value) : null,
//               style: const TextStyle(color: Colors.black, fontSize: 14),
//               underline: Container(
//                 height: 2,
//                 color: Colors.blue.shade300,
//               ),
//               dropdownColor: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//             ),
//           ],
//         ),
//         Row(
//           children: [
//             ElevatedButton(
//               onPressed: currentPage > 1
//                   ? () => onPageChanged(currentPage - 1)
//                   : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue.shade600,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 minimumSize: const Size(40, 40),
//                 elevation: 2,
//               ),
//               child: const Text("<"),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               "$currentPage of $totalPages",
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(width: 12),
//             ElevatedButton(
//               onPressed: currentPage < totalPages
//                   ? () => onPageChanged(currentPage + 1)
//                   : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue.shade600,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 minimumSize: const Size(40, 40),
//                 elevation: 2,
//               ),
//               child: const Text(">"),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// lib/widgets/pagination_widget.dart
import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int rowsPerPage;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;

  const PaginationWidget({
    super.key,
    required this.rowsPerPage,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Rows per page:'),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: rowsPerPage,
          items: const [
            DropdownMenuItem(value: 5, child: Text('5')),
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
          ],
          onChanged: (v) {
            if (v != null) onRowsPerPageChanged(v);
          },
        ),
        const Spacer(),
        IconButton(
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$currentPage of $totalPages'),
        IconButton(
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

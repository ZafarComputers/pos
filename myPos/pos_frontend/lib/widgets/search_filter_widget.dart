// import 'package:flutter/material.dart';

// class SearchFilterWidget extends StatelessWidget {
//   final TextEditingController searchController;
//   final String? selectedStatus;
//   final Function(String?) onStatusChanged;

//   const SearchFilterWidget({
//     super.key,
//     required this.searchController,
//     this.selectedStatus,
//     required this.onStatusChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: searchController,
//             decoration: InputDecoration(
//               hintText: "Search by Brand Name...",
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               prefixIcon: const Icon(Icons.search, color: Colors.grey),
//               suffixIcon: searchController.text.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(
//                         Icons.clear,
//                         color: Colors.red,
//                         size: 24,
//                       ),
//                       onPressed: searchController.clear,
//                     )
//                   : null,
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         DropdownButton<String?>(
//           hint: const Text("Select Status"),
//           value: selectedStatus,
//           items: const [
//             DropdownMenuItem<String?>(value: null, child: Text("All Statuses")),
//             DropdownMenuItem<String?>(value: "Active", child: Text("Active")),
//             DropdownMenuItem<String?>(value: "Inactive", child: Text("Inactive")),
//           ],
//           onChanged: onStatusChanged,
//           style: const TextStyle(color: Colors.black, fontSize: 14),
//           underline: Container(
//             height: 2,
//             color: Colors.grey.shade300,
//           ),
//         ),
//       ],
//     );
//   }
// }

// lib/widgets/search_filter_widget.dart
import 'package:flutter/material.dart';

class SearchFilterWidget extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const SearchFilterWidget({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Status dropdown
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
            ],
            onChanged: onStatusChanged,
          ),
        )
      ],
    );
  }
}

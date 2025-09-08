import 'package:flutter/material.dart';

class RolesPermissionsPage extends StatefulWidget {
  const RolesPermissionsPage({super.key});

  @override
  State<RolesPermissionsPage> createState() => _RolesPermissionsPageState();
}

class _RolesPermissionsPageState extends State<RolesPermissionsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Roles & Permissions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Replace with your roles & permissions count
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Role/Permission ${index + 1}'),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

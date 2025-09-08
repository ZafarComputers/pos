// lib/widgets/footer.dart
import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Center(
        child: Text(
          '© 2025 POS Inventory Management System',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
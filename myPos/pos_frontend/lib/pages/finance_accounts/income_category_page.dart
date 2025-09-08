import 'package:flutter/material.dart';

class IncomeCategoryPage extends StatelessWidget {
  const IncomeCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Categories'),
      ),
      body: const Center(
        child: Text('Income Categories Information'),
      ),
    );
  }
}

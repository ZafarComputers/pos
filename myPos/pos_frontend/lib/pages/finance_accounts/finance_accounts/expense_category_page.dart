import 'package:flutter/material.dart';

class ExpenseCategoryPage extends StatelessWidget {
  const ExpenseCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
      ),
      body: const Center(
        child: Text('Expense Categories Information'),
      ),
    );
  }
}

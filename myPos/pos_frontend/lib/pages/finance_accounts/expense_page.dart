import 'package:flutter/material.dart';

class ExpensePage extends StatelessWidget {
  const ExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashflow'),
      ),
      body: const Center(
        child: Text('Cashflow Information'),
      ),
    );
  }
}

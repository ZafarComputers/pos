import 'package:flutter/material.dart';

class CashflowPage extends StatelessWidget {
  const CashflowPage({super.key});

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

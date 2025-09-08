import 'package:flutter/material.dart';

class BalanceSheetPage extends StatelessWidget {
  const BalanceSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Sheet'),
      ),
      body: const Center(
        child: Text('Balance Sheet Information'),
      ),
    );
  }
}

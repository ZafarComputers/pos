import 'package:flutter/material.dart';

class BankAccountPage extends StatelessWidget {
  const BankAccountPage({super.key});

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

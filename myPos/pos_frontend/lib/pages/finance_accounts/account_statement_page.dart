import 'package:flutter/material.dart';

class AccountStatementPage extends StatelessWidget {
  const AccountStatementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Statement'),
      ),
      body: const Center(
        child: Text('Account Statement Information'),
      ),
    );
  }
}

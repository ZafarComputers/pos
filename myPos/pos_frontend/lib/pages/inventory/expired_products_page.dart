import 'package:flutter/material.dart';

class ExpiredProductsPage extends StatefulWidget {
  const ExpiredProductsPage({super.key});

  @override
  State<ExpiredProductsPage> createState() => _ExpiredProductsPageState();
}

class _ExpiredProductsPageState extends State<ExpiredProductsPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expired Products',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Replace with your expired products count
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Expired Product ${index + 1}'),
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

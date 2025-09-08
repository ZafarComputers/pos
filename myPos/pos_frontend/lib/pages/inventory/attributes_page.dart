import 'package:flutter/material.dart';

class AttributesPage extends StatefulWidget {
  const AttributesPage({super.key});

  @override
  State<AttributesPage> createState() => _AttributesPageState();
}

class _AttributesPageState extends State<AttributesPage> {
  // Dummy data for attributes
  final List<Map<String, dynamic>> _attributes = [
    {
      'name': 'Color',
      'values': ['Red', 'Green', 'Blue'],
    },
    {
      'name': 'Size',
      'values': ['S', 'M', 'L', 'XL'],
    },
    {
      'name': 'Material',
      'values': ['Cotton', 'Polyester', 'Wool'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Attributes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _attributes.length,
              itemBuilder: (context, index) {
                final attribute = _attributes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attribute['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: List.generate(
                            attribute['values'].length,
                            (valueIndex) {
                              return Chip(
                                label: Text(attribute['values'][valueIndex]),
                              );
                            },
                          ),
                        ),
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

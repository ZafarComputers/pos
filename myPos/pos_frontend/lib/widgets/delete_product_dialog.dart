import 'package:flutter/material.dart';
import 'package:pos_frontend/models/product_model.dart';

Future<void> showDeleteProductDialog(
  BuildContext context, {
  required List<ProductModel> filteredProducts,
  required int index,
  required List<ProductModel> products,
  required void Function(VoidCallback) setStateCallback,
  required int totalPages,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: const Text('Are you sure you want to delete this product?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    setStateCallback(() {
      final model = filteredProducts[index];
      final actualIndex = products.indexOf(model);
      if (actualIndex != -1) {
        products.removeAt(actualIndex);
      }
    });
  }
}
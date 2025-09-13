// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pos_frontend/models/product_model.dart';

void showEditProductDialog(
  BuildContext context, {
  required List<ProductModel> filteredProducts,
  required int index,
  required List<ProductModel> products,
  required void Function(VoidCallback) setStateCallback,
}) {
  final model = filteredProducts[index];
  final nameController = TextEditingController(text: model.nameProduct);
  final priceController = TextEditingController(text: model.price.toString());
  final quantityController = TextEditingController(text: model.quantity.toString());
  String? selectedCategory = model.category;
  String? selectedVendor = model.vendor;
  bool isActive = model.status == 'Active';
  const categoryOptions = ['Category 1', 'Category 2', 'Category 3', 'Category 4'];
  const vendorOptions = ['Vendor 1', 'Vendor 2', 'Vendor 3', 'Vendor 4'];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Edit Product'),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name input
                  const Text('Product Name *', style: TextStyle(color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Category dropdown
                  const Text('Category *', style: TextStyle(color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: categoryOptions.map((category) {
                      return DropdownMenuItem<String>(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (newValue) => setStateDialog(() => selectedCategory = newValue),
                  ),
                  const SizedBox(height: 24),
                  // Vendor dropdown
                  const Text('Vendor *', style: TextStyle(color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedVendor,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: vendorOptions.map((vendor) {
                      return DropdownMenuItem<String>(value: vendor, child: Text(vendor));
                    }).toList(),
                    onChanged: (newValue) => setStateDialog(() => selectedVendor = newValue),
                  ),
                  const SizedBox(height: 24),
                  // Price input
                  const Text('Price *', style: TextStyle(color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quantity input
                  const Text('Quantity *', style: TextStyle(color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Status toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status', style: TextStyle(fontSize: 14)),
                      Switch(
                        value: isActive,
                        activeThumbColor: Colors.green,
                        onChanged: (value) => setStateDialog(() => isActive = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                minimumSize: const Size(100, 36),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty ||
                    quantityController.text.isEmpty ||
                    selectedCategory == null ||
                    selectedVendor == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                final price = double.tryParse(priceController.text) ?? 0.0;
                final quantity = int.tryParse(quantityController.text) ?? 0;

                if (price < 0 || quantity < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Price and quantity must be non-negative')),
                  );
                  return;
                }

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Edit'),
                    content: const Text('Are you sure you want to save changes to this product?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  setStateCallback(() {
                    final actualIndex = products.indexOf(model);
                    if (actualIndex != -1) {
                      products[actualIndex] = ProductModel(
                        imageProduct: model.imageProduct,
                        nameProduct: nameController.text,
                        category: selectedCategory!,
                        vendor: selectedVendor!,
                        price: price,
                        quantity: quantity,
                        imageUser: model.imageUser,
                        createdBy: model.createdBy,
                        status: isActive ? 'Active' : 'Inactive',
                      );
                    }
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(150, 36),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
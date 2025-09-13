import 'package:flutter/material.dart';
import 'package:pos_frontend/models/product_model.dart';
import 'package:file_selector/file_selector.dart';

void showAddProductDialog(
  BuildContext context, {
  required List<ProductModel> products,
  required void Function(VoidCallback) setStateCallback,
  required int totalPages,
}) {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  String? selectedCategory = 'Category 1';
  String? selectedVendor = 'Vendor 1';
  String selectedImageProduct = '';
  bool isActive = true;
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
              const Text('Add Product'),
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
                  // Product image upload section
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: selectedImageProduct.isNotEmpty
                            ? Image.network(selectedImageProduct, fit: BoxFit.cover)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 32, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('Add Image', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              const XTypeGroup typeGroup = XTypeGroup(
                                label: 'Images',
                                extensions: ['jpg', 'jpeg', 'png'],
                              );
                              final XFile? file = await openFile(
                                acceptedTypeGroups: [typeGroup],
                              );
                              if (file != null) {
                                final fileSize = await file.length();
                                if (fileSize > 2 * 1024 * 1024) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Image exceeds 2 MB limit')),
                                  );
                                  return;
                                }
                                setStateDialog(() => selectedImageProduct = file.path);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              minimumSize: const Size(120, 36),
                            ),
                            child: const Text('Upload Product Image'),
                          ),
                          const SizedBox(height: 4),
                          const Text('JPEG, PNG up to 2 MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                    title: const Text('Confirm Add'),
                    content: const Text('Are you sure you want to add this product?'),
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
                    products.add(
                      ProductModel(
                        imageProduct: selectedImageProduct.isNotEmpty ? selectedImageProduct : 'assets/images/img01.jpg',
                        nameProduct: nameController.text,
                        category: selectedCategory!,
                        vendor: selectedVendor!,
                        price: price,
                        quantity: quantity,
                        imageUser: 'assets/images/user1.jpg',
                        createdBy: 'Current User',
                        status: isActive ? 'Active' : 'Inactive',
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(150, 36),
              ),
              child: const Text('Add Product'),
            ),
          ],
        );
      },
    ),
  );
}
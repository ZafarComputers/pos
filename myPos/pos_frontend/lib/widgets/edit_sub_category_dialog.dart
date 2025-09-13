import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pos_frontend/models/sub_category_model.dart';

class EditSubCategoryDialog extends StatelessWidget {
  final SubCategoryModel model;
  final Function(SubCategoryModel) onUpdate;

  const EditSubCategoryDialog({
    super.key,
    required this.model,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final subCategoryController = TextEditingController(text: model.subCategory);
    final descriptionController = TextEditingController(text: model.description);
    String? selectedCategory = model.category;
    XFile? selectedFile;
    bool isActive = model.status == 'Active';

    const List<String> categoryOptions = ['Computers', 'Electronics', 'Books', 'Clothing'];
    const imageTypeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png'],
    );

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Edit Sub Category'),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          return SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview & change button
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Builder(
                        builder: (context) {
                          final path = selectedFile?.path ?? model.image;
                          if (path.isEmpty) {
                            return const Icon(Icons.image_not_supported, color: Colors.grey, size: 40);
                          }
                          return Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final XFile? file = await openFile(
                                acceptedTypeGroups: [imageTypeGroup],
                              );
                              if (file != null) {
                                final fileSize = await File(file.path).length();
                                if (fileSize > 2 * 1024 * 1024) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Image exceeds 2 MB limit')),
                                  );
                                  return;
                                }
                                setStateDialog(() => selectedFile = file);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to pick image: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 36),
                          ),
                          child: const Text('Change Image'),
                        ),
                        const SizedBox(height: 4),
                        const Text('JPEG, PNG up to 2 MB',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category dropdown
                const Text('Category *', style: TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: categoryOptions
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (newVal) => setStateDialog(() => selectedCategory = newVal),
                ),
                const SizedBox(height: 24),

                // SubCategory input
                const Text('Sub Category *', style: TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                TextField(
                  controller: subCategoryController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Description input
                const Text('Description *', style: TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Status toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status'),
                    Switch(
                      value: isActive,
                      onChanged: (value) => setStateDialog(() => isActive = value),
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 36),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (subCategoryController.text.isEmpty ||
                descriptionController.text.isEmpty ||
                selectedCategory == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in all required fields')),
              );
              return;
            }
            final updatedModel = SubCategoryModel(
              image: selectedFile?.path ?? model.image,
              subCategory: subCategoryController.text,
              category: selectedCategory!,
              description: descriptionController.text,
              createdDate: model.createdDate,
              status: isActive ? 'Active' : 'Inactive',
            );
            onUpdate(updatedModel);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(150, 36),
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

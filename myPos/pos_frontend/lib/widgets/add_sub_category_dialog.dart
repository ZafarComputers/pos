// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pos_frontend/models/sub_category_model.dart';

class AddSubCategoryDialog extends StatefulWidget {
  final Function(SubCategoryModel) onSave;

  const AddSubCategoryDialog({super.key, required this.onSave});

  @override
  State<AddSubCategoryDialog> createState() => _AddSubCategoryDialogState();
}

class _AddSubCategoryDialogState extends State<AddSubCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final subCategoryController = TextEditingController();
  final descriptionController = TextEditingController();

  String? selectedCategory = 'Computers';
  XFile? selectedFile;
  bool isActive = true;

  static const List<String> categoryOptions = [
    'Computers',
    'Electronics',
    'Books',
    'Clothing',
  ];

  static const imageTypeGroup = XTypeGroup(
    label: 'Images',
    extensions: ['jpg', 'jpeg', 'png'],
  );

  Future<void> _pickImage() async {
    try {
      final file = await openFile(
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
        setState(() => selectedFile = file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate() || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    final newModel = SubCategoryModel(
      image: selectedFile?.path ?? 'assets/images/img01.jpg',
      subCategory: subCategoryController.text.trim(),
      category: selectedCategory!,
      description: descriptionController.text.trim(),
      createdDate: DateTime.now().toIso8601String().split('T')[0],
      status: isActive ? 'Active' : 'Inactive',
    );
    widget.onSave(newModel);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Add Sub Category'),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image upload
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: selectedFile != null
                        ? Image.file(
                            File(selectedFile!.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 32),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: 32, color: Colors.grey),
                              SizedBox(height: 4),
                              Text('Add Image',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Upload Image'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: categoryOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
              ),
              const SizedBox(height: 16),

              // Sub Category input
              TextFormField(
                controller: subCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Sub Category *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description input
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Status toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status'),
                  Switch(
                    value: isActive,
                    onChanged: (val) => setState(() => isActive = val),
                    activeThumbColor: Colors.green,
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

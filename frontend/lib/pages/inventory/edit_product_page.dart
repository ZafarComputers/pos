import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../models/vendor.dart' as vendor;
import '../../models/category.dart';
import '../../models/sub_category.dart';
import '../../models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProductPage extends StatefulWidget {
  final Product product;
  final VoidCallback? onProductUpdated;

  const EditProductPage({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _designCodeController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _openingStockQuantityController;
  late final TextEditingController _barcodeController;

  late String _selectedStatus;
  int? _selectedVendorId;
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  List<vendor.Vendor> vendors = [];
  bool isSubmitting = false;
  File? _selectedImage;
  String? _imagePath;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing product data
    _titleController = TextEditingController(text: widget.product.title);
    _designCodeController = TextEditingController(
      text: widget.product.designCode,
    );
    _salePriceController = TextEditingController(
      text: widget.product.salePrice.toString(),
    );
    _openingStockQuantityController = TextEditingController(
      text: widget.product.openingStockQuantity.toString(),
    );
    _barcodeController = TextEditingController(text: widget.product.barcode);

    _selectedStatus = widget.product.status;
    _selectedVendorId = widget.product.vendor.id;
    _imagePath = widget.product.imagePath;

    _fetchCategories();
    _fetchVendors();
    _fetchSubCategoriesForProduct();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _designCodeController.dispose();
    _salePriceController.dispose();
    _openingStockQuantityController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchVendors() async {
    try {
      final vendorResponse = await InventoryService.getVendors();
      setState(() {
        vendors = vendorResponse.data;
        // Only set selected vendor if it exists in the fetched list
        if (_selectedVendorId != null &&
            !vendors.any((v) => v.id == _selectedVendorId)) {
          _selectedVendorId = null; // Reset if vendor no longer exists
        }
      });
    } catch (e) {
      setState(() {
        vendors = [];
        _selectedVendorId = null; // Reset on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vendors: $e'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categoryResponse = await InventoryService.getCategories();
      setState(() {
        categories = categoryResponse.data;
      });
    } catch (e) {
      setState(() {
        categories = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
      }
    }
  }

  Future<void> _fetchSubCategoriesForProduct() async {
    try {
      final subCategoryResponse = await InventoryService.getSubCategories();
      setState(() {
        subCategories = subCategoryResponse.data;
        // Find the category for the current product's sub category
        final productSubCategory = subCategories.firstWhere(
          (sc) => sc.id == int.tryParse(widget.product.subCategoryId),
          orElse: () => subCategories.first,
        );
        _selectedCategoryId = productSubCategory.categoryId;
        _selectedSubCategoryId = int.tryParse(widget.product.subCategoryId);
      });
    } catch (e) {
      setState(() {
        subCategories = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sub categories: $e'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
      }
    }
  }

  Future<void> _fetchSubCategories(int categoryId) async {
    try {
      final subCategoryResponse = await InventoryService.getSubCategories();
      setState(() {
        // Filter sub categories by selected category
        subCategories = subCategoryResponse.data
            .where((subCategory) => subCategory.categoryId == categoryId)
            .toList();
        // Reset selected sub category when category changes
        _selectedSubCategoryId = null;
      });
    } catch (e) {
      setState(() {
        subCategories = [];
        _selectedSubCategoryId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sub categories: $e'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await _saveImageLocally(imageFile);
    }
  }

  Future<void> _saveImageLocally(File imageFile) async {
    try {
      final directory = Directory(
        '${Directory.current.path}/assets/images/products',
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${directory.path}/$fileName');
      setState(() {
        _selectedImage = savedImage;
        _imagePath =
            'https://zafarcomputers.com/assets/images/products/$fileName';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final productData = {
        'title': _titleController.text,
        'design_code': _designCodeController.text,
        'image_path': _imagePath,
        'sub_category_id': _selectedSubCategoryId,
        'sale_price': double.parse(_salePriceController.text),
        'opening_stock_quantity': int.parse(
          _openingStockQuantityController.text,
        ),
        'stock_in_quantity': 0, // Required by API
        'stock_out_quantity': 0, // Required by API
        'in_stock_quantity': int.parse(
          _openingStockQuantityController.text,
        ), // Required by API
        'vendor_id': _selectedVendorId,
        'user_id': 1,
        'barcode': _barcodeController.text,
        'status': _selectedStatus,
      };

      await InventoryService.updateProduct(widget.product.id, productData);

      // Call the callback to notify parent that product was updated
      widget.onProductUpdated?.call();

      if (mounted) {
        // Show success dialog with options
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF28A745)),
                  SizedBox(width: 12),
                  Text('Product Updated Successfully!'),
                ],
              ),
              content: Text(
                'The product has been updated in your inventory. What would you like to do next?',
                style: TextStyle(color: Color(0xFF6C757D)),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to product list
                  },
                  child: Text(
                    'View Product List',
                    style: TextStyle(color: Color(0xFF0D1845)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // Stay on page to make more edits if needed
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Continue Editing'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to update product';
      if (e.toString().contains('No query results for model')) {
        errorMessage = 'Product no longer exists. It may have been deleted.';
      } else if (e.toString().contains('sub_category_id')) {
        errorMessage =
            'Invalid sub category selection. Please select a valid sub category.';
      } else if (e.toString().contains('vendor_id')) {
        errorMessage =
            'Invalid vendor selection. Please select a valid vendor.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Color(0xFFDC3545),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        backgroundColor: Color(0xFF0D1845),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D1845), Color(0xFF0A1238)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF0D1845).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Product',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Update product information in your inventory',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionHeader('Basic Information', Icons.info),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Product Title *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter product title';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _designCodeController,
                              decoration: InputDecoration(
                                labelText: 'Design Code *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter design code';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Category Section
                      _buildSectionHeader(
                        'Category & Sub Category',
                        Icons.category,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Category *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: categories.map((category) {
                                return DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(
                                    '${category.title} (${category.categoryCode})',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                  _selectedSubCategoryId =
                                      null; // Reset sub category when category changes
                                });
                                if (value != null) {
                                  _fetchSubCategories(value);
                                } else {
                                  setState(() {
                                    subCategories = [];
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedSubCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Sub Category *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: subCategories.map((subCategory) {
                                return DropdownMenuItem<int>(
                                  value: subCategory.id,
                                  child: Text(
                                    '${subCategory.title} (${subCategory.subCategoryCode})',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubCategoryId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a sub category';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: InputDecoration(
                                labelText: 'Barcode (Numerical) *',
                                hintText: 'Enter numerical barcode value',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter barcode';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Barcode must be a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(), // Empty space to maintain layout
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pricing & Stock Section
                      _buildSectionHeader(
                        'Pricing & Stock',
                        Icons.attach_money,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _salePriceController,
                              decoration: InputDecoration(
                                labelText: 'Sale Price (PKR) *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter sale price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _openingStockQuantityController,
                              decoration: InputDecoration(
                                labelText: 'Opening Stock Quantity *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter opening stock quantity';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Vendor Section
                      _buildSectionHeader('Vendor Information', Icons.business),
                      const SizedBox(height: 24),

                      DropdownButtonFormField<int>(
                        value:
                            _selectedVendorId != null &&
                                vendors.any((v) => v.id == _selectedVendorId)
                            ? _selectedVendorId
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Vendor *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: vendors.map((v) {
                          return DropdownMenuItem<int>(
                            value: v.id,
                            child: Text('${v.fullName} (${v.vendorCode})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVendorId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a vendor';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Image Section
                      _buildSectionHeader('Product Image', Icons.image),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFDEE2E6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imagePath != null && _imagePath!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          color: Color(0xFF6C757D),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load image',
                                          style: TextStyle(
                                            color: Color(0xFF6C757D),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Color(0xFF6C757D),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(color: Color(0xFF6C757D)),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.photo_library),
                        label: Text(
                          _selectedImage == null &&
                                  (_imagePath == null || _imagePath!.isEmpty)
                              ? 'Select Image'
                              : 'Change Image',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0D1845),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Section
                      _buildSectionHeader('Status', Icons.toggle_on),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['Active', 'Inactive'].map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF28A745),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text('Update Product'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF0D1845), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF343A40),
          ),
        ),
      ],
    );
  }
}

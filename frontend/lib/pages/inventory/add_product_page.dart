import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../models/vendor.dart' as vendor;
import '../../models/category.dart';
import '../../models/sub_category.dart';
import '../../models/color.dart' as colorModel;
import '../../models/size.dart' as sizeModel;
import '../../models/material.dart' as materialModel;
import '../../models/season.dart' as seasonModel;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class AddProductPage extends StatefulWidget {
  final VoidCallback? onProductAdded;

  const AddProductPage({super.key, this.onProductAdded});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _designCodeController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _openingStockQuantityController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _qrCodeController = TextEditingController();

  String _selectedStatus = 'Active';
  int? _selectedVendorId;
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  int? _selectedSizeId;
  int? _selectedColorId;
  int? _selectedMaterialId;
  int? _selectedSeasonId;

  // Variant data
  List<colorModel.Color> colors = [];
  List<sizeModel.Size> sizes = [];
  List<materialModel.Material> materials = [];
  List<seasonModel.Season> seasons = [];

  // Existing data
  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  List<vendor.Vendor> vendors = [];

  bool isSubmitting = false;
  List<File> _selectedImages = [];
  List<String> _imagePaths = [];
  String? _qrCodeData;
  String? _qrCodeImagePath;
  bool _showQrCode = false;

  @override
  void initState() {
    super.initState();
    print('🏗️ AddProductPage initialized');
    _fetchCategories();
    _fetchVendors();
    _fetchVariants();
    // Add listener to design code controller to auto-generate barcode and QR code
    _designCodeController.addListener(_generateBarcodeAndQrFromDesignCode);
  }

  @override
  void dispose() {
    _designCodeController.removeListener(_generateBarcodeAndQrFromDesignCode);
    super.dispose();
  }

  void _generateBarcodeAndQrFromDesignCode() {
    final designCode = _designCodeController.text.trim();
    if (designCode.isNotEmpty) {
      // Generate barcode by converting design code to a numerical representation
      int barcodeValue = 0;
      for (int i = 0; i < designCode.length; i++) {
        barcodeValue = barcodeValue * 31 + designCode.codeUnitAt(i);
      }
      // Ensure it's positive and within reasonable barcode length
      barcodeValue = barcodeValue.abs() % 999999999;
      // Pad with zeros to ensure consistent length
      final barcodeString = barcodeValue.toString().padLeft(9, '0');
      _barcodeController.text = barcodeString;

      // Generate QR code data
      _generateQrCode();
    } else {
      _barcodeController.text = '';
      _qrCodeData = null;
      setState(() {
        _showQrCode = false;
      });
    }
  }

  void _generateQrCode() {
    if (_titleController.text.isEmpty || _designCodeController.text.isEmpty) {
      return;
    }

    // Get selected vendor details
    vendor.Vendor? selectedVendor;
    if (_selectedVendorId != null) {
      try {
        selectedVendor = vendors.firstWhere((v) => v.id == _selectedVendorId);
      } catch (e) {
        // Vendor not found
      }
    }

    // Get selected category details
    Category? selectedCategory;
    if (_selectedCategoryId != null) {
      try {
        selectedCategory = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
        );
      } catch (e) {
        // Category not found
      }
    }

    // Get selected variants
    sizeModel.Size? selectedSize;
    colorModel.Color? selectedColor;
    materialModel.Material? selectedMaterial;

    if (_selectedSizeId != null) {
      try {
        selectedSize = sizes.firstWhere((s) => s.id == _selectedSizeId);
      } catch (e) {}
    }
    if (_selectedColorId != null) {
      try {
        selectedColor = colors.firstWhere((c) => c.id == _selectedColorId);
      } catch (e) {}
    }
    if (_selectedMaterialId != null) {
      try {
        selectedMaterial = materials.firstWhere(
          (m) => m.id == _selectedMaterialId,
        );
      } catch (e) {}
    }

    // Create comprehensive QR code data
    final qrData = {
      'vendor_info': selectedVendor != null
          ? {
              'id': selectedVendor.id,
              'name': selectedVendor.fullName,
              'code': selectedVendor.vendorCode,
              'cnic': selectedVendor.cnic,
              'address': selectedVendor.address,
              'city': selectedVendor.city.title,
            }
          : null,
      'vendor_barcode': selectedVendor?.vendorCode ?? '',
      'our_barcode': _barcodeController.text,
      'product_images': _imagePaths,
      'data_entry_date': DateTime.now().toIso8601String(),
      'buying_price': _buyingPriceController.text,
      'selling_price': _salePriceController.text,
      'product_name': _titleController.text,
      'category': selectedCategory?.title ?? '',
      'size': selectedSize?.title ?? '',
      'color': selectedColor?.title ?? '',
      'fabric': selectedMaterial?.title ?? '',
      'quantity': _openingStockQuantityController.text,
      'design_code': _designCodeController.text,
      'status': _selectedStatus,
    };

    _qrCodeData = jsonEncode(qrData);
    setState(() {
      _showQrCode = true;
    });

    // Save QR code as image file
    _saveQrCodeAsImage();
  }

  Future<void> _saveQrCodeAsImage() async {
    try {
      final directory = Directory(
        '${Directory.current.path}/assets/images/products',
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName =
          'qr_${_designCodeController.text}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      // Create QR code image data
      final qrPainter = QrPainter(
        data: _qrCodeData!,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      final picData = await qrPainter.toImageData(200);
      if (picData != null) {
        final buffer = picData.buffer.asUint8List();
        final file = File(filePath);
        await file.writeAsBytes(buffer);

        // Store QR code image path
        _qrCodeImagePath =
            'https://zafarcomputers.com/assets/images/products/$fileName';
        print('✅ QR Code saved: $_qrCodeImagePath');
      }
    } catch (e) {
      print('❌ Error saving QR code: $e');
    }
  }

  Future<void> _fetchVariants() async {
    try {
      // Fetch all variants in parallel
      final results = await Future.wait([
        InventoryService.getColors(),
        InventoryService.getSizes(),
        InventoryService.getMaterials(),
        InventoryService.getSeasons(),
      ]);

      setState(() {
        colors = (results[0] as colorModel.ColorResponse).data;
        sizes = (results[1] as sizeModel.SizeResponse).data;
        materials = (results[2] as materialModel.MaterialResponse).data;
        seasons = (results[3] as seasonModel.SeasonResponse).data;
      });
    } catch (e) {
      print('Error fetching variants: $e');
      // Set empty lists on error
      setState(() {
        colors = [];
        sizes = [];
        materials = [];
        seasons = [];
      });
    }
  }

  Future<void> _fetchVendors() async {
    try {
      final vendorResponse = await InventoryService.getVendors();
      setState(() {
        vendors = vendorResponse.data;
      });
    } catch (e) {
      setState(() {
        vendors = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load vendors: $e'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load categories: $e'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load sub categories: $e'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

      final imagePath =
          'https://zafarcomputers.com/assets/images/products/$fileName';

      setState(() {
        _selectedImages.add(savedImage);
        _imagePaths.add(imagePath);
      });

      // Regenerate QR code with new image
      _generateQrCode();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: $e'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imagePaths.removeAt(index);
    });
    // Regenerate QR code after image removal
    _generateQrCode();
  }

  Future<void> _submitForm() async {
    print('🔄 _submitForm called - starting product creation');
    print('📝 Form key current state: ${_formKey.currentState}');
    print('📝 Form validation result: ${_formKey.currentState?.validate()}');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    print('✅ Form validation passed');
    print('📊 Form data summary:');
    print('  - Title: "${_titleController.text}"');
    print('  - Design Code: "${_designCodeController.text}"');
    print('  - Category ID: $_selectedCategoryId');
    print('  - Sub Category ID: $_selectedSubCategoryId');
    print('  - Vendor ID: $_selectedVendorId');
    print('  - Sale Price: "${_salePriceController.text}"');
    print('  - Buying Price: "${_buyingPriceController.text}"');
    print('  - Opening Stock: "${_openingStockQuantityController.text}"');
    print('  - Barcode: "${_barcodeController.text}"');
    print('  - Status: $_selectedStatus');
    setState(() => isSubmitting = true);

    try {
      print('📦 Preparing product data...');
      final productData = {
        'title': _titleController.text,
        'design_code': _designCodeController.text,
        'image_paths': _imagePaths, // Changed to array
        'sub_category_id': _selectedSubCategoryId,
        'sale_price': double.parse(_salePriceController.text),
        'buying_price':
            double.tryParse(_buyingPriceController.text) ??
            0, // Added buying price
        'opening_stock_quantity': int.parse(
          _openingStockQuantityController.text,
        ),
        'stock_in_quantity': int.parse(_openingStockQuantityController.text),
        'stock_out_quantity': 0,
        'in_stock_quantity': int.parse(_openingStockQuantityController.text),
        'vendor_id': _selectedVendorId,
        'user_id': 1,
        'barcode': _barcodeController.text,
        'qr_code_data': _qrCodeData, // Added QR code data
        'qr_code_image_path': _qrCodeImagePath, // Added QR code image path
        'status': _selectedStatus,
        // Variant data
        'size_id': _selectedSizeId,
        'color_id': _selectedColorId,
        'material_id': _selectedMaterialId,
        'season_id': _selectedSeasonId,
      };

      print('📤 Product data prepared: $productData');
      print('🚀 Calling InventoryService.createProduct...');

      await InventoryService.createProduct(productData);

      print('✅ Product created successfully, calling callback...');

      // Call the callback to notify parent that product was added
      widget.onProductAdded?.call();

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
                Text('Product Added Successfully!'),
              ],
            ),
            content: Text(
              'The product has been added to your inventory. What would you like to do next?',
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
                  // Stay on page to add another product
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Add Another Product'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      String errorMessage = 'Failed to add product';
      if (e.toString().contains('sub_category_id')) {
        errorMessage =
            'Invalid sub category selection. Please select a valid sub category.';
      } else if (e.toString().contains('vendor_id')) {
        errorMessage =
            'Invalid vendor selection. Please select a valid vendor.';
      }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Product'),
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
                          Icons.add_circle,
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
                              'Add New Product',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Create a new product in your inventory',
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
                      const SizedBox(height: 16),

                      // QR Code Section
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qrCodeController,
                              decoration: InputDecoration(
                                labelText: 'QR Code (Auto-generated)',
                                hintText: 'Generated from product data',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              readOnly: true,
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_showQrCode && _qrCodeData != null)
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFDEE2E6)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: QrImageView(
                                data: _qrCodeData!,
                                size: 80,
                                backgroundColor: Colors.white,
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
                                labelText: 'Barcode (Auto-generated) *',
                                hintText: 'Generated from design code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Barcode is required';
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
                              controller: _buyingPriceController,
                              decoration: InputDecoration(
                                labelText: 'Buying Price (PKR)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
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
                      const SizedBox(height: 24),

                      // Variants Section
                      _buildSectionHeader(
                        'Variants & Attributes',
                        Icons.palette,
                      ),
                      const SizedBox(height: 24),

                      // Size and Color row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedSizeId,
                              decoration: InputDecoration(
                                labelText: 'Size',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: sizes.map((size) {
                                return DropdownMenuItem<int>(
                                  value: size.id,
                                  child: Text('${size.title}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSizeId = value;
                                });
                                _generateQrCode();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedColorId,
                              decoration: InputDecoration(
                                labelText: 'Color',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: colors.map((color) {
                                return DropdownMenuItem<int>(
                                  value: color.id,
                                  child: Text('${color.title}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedColorId = value;
                                });
                                _generateQrCode();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Material and Season row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedMaterialId,
                              decoration: InputDecoration(
                                labelText: 'Material/Fabric',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: materials.map((material) {
                                return DropdownMenuItem<int>(
                                  value: material.id,
                                  child: Text('${material.title}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMaterialId = value;
                                });
                                _generateQrCode();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedSeasonId,
                              decoration: InputDecoration(
                                labelText: 'Season',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: seasons.map((season) {
                                return DropdownMenuItem<int>(
                                  value: season.id,
                                  child: Text('${season.title}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSeasonId = value;
                                });
                                _generateQrCode();
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
                        value: _selectedVendorId,
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
                      _buildSectionHeader(
                        'Product Images (Max 3)',
                        Icons.image,
                      ),
                      const SizedBox(height: 16),

                      // Display selected images
                      if (_selectedImages.isNotEmpty)
                        Container(
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFFDEE2E6)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImages[index],
                                        fit: BoxFit.cover,
                                        width: 100,
                                        height: 100,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFDEE2E6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              color: Color(0xFF6C757D),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedImages.isEmpty
                                  ? 'No images selected'
                                  : '${_selectedImages.length}/3 images selected',
                              style: TextStyle(color: Color(0xFF6C757D)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: _selectedImages.length < 3
                            ? _pickImage
                            : null,
                        icon: Icon(Icons.photo_library),
                        label: Text(
                          _selectedImages.isEmpty
                              ? 'Select Images'
                              : 'Add More Images (${_selectedImages.length}/3)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedImages.length < 3
                              ? Color(0xFF0D1845)
                              : Colors.grey,
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
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  print('🔘 Submit button pressed');
                                  _submitForm();
                                },
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
                              : Text('Add Product'),
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

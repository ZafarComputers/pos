import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../models/product.dart';
import '../../models/vendor.dart' as vendor;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  ProductResponse? productResponse;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  final int itemsPerPage = 10;

  // Form controllers for add product dialog
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _designCodeController = TextEditingController();
  final _subCategoryIdController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _openingStockQuantityController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _selectedStatus = 'Active';
  int? _selectedVendorId;
  List<vendor.Vendor> vendors = [];
  bool isSubmitting = false;
  File? _selectedImage;
  String? _imagePath;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts({int page = 1}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await InventoryService.getProducts(
        page: page,
        limit: itemsPerPage,
      );
      setState(() {
        productResponse = response;
        currentPage = page;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String selectedCategory = 'All';
  String selectedVendor = 'All';

  void exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.white),
            SizedBox(width: 8),
            Text('Exporting to PDF... (Feature coming soon)'),
          ],
        ),
        backgroundColor: Color(0xFFDC3545),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.file_download, color: Colors.white),
            SizedBox(width: 8),
            Text('Exporting to Excel... (Feature coming soon)'),
          ],
        ),
        backgroundColor: Color(0xFF28A745),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void exportToCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.table_chart, color: Colors.white),
            SizedBox(width: 8),
            Text('Exporting to CSV... (Feature coming soon)'),
          ],
        ),
        backgroundColor: Color(0xFF17A2B8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void addNewProduct() async {
    // Reset form
    _titleController.clear();
    _designCodeController.clear();
    _subCategoryIdController.clear();
    _salePriceController.clear();
    _openingStockQuantityController.clear();
    _barcodeController.clear();
    _selectedStatus = 'Active';
    _selectedVendorId = null;
    _selectedImage = null;
    _imagePath = null;
    _localImagePath = null;

    // Fetch vendors for dropdown
    try {
      final vendorResponse = await InventoryService.getVendors();
      vendors = vendorResponse.data;
    } catch (e) {
      vendors = [];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.add_circle, color: Color(0xFF0D1845)),
                  SizedBox(width: 8),
                  Text('Add New Product'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Product Title',
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
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _designCodeController,
                        decoration: InputDecoration(
                          labelText: 'Design Code',
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
                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Image (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF343A40),
                            ),
                          ),
                          SizedBox(height: 8),
                          if (_selectedImage != null)
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFDEE2E6)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFDEE2E6)),
                                borderRadius: BorderRadius.circular(8),
                                color: Color(0xFFF8F9FA),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Color(0xFF6C757D),
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(color: Color(0xFF6C757D)),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (pickedFile != null) {
                                final imageFile = File(pickedFile.path);
                                // Save to local storage
                                try {
                                  final directory = Directory(
                                    '${Directory.current.path}/assets/images/products',
                                  );
                                  if (!await directory.exists()) {
                                    await directory.create(recursive: true);
                                  }
                                  final fileName =
                                      'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                  final savedImage = await imageFile.copy(
                                    '${directory.path}/$fileName',
                                  );
                                  setState(() {
                                    _selectedImage = savedImage;
                                    _localImagePath =
                                        'assets/images/products/$fileName';
                                    _imagePath =
                                        'https://zafarcomputers.com/assets/images/products/$fileName';
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to save image: $e'),
                                      backgroundColor: Color(0xFFDC3545),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(Icons.photo_library),
                            label: Text(
                              _selectedImage == null
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
                        ],
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _subCategoryIdController,
                        decoration: InputDecoration(
                          labelText: 'Sub Category ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter sub category ID';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _salePriceController,
                        decoration: InputDecoration(
                          labelText: 'Sale Price',
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
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _openingStockQuantityController,
                        decoration: InputDecoration(
                          labelText: 'Opening Stock Quantity',
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
                      SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedVendorId,
                        decoration: InputDecoration(
                          labelText: 'Vendor',
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
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter barcode';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF6C757D)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              isSubmitting = true;
                            });

                            try {
                              final productData = {
                                'title': _titleController.text,
                                'design_code': _designCodeController.text,
                                'image_path': _imagePath,
                                'sub_category_id': int.parse(
                                  _subCategoryIdController.text,
                                ),
                                'sale_price': double.parse(
                                  _salePriceController.text,
                                ),
                                'opening_stock_quantity': int.parse(
                                  _openingStockQuantityController.text,
                                ),
                                'vendor_id': _selectedVendorId,
                                'user_id': 1, // Hardcoded for now
                                'barcode': _barcodeController.text,
                                'status': _selectedStatus,
                              };

                              await InventoryService.createProduct(productData);

                              Navigator.of(context).pop();
                              _fetchProducts(); // Refresh the list

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Product added successfully!'),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF28A745),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Failed to add product: ${e.toString()}',
                                      ),
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
                            } finally {
                              setState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D1845),
                    foregroundColor: Colors.white,
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
              ],
            );
          },
        );
      },
    );
  }

  void viewProduct(Product product) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.inventory_2, color: Color(0xFF0D1845), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF343A40),
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D1845)),
                ),
                SizedBox(height: 16),
                Text(
                  'Fetching product details...',
                  style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF0D1845),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(24),
        );
      },
    );

    // Fetch product details asynchronously
    try {
      final productDetails = await InventoryService.getProduct(product.id);

      // Close loading dialog and show success dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.inventory_2, color: Color(0xFF0D1845), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF343A40),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Basic Information
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D1845),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow(
                            'Product ID',
                            productDetails.id.toString(),
                          ),
                          _buildDetailRow('Title', productDetails.title),
                          _buildDetailRow(
                            'Design Code',
                            productDetails.designCode,
                          ),
                          _buildDetailRow('Barcode', productDetails.barcode),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Pricing & Stock Information
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pricing & Stock',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D1845),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow(
                            'Sale Price',
                            'PKR ${productDetails.salePrice}',
                          ),
                          _buildDetailRow(
                            'Opening Stock',
                            productDetails.openingStockQuantity,
                          ),
                          _buildDetailRow(
                            'Sub Category ID',
                            productDetails.subCategoryId,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Vendor Information
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vendor Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D1845),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow(
                            'Vendor ID',
                            productDetails.vendor.id.toString(),
                          ),
                          _buildDetailRow(
                            'Vendor Name',
                            productDetails.vendor.name ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Vendor Email',
                            productDetails.vendor.email ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Vendor Phone',
                            productDetails.vendor.phone ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Vendor Address',
                            productDetails.vendor.address ?? 'N/A',
                            isMultiline: true,
                          ),
                          _buildDetailRow(
                            'Vendor Status',
                            productDetails.vendor.status,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Image Information
                    if (productDetails.imagePath != null &&
                        productDetails.imagePath!.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Image Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D1845),
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildDetailRow(
                              'Image Path',
                              productDetails.imagePath!,
                              isMultiline: true,
                            ),
                          ],
                        ),
                      ),
                    if (productDetails.imagePath != null &&
                        productDetails.imagePath!.isNotEmpty)
                      SizedBox(height: 16),

                    // Status & Timestamps
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status & Timestamps',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D1845),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildDetailRow('Status', productDetails.status),
                          _buildDetailRow(
                            'Created At',
                            _formatDateTime(productDetails.createdAt),
                          ),
                          _buildDetailRow(
                            'Updated At',
                            _formatDateTime(productDetails.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF0D1845),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.all(24),
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog and show error dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFDC3545), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF343A40),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Failed to load product details: $e',
                style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF0D1845),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.all(24),
            );
          },
        );
      }
    }
  }

  void editProduct(Product product) async {
    // Reset form controllers
    _titleController.text = product.title;
    _designCodeController.text = product.designCode;
    _subCategoryIdController.text = product.subCategoryId;
    _salePriceController.text = product.salePrice;
    _openingStockQuantityController.text = product.openingStockQuantity;
    _barcodeController.text = product.barcode;
    _selectedStatus = product.status;
    _selectedVendorId = int.tryParse(product.vendorId);
    _selectedImage = null;
    _imagePath = product.imagePath;
    _localImagePath = null;

    // Fetch vendors for dropdown
    try {
      final vendorResponse = await InventoryService.getVendors();
      vendors = vendorResponse.data;
    } catch (e) {
      vendors = [];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF28A745)),
                  SizedBox(width: 8),
                  Text('Edit Product'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
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
                      SizedBox(height: 16),
                      TextFormField(
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
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _subCategoryIdController,
                        decoration: InputDecoration(
                          labelText: 'Sub Category ID *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter sub category ID';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _salePriceController,
                        decoration: InputDecoration(
                          labelText: 'Sale Price *',
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
                      SizedBox(height: 16),
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
                      SizedBox(height: 16),
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
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Barcode *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter barcode';
                          }
                          return null;
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Image (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF343A40),
                            ),
                          ),
                          SizedBox(height: 8),
                          if (_selectedImage != null)
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFDEE2E6)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else if (_imagePath != null && _imagePath!.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFDEE2E6)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  _imagePath!.startsWith('http') &&
                                      !_imagePath!.contains(
                                        'zafarcomputers.com',
                                      )
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.inventory_2,
                                                  color: Color(0xFF6C757D),
                                                  size: 48,
                                                ),
                                      ),
                                    )
                                  : FutureBuilder<Uint8List?>(
                                      future: _loadProductImage(_imagePath!),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        } else if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        } else {
                                          return Icon(
                                            Icons.inventory_2,
                                            color: Color(0xFF6C757D),
                                            size: 48,
                                          );
                                        }
                                      },
                                    ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFDEE2E6)),
                                borderRadius: BorderRadius.circular(8),
                                color: Color(0xFFF8F9FA),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Color(0xFF6C757D),
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No image selected',
                                    style: TextStyle(color: Color(0xFF6C757D)),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (pickedFile != null) {
                                final imageFile = File(pickedFile.path);
                                // Save to local storage
                                try {
                                  final directory = Directory(
                                    '${Directory.current.path}/assets/images/products',
                                  );
                                  if (!await directory.exists()) {
                                    await directory.create(recursive: true);
                                  }
                                  final fileName =
                                      'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                  final savedImage = await imageFile.copy(
                                    '${directory.path}/$fileName',
                                  );
                                  setState(() {
                                    _selectedImage = savedImage;
                                    _localImagePath =
                                        'assets/images/products/$fileName';
                                    _imagePath =
                                        'https://zafarcomputers.com/assets/images/products/$fileName';
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to save image: $e'),
                                      backgroundColor: Color(0xFFDC3545),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(Icons.photo_library),
                            label: Text(
                              _selectedImage != null ||
                                      (_imagePath != null &&
                                          _imagePath!.isNotEmpty)
                                  ? 'Change Image'
                                  : 'Select Image',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF0D1845),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              isSubmitting = true;
                            });

                            try {
                              final productData = {
                                'title': _titleController.text,
                                'design_code': _designCodeController.text,
                                'image_path': _imagePath,
                                'sub_category_id': int.parse(
                                  _subCategoryIdController.text,
                                ),
                                'sale_price': double.parse(
                                  _salePriceController.text,
                                ),
                                'opening_stock_quantity': int.parse(
                                  _openingStockQuantityController.text,
                                ),
                                'vendor_id': _selectedVendorId,
                                'user_id': 1, // Hardcoded for now
                                'barcode': _barcodeController.text,
                                'status': _selectedStatus,
                              };

                              await InventoryService.updateProduct(
                                product.id,
                                productData,
                              );

                              Navigator.of(context).pop();
                              _fetchProducts(
                                page: currentPage,
                              ); // Refresh the list

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Product updated successfully!'),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF28A745),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Failed to update product: ${e.toString()}',
                                      ),
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
                            } finally {
                              setState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28A745),
                    foregroundColor: Colors.white,
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
              ],
            );
          },
        );
      },
    );
  }

  void deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Color(0xFFDC3545)),
              SizedBox(width: 8),
              Text('Delete Product'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${product.title}"?\n\nThis action cannot be undone.',
            style: TextStyle(color: Color(0xFF6C757D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF6C757D))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await InventoryService.deleteProduct(product.id);

                  // Refresh the product list on the same page
                  await _fetchProducts(page: currentPage);

                  // Check if current page is now empty and we need to go to previous page
                  if ((productResponse?.data.isEmpty ?? true) &&
                      currentPage > 1) {
                    await _fetchProducts(page: currentPage - 1);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Product "${product.title}" deleted successfully',
                          ),
                        ],
                      ),
                      backgroundColor: Color(0xFF28A745),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Failed to delete product: ${e.toString()}'),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDC3545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D1845)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading products...',
                style: TextStyle(color: Color(0xFF6C757D), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Color(0xFFDC3545), size: 64),
                SizedBox(height: 16),
                Text(
                  'Failed to load products',
                  style: TextStyle(
                    color: Color(0xFFDC3545),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchProducts,
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D1845),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header
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
                      Icons.inventory_2,
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
                          'Products',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Manage your complete product inventory and stock levels',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: exportToPDF,
                          icon: Icon(Icons.picture_as_pdf, size: 16),
                          label: Text('PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFDC3545),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: exportToExcel,
                          icon: Icon(Icons.file_download, size: 16),
                          label: Text('Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF28A745),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: ElevatedButton.icon(
                          onPressed: exportToCSV,
                          icon: Icon(Icons.table_chart, size: 16),
                          label: Text('CSV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF17A2B8),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: addNewProduct,
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Add Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF0D1845),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Enhanced Filters Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_list, color: Color(0xFF6C757D)),
                      SizedBox(width: 8),
                      Text(
                        'Filters & Search',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF343A40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Search products by name, code, or vendor...',
                              hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF6C757D),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFDEE2E6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFDEE2E6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFF0D1845),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 16,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFF0D1845),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                items:
                                    ['All', 'Computers', 'Electronics', 'Shoe']
                                        .map(
                                          (category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                color: Color(0xFF343A40),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCategory = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Vendor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedVendor,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFF0D1845),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                items: ['All', 'Lenovo', 'Beats', 'Nike']
                                    .map(
                                      (brand) => DropdownMenuItem(
                                        value: brand,
                                        child: Text(
                                          brand,
                                          style: TextStyle(
                                            color: Color(0xFF343A40),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedVendor = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Enhanced Table Section
            Container(
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
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, color: Color(0xFF6C757D)),
                        SizedBox(width: 8),
                        Text(
                          'Product Inventory',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${productResponse?.meta.total ?? 0} Products',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Color(0xFFF8F9FA),
                      ),
                      dataRowColor: MaterialStateProperty.resolveWith<Color>((
                        Set<MaterialState> states,
                      ) {
                        if (states.contains(MaterialState.selected)) {
                          return Color(0xFF0D1845).withOpacity(0.1);
                        }
                        return Colors.white;
                      }),
                      columns: const [
                        DataColumn(label: Text('Product Code')),
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Created By')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: (productResponse?.data ?? []).map((product) {
                        final quantity =
                            int.tryParse(product.openingStockQuantity) ?? 0;
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.designCode,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D1845),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Color(0xFFDEE2E6),
                                        ),
                                      ),
                                      child:
                                          product.imagePath != null &&
                                              product.imagePath!.isNotEmpty
                                          ? (product.imagePath!.startsWith(
                                                      'http',
                                                    ) &&
                                                    !product.imagePath!
                                                        .contains(
                                                          'zafarcomputers.com',
                                                        ))
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      product.imagePath!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Icon(
                                                            Icons.inventory_2,
                                                            color: Color(
                                                              0xFF6C757D,
                                                            ),
                                                            size: 24,
                                                          ),
                                                    ),
                                                  )
                                                : FutureBuilder<Uint8List?>(
                                                    future: _loadProductImage(
                                                      product.imagePath!,
                                                    ),
                                                    builder: (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        );
                                                      } else if (snapshot
                                                              .hasData &&
                                                          snapshot.data !=
                                                              null) {
                                                        return ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.memory(
                                                            snapshot.data!,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        );
                                                      } else {
                                                        return Icon(
                                                          Icons.inventory_2,
                                                          color: Color(
                                                            0xFF6C757D,
                                                          ),
                                                          size: 24,
                                                        );
                                                      }
                                                    },
                                                  )
                                          : Icon(
                                              Icons.inventory_2,
                                              color: Color(0xFF6C757D),
                                              size: 24,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            product.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF343A40),
                                            ),
                                          ),
                                          Text(
                                            'Code: ${product.designCode}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6C757D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    product.subCategoryId,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Category ${product.subCategoryId}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                product.vendor.name ??
                                    'Vendor ${product.vendorId}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF343A40),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                'PKR ${product.salePrice}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF28A745),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Pc',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6C757D),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: quantity < 50
                                      ? Color(0xFFFFF3CD)
                                      : Color(0xFFD4EDDA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  quantity.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: quantity < 50
                                        ? Color(0xFF856404)
                                        : Color(0xFF155724),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                'N/A',
                                style: TextStyle(color: Color(0xFF6C757D)),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => viewProduct(product),
                                    icon: Icon(
                                      Icons.visibility,
                                      color: Color(0xFF17A2B8),
                                      size: 16,
                                    ),
                                    tooltip: 'View Details',
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => editProduct(product),
                                    icon: Icon(
                                      Icons.edit,
                                      color: Color(0xFF28A745),
                                      size: 16,
                                    ),
                                    tooltip: 'Edit Product',
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => deleteProduct(product),
                                    icon: Icon(
                                      Icons.delete,
                                      color: Color(0xFFDC3545),
                                      size: 16,
                                    ),
                                    tooltip: 'Delete Product',
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Pagination
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: currentPage > 1
                        ? () => _fetchProducts(page: currentPage - 1)
                        : null,
                    icon: Icon(Icons.chevron_left),
                    label: Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: currentPage > 1
                          ? Color(0xFF0D1845)
                          : Color(0xFF6C757D),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ..._buildPageButtons(),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed:
                        currentPage < (productResponse?.meta.lastPage ?? 1)
                        ? () => _fetchProducts(page: currentPage + 1)
                        : null,
                    icon: Icon(Icons.chevron_right),
                    label: Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          currentPage < (productResponse?.meta.lastPage ?? 1)
                          ? Color(0xFF0D1845)
                          : Color(0xFF6C757D),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Computers':
        return Color(0xFF007BFF);
      case 'Electronics':
        return Color(0xFF28A745);
      case 'Shoe':
        return Color(0xFFFD7E14);
      default:
        return Color(0xFF6C757D);
    }
  }

  Future<Uint8List?> _loadProductImage(String imagePath) async {
    try {
      // Extract filename from any path format
      String filename;
      if (imagePath.contains('/')) {
        // If it contains slashes, take the last part after the last /
        filename = imagePath.split('/').last;
      } else {
        // Use as is if no slashes
        filename = imagePath;
      }

      // Remove any query parameters
      if (filename.contains('?')) {
        filename = filename.split('?').first;
      }

      print('�️ Extracted filename: $filename from path: $imagePath');

      // Check if file exists in local products directory
      final file = File('assets/images/products/$filename');
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        // Try to load from network if it's a valid URL
        if (imagePath.startsWith('http')) {
          // For now, return null to show default icon
          // In future, could implement network loading with caching
        }
      }
    } catch (e) {
      // Error loading image
    }
    return null;
  }

  List<Widget> _buildPageButtons() {
    if (productResponse?.meta == null) {
      return [];
    }

    final meta = productResponse!.meta;
    final totalPages = meta.lastPage;
    final current = meta.currentPage;

    // Show max 5 page buttons centered around current page
    const maxButtons = 5;
    final halfRange = maxButtons ~/ 2; // 2

    // Calculate desired start and end
    int startPage = (current - halfRange).clamp(1, totalPages);
    int endPage = (startPage + maxButtons - 1).clamp(1, totalPages);

    // If endPage exceeds totalPages, adjust startPage
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = (endPage - maxButtons + 1).clamp(1, totalPages);
    }

    List<Widget> buttons = [];

    for (int i = startPage; i <= endPage; i++) {
      buttons.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal: 1),
          child: ElevatedButton(
            onPressed: i == current ? null : () => _fetchProducts(page: i),
            style: ElevatedButton.styleFrom(
              backgroundColor: i == current ? Color(0xFF0D1845) : Colors.white,
              foregroundColor: i == current ? Colors.white : Color(0xFF6C757D),
              elevation: i == current ? 2 : 0,
              side: i == current ? null : BorderSide(color: Color(0xFFDEE2E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size(32, 32),
            ),
            child: Text(
              i.toString(),
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C757D),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Color(0xFF343A40),
                fontSize: 12,
                fontFamily:
                    label == 'Barcode' ||
                        label == 'Product ID' ||
                        label.contains('ID')
                    ? 'monospace'
                    : null,
              ),
              maxLines: isMultiline ? null : 1,
              overflow: isMultiline
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}

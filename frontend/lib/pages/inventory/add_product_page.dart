import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isProductInfoExpanded = true;
  bool _isPricingStocksExpanded = false;
  bool _isImagesExpanded = false;
  bool _isCustomFieldsExpanded = false;

  // Form controllers
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountValueController =
      TextEditingController();
  final TextEditingController _quantityAlertController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedStore = 'Store 1';
  String _selectedWarehouse = 'Warehouse 1';
  String _selectedSellingType = 'Single';
  String _selectedCategory = 'Computers';
  String _selectedSubCategory = 'Laptop';
  String _selectedBrand = 'Lenovo';
  String _selectedUnit = 'Pc';
  String _selectedBarcodeSymbology = 'CODE128';
  String _selectedProductType = 'Single Product';
  String _selectedTaxType = 'Inclusive';
  String _selectedDiscountType = 'Percentage';

  @override
  Widget build(BuildContext context) {
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
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Product',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill in the details below to add a new product to your inventory',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Product Information Section
                  _buildEnhancedExpandableSection(
                    title: 'Product Information',
                    subtitle: 'Basic product details and categorization',
                    icon: Icons.info_outline,
                    color: Color(0xFF007BFF),
                    isExpanded: _isProductInfoExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isProductInfoExpanded = expanded;
                      });
                    },
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Store',
                              value: _selectedStore,
                              items: ['Store 1', 'Store 2', 'Store 3'],
                              icon: Icons.store,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStore = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Warehouse',
                              value: _selectedWarehouse,
                              items: [
                                'Warehouse 1',
                                'Warehouse 2',
                                'Warehouse 3',
                              ],
                              icon: Icons.warehouse,
                              onChanged: (value) {
                                setState(() {
                                  _selectedWarehouse = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Product Name',
                              controller: _productNameController,
                              icon: Icons.inventory_2,
                              hintText: 'Enter product name',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Slug',
                              controller: _slugController,
                              icon: Icons.link,
                              hintText: 'product-slug-url',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'SKU',
                              controller: _skuController,
                              icon: Icons.tag,
                              hintText: 'Unique product code',
                              suffix: Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.refresh, size: 16),
                                  label: Text('Generate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF28A745),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Selling Type',
                              value: _selectedSellingType,
                              items: ['Single', 'Variable'],
                              icon: Icons.sell,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSellingType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Category',
                              value: _selectedCategory,
                              items: [
                                'Computers',
                                'Electronics',
                                'Shoe',
                                'Furniture',
                              ],
                              icon: Icons.category,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Sub Category',
                              value: _selectedSubCategory,
                              items: [
                                'Laptop',
                                'Desktop',
                                'Sneakers',
                                'Formals',
                              ],
                              icon: Icons.subdirectory_arrow_right,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubCategory = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Brand',
                              value: _selectedBrand,
                              items: ['Lenovo', 'Beats', 'Nike', 'Apple'],
                              icon: Icons.branding_watermark,
                              onChanged: (value) {
                                setState(() {
                                  _selectedBrand = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Unit',
                              value: _selectedUnit,
                              items: ['Pc', 'Kg', 'Liter', 'Box'],
                              icon: Icons.scale,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Barcode Symbology',
                              value: _selectedBarcodeSymbology,
                              items: ['CODE128', 'CODE39', 'EAN13', 'UPC'],
                              icon: Icons.qr_code,
                              onChanged: (value) {
                                setState(() {
                                  _selectedBarcodeSymbology = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Barcode',
                              controller: TextEditingController(),
                              icon: Icons.qr_code_scanner,
                              hintText: 'Barcode value',
                              suffix: Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Icon(Icons.qr_code, size: 16),
                                  label: Text('Generate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF17A2B8),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildEnhancedTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        icon: Icons.description,
                        maxLines: 4,
                        hintText:
                            'Enter product description (maximum 60 words)',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Pricing & Stocks Section
                  _buildEnhancedExpandableSection(
                    title: 'Pricing & Stocks',
                    subtitle: 'Set pricing, taxes, and inventory details',
                    icon: Icons.attach_money,
                    color: Color(0xFF28A745),
                    isExpanded: _isPricingStocksExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isPricingStocksExpanded = expanded;
                      });
                    },
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Product Type',
                              value: _selectedProductType,
                              items: ['Single Product', 'Variable Product'],
                              icon: Icons.inventory,
                              onChanged: (value) {
                                setState(() {
                                  _selectedProductType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Quantity',
                              controller: _quantityController,
                              icon: Icons.inventory_2,
                              keyboardType: TextInputType.number,
                              hintText: 'Enter quantity',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Price',
                              controller: _priceController,
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              hintText: 'Enter price',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Tax Type',
                              value: _selectedTaxType,
                              items: ['Inclusive', 'Exclusive'],
                              icon: Icons.account_balance,
                              onChanged: (value) {
                                setState(() {
                                  _selectedTaxType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Tax Rate',
                              value: '5%',
                              items: ['5%', '10%', '15%', '20%'],
                              icon: Icons.percent,
                              onChanged: (value) {},
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Discount Type',
                              value: _selectedDiscountType,
                              items: ['Percentage', 'Fixed'],
                              icon: Icons.discount,
                              onChanged: (value) {
                                setState(() {
                                  _selectedDiscountType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Discount Value',
                              controller: _discountValueController,
                              icon: Icons.local_offer,
                              keyboardType: TextInputType.number,
                              hintText: 'Enter discount value',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Quantity Alert',
                              controller: _quantityAlertController,
                              icon: Icons.warning,
                              keyboardType: TextInputType.number,
                              hintText: 'Low stock alert threshold',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Images Section
                  _buildEnhancedExpandableSection(
                    title: 'Product Images',
                    subtitle: 'Upload product photos and media',
                    icon: Icons.photo_camera,
                    color: Color(0xFFFD7E14),
                    isExpanded: _isImagesExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isImagesExpanded = expanded;
                      });
                    },
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFDEE2E6)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: Color(0xFF6C757D),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Drag & Drop Images Here',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF343A40),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'or click to browse files (PNG, JPG, JPEG up to 5MB each)',
                              style: TextStyle(
                                color: Color(0xFF6C757D),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.file_upload),
                              label: Text('Choose Files'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0D1845),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildEnhancedImagePlaceholder(),
                          const SizedBox(width: 20),
                          _buildEnhancedImagePlaceholder(),
                          const SizedBox(width: 20),
                          _buildEnhancedImagePlaceholder(),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Custom Fields Section
                  _buildEnhancedExpandableSection(
                    title: 'Additional Details',
                    subtitle: 'Warranty, manufacturer, and expiry information',
                    icon: Icons.settings,
                    color: Color(0xFF6F42C1),
                    isExpanded: _isCustomFieldsExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isCustomFieldsExpanded = expanded;
                      });
                    },
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedDropdownField(
                              label: 'Warranty',
                              value: '1 Year',
                              items: [
                                '6 Months',
                                '1 Year',
                                '2 Years',
                                '3 Years',
                              ],
                              icon: Icons.security,
                              onChanged: (value) {},
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Manufacturer',
                              controller: TextEditingController(),
                              icon: Icons.factory,
                              hintText: 'Enter manufacturer name',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Expiry Date',
                              controller: TextEditingController(),
                              icon: Icons.calendar_today,
                              hintText: 'Select expiry date',
                              suffix: Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF0D1845),
                                  ),
                                  onPressed: () {},
                                  style: IconButton.styleFrom(
                                    backgroundColor: Color(0xFFF8F9FA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEnhancedTextField(
                              label: 'Manufactured Date',
                              controller: TextEditingController(),
                              icon: Icons.event,
                              hintText: 'Select manufactured date',
                              suffix: Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.event,
                                    color: Color(0xFF0D1845),
                                  ),
                                  onPressed: () {},
                                  style: IconButton.styleFrom(
                                    backgroundColor: Color(0xFFF8F9FA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Enhanced Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.close),
                          label: Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF6C757D)),
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Product created successfully!',
                                  ),
                                  backgroundColor: Color(0xFF28A745),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.save),
                          label: Text('Create Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0D1845),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Color(0xFF0D1845).withOpacity(0.3),
                          ),
                        ),
                      ],
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

  Widget _buildEnhancedExpandableSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required Function(bool) onExpansionChanged,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF343A40),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
                  ),
                ],
              ),
            ],
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Color(0xFF6C757D)),
            const SizedBox(width: 8),
            Text(
              label,
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
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Color(0xFFADB5BD)),
              suffixIcon: suffix,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFDEE2E6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFDEE2E6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF0D1845), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (label.contains('*') && (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Color(0xFF6C757D)),
            const SizedBox(width: 8),
            Text(
              label,
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
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFDEE2E6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFDEE2E6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF0D1845), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item, style: TextStyle(color: Color(0xFF343A40))),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedImagePlaceholder() {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Color(0xFFDEE2E6),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate,
                size: 24,
                color: Color(0xFF6C757D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Image',
              style: TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

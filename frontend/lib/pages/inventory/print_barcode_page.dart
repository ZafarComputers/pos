import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PrintBarcodePage extends StatefulWidget {
  const PrintBarcodePage({super.key});

  @override
  State<PrintBarcodePage> createState() => _PrintBarcodePageState();
}

class _PrintBarcodePageState extends State<PrintBarcodePage> {
  final List<Map<String, dynamic>> products = [
    {
      'code': 'PT001',
      'name': 'Lenovo IdeaPad 3',
      'category': 'Computers',
      'vendor': 'Lenovo',
      'price': '\$600',
      'unit': 'Pc',
      'qty': 100,
      'createdBy': 'James Kirwin',
      'selected': false,
    },
    {
      'code': 'PT002',
      'name': 'Beats Pro',
      'category': 'Electronics',
      'vendor': 'Beats',
      'price': '\$160',
      'unit': 'Pc',
      'qty': 140,
      'createdBy': 'Francis Chang',
      'selected': false,
    },
    {
      'code': 'PT003',
      'name': 'Nike Jordan',
      'category': 'Shoe',
      'vendor': 'Nike',
      'price': '\$110',
      'unit': 'Pc',
      'qty': 300,
      'createdBy': 'Antonio Engle',
      'selected': false,
    },
    {
      'code': 'PT004',
      'name': 'Dell XPS 13',
      'category': 'Computers',
      'vendor': 'Dell',
      'price': '\$1200',
      'unit': 'Pc',
      'qty': 50,
      'createdBy': 'Sarah Johnson',
      'selected': false,
    },
    {
      'code': 'PT005',
      'name': 'Apple AirPods',
      'category': 'Electronics',
      'vendor': 'Apple',
      'price': '\$199',
      'unit': 'Pc',
      'qty': 200,
      'createdBy': 'Mike Davis',
      'selected': false,
    },
  ];

  String selectedCategory = 'All';
  String selectedVendor = 'All';
  bool selectAll = false;

  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      for (var product in products) {
        product['selected'] = selectAll;
      }
    });
  }

  void toggleProductSelection(int index) {
    setState(() {
      products[index]['selected'] = !products[index]['selected'];
      selectAll = products.every((product) => product['selected']);
    });
  }

  List<Map<String, dynamic>> getSelectedProducts() {
    return products.where((product) => product['selected'] == true).toList();
  }

  void generateAndPrintBarcode() {
    final selectedProducts = getSelectedProducts();
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one product to generate barcode',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show barcode generation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate Barcodes'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${selectedProducts.length} product(s) selected'),
                const SizedBox(height: 16),
                const Text(
                  'Barcode generation and printing feature coming soon!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Generating barcodes for ${selectedProducts.length} products...',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D1845),
              ),
              child: const Text('Generate & Print'),
            ),
          ],
        );
      },
    );
  }

  void generateQRCode() {
    final selectedProducts = getSelectedProducts();
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one product to generate QR code',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show QR code generation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate QR Codes'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${selectedProducts.length} product(s) selected'),
                const SizedBox(height: 16),
                // Show QR code preview for first selected product
                if (selectedProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          selectedProducts[0]['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        QrImageView(
                          data: selectedProducts[0]['code'],
                          version: QrVersions.auto,
                          size: 120.0,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code: ${selectedProducts[0]['code']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'QR code generation feature coming soon!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Generating QR codes for ${selectedProducts.length} products...',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D1845),
              ),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

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
                  colors: [Color(0xFF17A2B8), Color(0xFF20B2AA)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF17A2B8).withOpacity(0.3),
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
                      Icons.qr_code_scanner,
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
                          'Print Barcode',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate barcodes and QR codes for your products',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: generateAndPrintBarcode,
                    icon: Icon(Icons.qr_code_scanner, size: 16),
                    label: Text('Generate & Print Barcode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF0D1845),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
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
            const SizedBox(height: 24),

            // Enhanced Filters Section
            Container(
              padding: const EdgeInsets.all(16),
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
                      Icon(
                        Icons.filter_list,
                        color: Color(0xFF6C757D),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Search & Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF343A40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
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
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Search products...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF6C757D),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFFDEE2E6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFFDEE2E6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFF17A2B8),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFF17A2B8),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  isDense: true,
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
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedCategory = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Vendor',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDEE2E6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFF17A2B8),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                                items:
                                    [
                                          'All',
                                          'Lenovo',
                                          'Beats',
                                          'Nike',
                                          'Dell',
                                          'Apple',
                                        ]
                                        .map(
                                          (brand) => DropdownMenuItem(
                                            value: brand,
                                            child: Text(
                                              brand,
                                              style: TextStyle(
                                                color: Color(0xFF343A40),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedVendor = value;
                                    });
                                  }
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
            const SizedBox(height: 24),

            // Selection Controls
            Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  Checkbox(
                    value: selectAll,
                    onChanged: (value) => toggleSelectAll(),
                    activeColor: Color(0xFF17A2B8),
                  ),
                  Text(
                    'Select All',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF343A40),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF1976D2),
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${getSelectedProducts().length} product(s) selected',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Enhanced Products Table
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
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_chart,
                          color: Color(0xFF17A2B8),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Products List',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${products.length} Products',
                                style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
                          return Color(0xFF17A2B8).withOpacity(0.1);
                        }
                        return Colors.white;
                      }),
                      columns: const [
                        DataColumn(label: Text('Select')),
                        DataColumn(label: Text('Product Code')),
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Qty')),
                      ],
                      rows: products.asMap().entries.map((entry) {
                        final index = entry.key;
                        final product = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(
                              Checkbox(
                                value: product['selected'],
                                onChanged: (value) =>
                                    toggleProductSelection(index),
                                activeColor: Color(0xFF17A2B8),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  product['code'],
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF17A2B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Color(0xFFDEE2E6),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: Color(0xFF6C757D),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF343A40),
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            product['code'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF6C757D),
                                              fontFamily: 'monospace',
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
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(product['category']),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  product['category'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                product['vendor'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF343A40),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                product['price'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF28A745),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  product['unit'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6C757D),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: product['qty'] < 50
                                      ? Color(0xFFFFF3CD)
                                      : Color(0xFFD4EDDA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product['qty'].toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: product['qty'] < 50
                                        ? Color(0xFF856404)
                                        : Color(0xFF155724),
                                    fontSize: 11,
                                  ),
                                ),
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

            const SizedBox(height: 24),

            // Generate QR Code Button at Bottom
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: generateQRCode,
                  icon: Icon(Icons.qr_code, size: 18),
                  label: Text('Generate QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Computers':
        return Color(0xFF17A2B8);
      case 'Electronics':
        return Color(0xFF28A745);
      case 'Shoe':
        return Color(0xFFDC3545);
      default:
        return Color(0xFF6C757D);
    }
  }
}

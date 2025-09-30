import 'package:flutter/material.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
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
    },
    // Add more sample data as needed
  ];

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

  void addNewProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.add_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Add Product feature coming soon!'),
          ],
        ),
        backgroundColor: Color(0xFF0D1845),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void viewProduct(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.visibility, color: Colors.white),
            SizedBox(width: 8),
            Text('Viewing product: ${product['name']}'),
          ],
        ),
        backgroundColor: Color(0xFF17A2B8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void editProduct(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text('Editing product: ${product['name']}'),
          ],
        ),
        backgroundColor: Color(0xFF28A745),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void deleteProduct(Map<String, dynamic> product) {
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
            'Are you sure you want to delete "${product['name']}"?\n\nThis action cannot be undone.',
            style: TextStyle(color: Color(0xFF6C757D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF6C757D))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Product "${product['name']}" deleted successfully',
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFFDC3545),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
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
                            '${products.length} Products',
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
                      rows: products.map((product) {
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
                                  product['code'],
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
                                      child: Icon(
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
                                            product['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF343A40),
                                            ),
                                          ),
                                          Text(
                                            'Code: ${product['code']}',
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
                                  color: _getCategoryColor(product['category']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  product['category'],
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
                                product['vendor'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF343A40),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                product['price'],
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
                                  product['unit'],
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
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                product['createdBy'],
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
                    onPressed: () {},
                    icon: Icon(Icons.chevron_left),
                    label: Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF6C757D),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  for (int i = 1; i <= 5; i++)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: i == 1
                              ? Color(0xFF0D1845)
                              : Colors.white,
                          foregroundColor: i == 1
                              ? Colors.white
                              : Color(0xFF6C757D),
                          elevation: i == 1 ? 2 : 0,
                          side: i == 1
                              ? null
                              : BorderSide(color: Color(0xFFDEE2E6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          i.toString(),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chevron_right),
                    label: Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF6C757D),
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
}

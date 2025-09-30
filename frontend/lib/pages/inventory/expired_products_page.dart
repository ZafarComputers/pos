import 'package:flutter/material.dart';

class ExpiredProductsPage extends StatefulWidget {
  const ExpiredProductsPage({super.key});

  @override
  State<ExpiredProductsPage> createState() => _ExpiredProductsPageState();
}

class _ExpiredProductsPageState extends State<ExpiredProductsPage> {
  final List<Map<String, dynamic>> expiredProducts = [
    {
      'code': 'PT001',
      'name': 'Lenovo 3rd Generation',
      'createdDate': '24 Dec 2024',
      'expiredDate': '20 Dec 2026',
    },
    {
      'code': 'PT002',
      'name': 'Beats Pro',
      'createdDate': '10 Dec 2024',
      'expiredDate': '07 Dec 2026',
    },
    {
      'code': 'PT003',
      'name': 'Nike Jordan',
      'createdDate': '27 Nov 2024',
      'expiredDate': '20 Nov 2026',
    },
    {
      'code': 'PT004',
      'name': 'Apple Series 5 Watch',
      'createdDate': '18 Nov 2024',
      'expiredDate': '15 Nov 2026',
    },
    {
      'code': 'PT005',
      'name': 'Amazon Echo Dot',
      'createdDate': '06 Nov 2024',
      'expiredDate': '04 Nov 2026',
    },
    {
      'code': 'PT006',
      'name': 'Sanford Chair Sofa',
      'createdDate': '25 Oct 2024',
      'expiredDate': '20 Oct 2026',
    },
    {
      'code': 'PT007',
      'name': 'Red Premium Satchel',
      'createdDate': '14 Oct 2024',
      'expiredDate': '10 Oct 2026',
    },
    {
      'code': 'PT008',
      'name': 'Iphone 14 Pro',
      'createdDate': '03 Oct 2024',
      'expiredDate': '01 Oct 2026',
    },
    {
      'code': 'PT009',
      'name': 'Gaming Chair',
      'createdDate': '20 Sep 2024',
      'expiredDate': '16 Sep 2026',
    },
    {
      'code': 'PT010',
      'name': 'Borealis Backpack',
      'createdDate': '10 Sep 2024',
      'expiredDate': '06 Sep 2026',
    },
  ];

  String selectedProduct = 'All';
  String selectedSortBy = 'Last 7 Days';

  void exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.white),
            SizedBox(width: 8),
            Text('Exporting expired products to PDF... (Feature coming soon)'),
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
            Text(
              'Exporting expired products to Excel... (Feature coming soon)',
            ),
          ],
        ),
        backgroundColor: Color(0xFF28A745),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void viewExpiredProduct(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.visibility, color: Colors.white),
            SizedBox(width: 8),
            Text('Viewing expired product: ${product['name']}'),
          ],
        ),
        backgroundColor: Color(0xFF17A2B8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void editExpiredProduct(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text('Editing expired product: ${product['name']}'),
          ],
        ),
        backgroundColor: Color(0xFF28A745),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void deleteExpiredProduct(Map<String, dynamic> product) {
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
              Text('Delete Expired Product'),
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
                          'Expired product "${product['name']}" deleted successfully',
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
                  colors: [Color(0xFFDC3545), Color(0xFFB02A37)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFDC3545).withOpacity(0.3),
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
                      Icons.warning_amber,
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
                          'Expired Products',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor and manage products that have reached their expiration dates',
                          style: TextStyle(
                            fontSize: 12,
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
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFFDC3545),
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
                          onPressed: exportToExcel,
                          icon: Icon(Icons.file_download, size: 16),
                          label: Text('Excel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF28A745),
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
                    ],
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
                      Icon(Icons.filter_list, color: Color(0xFF6C757D)),
                      SizedBox(width: 8),
                      Text(
                        'Filters & Sorting',
                        style: TextStyle(
                          fontSize: 18,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Product',
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
                                value: selectedProduct,
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
                                      color: Color(0xFFDC3545),
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
                                          'Lenovo 3rd Generation',
                                          'Beats Pro',
                                          'Nike Jordan',
                                          'Apple Series 5 Watch',
                                        ]
                                        .map(
                                          (product) => DropdownMenuItem(
                                            value: product,
                                            child: Text(
                                              product,
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
                                      selectedProduct = value;
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
                                  Icons.sort,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Sort By',
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
                                value: selectedSortBy,
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
                                      color: Color(0xFFDC3545),
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
                                          'Last 7 Days',
                                          'Last 30 Days',
                                          'Last 3 Months',
                                          'Last 6 Months',
                                          'Last Year',
                                        ]
                                        .map(
                                          (sort) => DropdownMenuItem(
                                            value: sort,
                                            child: Text(
                                              'Sort By: $sort',
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
                                      selectedSortBy = value;
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Color(0xFFDC3545),
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Expired Products List',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF343A40),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Color(0xFF856404),
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${expiredProducts.length} Expired',
                                style: TextStyle(
                                  color: Color(0xFF856404),
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
                          return Color(0xFFDC3545).withOpacity(0.1);
                        }
                        return Colors.white;
                      }),
                      columns: const [
                        DataColumn(label: Text('Product Code')),
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Created Date')),
                        DataColumn(label: Text('Expired Date')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: expiredProducts.map((product) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product['code'],
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFDC3545),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 160,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFF3CD),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Color(0xFFFFEAA7),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.warning_amber,
                                        color: Color(0xFF856404),
                                        size: 18,
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
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            product['code'],
                                            style: TextStyle(
                                              fontSize: 11,
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
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE7F3FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product['createdDate'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0066CC),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFF3CD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product['expiredDate'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF856404),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8D7DA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      color: Color(0xFFDC3545),
                                      size: 12,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Expired',
                                      style: TextStyle(
                                        color: Color(0xFFDC3545),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        viewExpiredProduct(product),
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
                                    onPressed: () =>
                                        editExpiredProduct(product),
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
                                    onPressed: () =>
                                        deleteExpiredProduct(product),
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
            const SizedBox(height: 24),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chevron_left, size: 16),
                    label: Text('Previous', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF6C757D),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  for (int i = 1; i <= 3; i++)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: i == 1
                              ? Color(0xFFDC3545)
                              : Colors.white,
                          foregroundColor: i == 1
                              ? Colors.white
                              : Color(0xFF6C757D),
                          elevation: i == 1 ? 2 : 0,
                          side: i == 1
                              ? null
                              : BorderSide(color: Color(0xFFDEE2E6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size(36, 36),
                        ),
                        child: Text(
                          i.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chevron_right, size: 16),
                    label: Text('Next', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF6C757D),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
}

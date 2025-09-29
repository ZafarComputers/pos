import 'package:flutter/material.dart';

class VendorsPage extends StatefulWidget {
  const VendorsPage({super.key});

  @override
  State<VendorsPage> createState() => _VendorsPageState();
}

class _VendorsPageState extends State<VendorsPage> {
  final List<Map<String, dynamic>> vendors = [
    {
      'code': 'SU001',
      'name': 'Apex Computers',
      'email': 'apexcomputers@example.com',
      'phone': '+15964712634',
      'country': 'Germany',
      'status': 'Active',
    },
    {
      'code': 'SU002',
      'name': 'Beats Headphones',
      'email': 'beatsheadphone@example.com',
      'phone': '+16372895190',
      'country': 'Japan',
      'status': 'Active',
    },
    {
      'code': 'SU003',
      'name': 'Dazzle Shoes',
      'email': 'dazzleshoes@example.com',
      'phone': '+17589201739',
      'country': 'USA',
      'status': 'Active',
    },
    {
      'code': 'SU004',
      'name': 'Best Accessories',
      'email': 'bestaccessories@example.com',
      'phone': '+18934092467',
      'country': 'Austria',
      'status': 'Active',
    },
    {
      'code': 'SU005',
      'name': 'A-Z Store',
      'email': 'a2zstore@example.com',
      'phone': '+12568749035',
      'country': 'Turkey',
      'status': 'Active',
    },
    {
      'code': 'SU006',
      'name': 'Hatimi Hardwares',
      'email': 'hatimihardware@example.com',
      'phone': '+19054674627',
      'country': 'Mexico',
      'status': 'Active',
    },
    {
      'code': 'SU007',
      'name': 'Aesthetic Bags',
      'email': 'aestheticbags@example.com',
      'phone': '+18943670365',
      'country': 'France',
      'status': 'Active',
    },
    {
      'code': 'SU008',
      'name': 'Alpha Mobiles',
      'email': 'alphamobiles@example.com',
      'phone': '+16473894103',
      'country': 'Greece',
      'status': 'Active',
    },
    {
      'code': 'SU009',
      'name': 'Sigma Chairs',
      'email': 'sigmachair@example.com',
      'phone': '+17590274536',
      'country': 'Italy',
      'status': 'Active',
    },
    {
      'code': 'SU010',
      'name': 'Zenith Bags',
      'email': 'zenithbags@example.com',
      'phone': '+12564098473',
      'country': 'China',
      'status': 'Active',
    },
  ];

  String selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  void exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting vendors to PDF... (Feature coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting vendors to Excel... (Feature coming soon)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void addNewVendor() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Vendor feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void viewVendor(Map<String, dynamic> vendor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing vendor: ${vendor['name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void editVendor(Map<String, dynamic> vendor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing vendor: ${vendor['name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void deleteVendor(Map<String, dynamic> vendor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Vendor'),
          content: Text('Are you sure you want to delete "${vendor['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Vendor "${vendor['name']}" deleted successfully',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFDC3545)),
              ),
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
                      Icons.business,
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
                          'Vendors',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your supplier relationships and vendor information',
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
                      ElevatedButton.icon(
                        onPressed: addNewVendor,
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Add Vendor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0D1845),
                          foregroundColor: Colors.white,
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
                            controller: _searchController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Search vendors...',
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
                                  Icons.filter_alt,
                                  size: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Status',
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
                                value: selectedStatus,
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
                                items: ['All', 'Active', 'Inactive']
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status,
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
                                      selectedStatus = value;
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
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business,
                          color: Color(0xFF17A2B8),
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Vendors List',
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
                                Icons.business_center,
                                color: Color(0xFF1976D2),
                                size: 12,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '${vendors.length} Vendors',
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
                        DataColumn(label: Text('Image')),
                        DataColumn(label: Text('Vendor Code')),
                        DataColumn(label: Text('Vendor Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Country')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: vendors.map((vendor) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _getVendorColor(vendor['country']),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Color(0xFFDEE2E6)),
                                ),
                                child: Icon(
                                  Icons.business,
                                  color: Colors.white,
                                  size: 16,
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
                                  vendor['code'],
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
                                width: 140,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      vendor['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF343A40),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      vendor['code'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF6C757D),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 160,
                                child: Text(
                                  vendor['email'],
                                  style: TextStyle(
                                    color: Color(0xFF6C757D),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                  color: Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  vendor['phone'],
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1976D2),
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
                                  color: _getCountryColor(vendor['country']),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  vendor['country'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
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
                                  color: vendor['status'] == 'Active'
                                      ? Color(0xFFD4EDDA)
                                      : Color(0xFFF8D7DA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      vendor['status'] == 'Active'
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: vendor['status'] == 'Active'
                                          ? Color(0xFF28A745)
                                          : Color(0xFFDC3545),
                                      size: 10,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      vendor['status'],
                                      style: TextStyle(
                                        color: vendor['status'] == 'Active'
                                            ? Color(0xFF155724)
                                            : Color(0xFF721C24),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                width: 32,
                                height: 32,
                                child: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'view':
                                        viewVendor(vendor);
                                        break;
                                      case 'edit':
                                        editVendor(vendor);
                                        break;
                                      case 'delete':
                                        deleteVendor(vendor);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.visibility,
                                            color: Color(0xFF17A2B8),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'View Details',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: Color(0xFF28A745),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Edit Vendor',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Color(0xFFDC3545),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Delete Vendor',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.more_vert,
                                      color: Color(0xFF6C757D),
                                      size: 14,
                                    ),
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

            // Enhanced Pagination
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chevron_left, size: 14),
                    label: Text('Previous', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF6C757D),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (int i = 1; i <= 3; i++)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: i == 1
                              ? Color(0xFF17A2B8)
                              : Colors.white,
                          foregroundColor: i == 1
                              ? Colors.white
                              : Color(0xFF6C757D),
                          elevation: i == 1 ? 2 : 0,
                          side: i == 1
                              ? null
                              : BorderSide(color: Color(0xFFDEE2E6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size(32, 32),
                        ),
                        child: Text(
                          i.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chevron_right, size: 14),
                    label: Text('Next', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF6C757D),
                      elevation: 0,
                      side: BorderSide(color: Color(0xFFDEE2E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
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

  Color _getVendorColor(String country) {
    switch (country.toLowerCase()) {
      case 'germany':
        return Color(0xFF17A2B8);
      case 'japan':
        return Color(0xFF28A745);
      case 'usa':
        return Color(0xFFDC3545);
      case 'austria':
        return Color(0xFF6F42C1);
      case 'turkey':
        return Color(0xFFFFA500);
      case 'mexico':
        return Color(0xFF20B2AA);
      case 'france':
        return Color(0xFF8A2BE2);
      case 'greece':
        return Color(0xFF32CD32);
      case 'italy':
        return Color(0xFFFF6347);
      case 'china':
        return Color(0xFF4169E1);
      default:
        return Color(0xFF6C757D);
    }
  }

  Color _getCountryColor(String country) {
    switch (country.toLowerCase()) {
      case 'germany':
        return Color(0xFF17A2B8);
      case 'japan':
        return Color(0xFF28A745);
      case 'usa':
        return Color(0xFFDC3545);
      case 'austria':
        return Color(0xFF6F42C1);
      case 'turkey':
        return Color(0xFFFFA500);
      case 'mexico':
        return Color(0xFF20B2AA);
      case 'france':
        return Color(0xFF8A2BE2);
      case 'greece':
        return Color(0xFF32CD32);
      case 'italy':
        return Color(0xFFFF6347);
      case 'china':
        return Color(0xFF4169E1);
      default:
        return Color(0xFF6C757D);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/inventory_service.dart';
import '../../models/vendor.dart' as vendor;
import '../../models/product.dart';

class CreatePurchaseReturnPage extends StatefulWidget {
  const CreatePurchaseReturnPage({super.key});

  @override
  State<CreatePurchaseReturnPage> createState() =>
      _CreatePurchaseReturnPageState();
}

class _CreatePurchaseReturnPageState extends State<CreatePurchaseReturnPage> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _orderTaxController = TextEditingController();
  final _orderDiscountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int? _selectedVendorId;
  String _selectedStatus = 'Pending'; // Default status
  List<vendor.Vendor> vendors = [];
  List<Product> products = [];
  List<PurchaseReturnItem> purchaseReturnItems = [];
  bool isSubmitting = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchVendors();
    _fetchProducts();
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

  Future<void> _fetchProducts() async {
    try {
      final productResponse = await InventoryService.getProducts();
      setState(() {
        products = productResponse.data;
      });
    } catch (e) {
      setState(() {
        products = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products: $e'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
    }
  }

  void _addPurchaseReturnItem() {
    setState(() {
      purchaseReturnItems.add(PurchaseReturnItem());
    });
  }

  void _removePurchaseReturnItem(int index) {
    setState(() {
      purchaseReturnItems.removeAt(index);
    });
  }

  void _updatePurchaseReturnItem(int index, PurchaseReturnItem item) {
    setState(() {
      purchaseReturnItems[index] = item;
    });
  }

  double _calculateGrandTotal() {
    double subtotal = 0;
    for (var item in purchaseReturnItems) {
      subtotal += item.totalCost;
    }

    double orderTax = double.tryParse(_orderTaxController.text) ?? 0;
    double orderDiscount = double.tryParse(_orderDiscountController.text) ?? 0;

    double totalAfterOrderTax = subtotal + (subtotal * orderTax / 100);
    return totalAfterOrderTax - orderDiscount;
  }

  double _calculateSubtotal() {
    double subtotal = 0;
    for (var item in purchaseReturnItems) {
      subtotal += item.totalCost;
    }
    return subtotal;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF0D1845),
              onPrimary: Colors.white,
              onSurface: Color(0xFF343A40),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (purchaseReturnItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one product to return'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
      return;
    }

    // Validate all purchase return items
    for (int i = 0; i < purchaseReturnItems.length; i++) {
      if (purchaseReturnItems[i].productId == null ||
          purchaseReturnItems[i].quantity <= 0 ||
          purchaseReturnItems[i].purchasePrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please complete all product details for item ${i + 1}',
            ),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
        return;
      }
    }

    setState(() => isSubmitting = true);

    try {
      // TODO: Call API to create purchase return
      // await PurchaseReturnService.createPurchaseReturn(purchaseReturnData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Purchase return created successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF28A745),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _referenceController.clear();
      _orderTaxController.clear();
      _orderDiscountController.clear();
      _notesController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedVendorId = null;
        purchaseReturnItems.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Failed to create purchase return: $e')),
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

  List<PurchaseReturnItem> _getPaginatedItems() {
    int startIndex = _currentPage * 10;
    int endIndex = startIndex + 10;
    if (endIndex > purchaseReturnItems.length) {
      endIndex = purchaseReturnItems.length;
    }
    return purchaseReturnItems.sublist(startIndex, endIndex);
  }

  int _getTotalPages() {
    return (purchaseReturnItems.length / 10).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text('Create Purchase Return Order'),
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
                          Icons.assignment_return,
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
                              'Create Purchase Return Order',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Return products from existing purchases',
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
                            child: DropdownButtonFormField<int>(
                              value: _selectedVendorId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Vendor Name *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: vendors.isEmpty
                                  ? [
                                      DropdownMenuItem<int>(
                                        value: null,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Loading vendors...'),
                                          ],
                                        ),
                                      ),
                                    ]
                                  : vendors.map((v) {
                                      return DropdownMenuItem<int>(
                                        value: v.id,
                                        child: Text(
                                          '${v.fullName} (${v.vendorCode})',
                                        ),
                                      );
                                    }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedVendorId = value;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a vendor';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_selectedDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: 'Reference ID *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter reference ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Products Section
                      _buildSectionHeader(
                        'Products to Return',
                        Icons.inventory,
                      ),
                      const SizedBox(height: 24),

                      // Add Product Button
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addPurchaseReturnItem,
                            icon: Icon(Icons.add),
                            label: Text('Add Product'),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${purchaseReturnItems.length} products added',
                                  style: TextStyle(
                                    color: Color(0xFF6C757D),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (purchaseReturnItems.any(
                                  (item) =>
                                      item.productId == null ||
                                      item.quantity <= 0 ||
                                      item.purchasePrice <= 0,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '⚠️ Some products are incomplete. Please fill in all required fields.',
                                      style: TextStyle(
                                        color: Color(0xFF856404),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Products Table
                      if (purchaseReturnItems.isNotEmpty) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF0D1845),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_return,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Return Items',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Table Content
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                    Color(0xFFF8F9FA),
                                  ),
                                  dataRowColor:
                                      MaterialStateProperty.resolveWith<Color>((
                                        Set<MaterialState> states,
                                      ) {
                                        if (states.contains(
                                          MaterialState.selected,
                                        )) {
                                          return Color(
                                            0xFF0D1845,
                                          ).withOpacity(0.1);
                                        }
                                        return Colors.white;
                                      }),
                                  columnSpacing: 24.0,
                                  dataRowMinHeight: 60.0,
                                  dataRowMaxHeight: 80.0,
                                  headingRowHeight: 50.0,
                                  columns: const [
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Product',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Purchase Price',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Discount',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Tax (%)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Tax Amount',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Unit Cost',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Total Cost',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Pending Payment',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Text(
                                          'Actions',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: _getPaginatedItems().map((item) {
                                    int index = purchaseReturnItems.indexOf(
                                      item,
                                    );
                                    bool isIncomplete =
                                        item.productId == null ||
                                        item.quantity <= 0 ||
                                        item.purchasePrice <= 0;

                                    return DataRow(
                                      color:
                                          MaterialStateProperty.resolveWith<
                                            Color
                                          >((states) {
                                            if (isIncomplete) {
                                              return Color(
                                                0xFFFFF3CD,
                                              ); // Light yellow for incomplete items
                                            }
                                            if (states.contains(
                                              MaterialState.selected,
                                            )) {
                                              return Color(
                                                0xFF0D1845,
                                              ).withOpacity(0.1);
                                            }
                                            return Colors.white;
                                          }),
                                      cells: [
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 220,
                                              child: DropdownButtonFormField<int>(
                                                value: item.productId,
                                                isExpanded: true,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  filled: true,
                                                  fillColor: isIncomplete
                                                      ? Color(0xFFFFF3CD)
                                                      : Colors.white,
                                                ),
                                                items: products.map((product) {
                                                  return DropdownMenuItem<int>(
                                                    value: product.id,
                                                    child: Container(
                                                      constraints:
                                                          BoxConstraints(
                                                            maxWidth: 180,
                                                          ),
                                                      child: Text(
                                                        '${product.title} (${product.designCode})',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    PurchaseReturnItem
                                                    updatedItem = item.copyWith(
                                                      productId: value,
                                                    );
                                                    _updatePurchaseReturnItem(
                                                      index,
                                                      updatedItem,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 80,
                                              child: TextFormField(
                                                initialValue: item.quantity
                                                    .toString(),
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  filled: true,
                                                  fillColor: isIncomplete
                                                      ? Color(0xFFFFF3CD)
                                                      : Colors.white,
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                style: TextStyle(fontSize: 14),
                                                onChanged: (value) {
                                                  int qty =
                                                      int.tryParse(value) ?? 0;
                                                  PurchaseReturnItem
                                                  updatedItem = item.copyWith(
                                                    quantity: qty,
                                                  );
                                                  _updatePurchaseReturnItem(
                                                    index,
                                                    updatedItem,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 120,
                                              child: TextFormField(
                                                initialValue: item.purchasePrice
                                                    .toString(),
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  filled: true,
                                                  fillColor: isIncomplete
                                                      ? Color(0xFFFFF3CD)
                                                      : Colors.white,
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                style: TextStyle(fontSize: 14),
                                                onChanged: (value) {
                                                  double price =
                                                      double.tryParse(value) ??
                                                      0;
                                                  PurchaseReturnItem
                                                  updatedItem = item.copyWith(
                                                    purchasePrice: price,
                                                  );
                                                  _updatePurchaseReturnItem(
                                                    index,
                                                    updatedItem,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 100,
                                              child: TextFormField(
                                                initialValue: item.discount
                                                    .toString(),
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  filled: true,
                                                  fillColor: isIncomplete
                                                      ? Color(0xFFFFF3CD)
                                                      : Colors.white,
                                                  suffixText: '%',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                style: TextStyle(fontSize: 14),
                                                onChanged: (value) {
                                                  double discount =
                                                      double.tryParse(value) ??
                                                      0;
                                                  PurchaseReturnItem
                                                  updatedItem = item.copyWith(
                                                    discount: discount,
                                                  );
                                                  _updatePurchaseReturnItem(
                                                    index,
                                                    updatedItem,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 80,
                                              child: TextFormField(
                                                initialValue: item.taxPercentage
                                                    .toString(),
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  filled: true,
                                                  fillColor: isIncomplete
                                                      ? Color(0xFFFFF3CD)
                                                      : Colors.white,
                                                  suffixText: '%',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                style: TextStyle(fontSize: 14),
                                                onChanged: (value) {
                                                  double tax =
                                                      double.tryParse(value) ??
                                                      0;
                                                  PurchaseReturnItem
                                                  updatedItem = item.copyWith(
                                                    taxPercentage: tax,
                                                  );
                                                  _updatePurchaseReturnItem(
                                                    index,
                                                    updatedItem,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: 100,
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Rs. ${item.taxAmount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF1976D2),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: 100,
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Rs. ${item.unitCost.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF28A745),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: 120,
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Rs. ${(item.unitCost * item.quantity).toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF343A40),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 120,
                                              child: TextFormField(
                                                initialValue: item
                                                    .pendingPayment
                                                    .toString(),
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  filled: true,
                                                  fillColor: isIncomplete
                                                      ? Color(0xFFFFF3CD)
                                                      : Colors.white,
                                                  prefixText: 'Rs. ',
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                style: TextStyle(fontSize: 14),
                                                onChanged: (value) {
                                                  double pending =
                                                      double.tryParse(value) ??
                                                      0;
                                                  PurchaseReturnItem
                                                  updatedItem = item.copyWith(
                                                    pendingPayment: pending,
                                                  );
                                                  _updatePurchaseReturnItem(
                                                    index,
                                                    updatedItem,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (isIncomplete)
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF856404),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Incomplete',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                SizedBox(width: 8),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Color(0xFFDC3545),
                                                    size: 20,
                                                  ),
                                                  onPressed: () =>
                                                      _removePurchaseReturnItem(
                                                        index,
                                                      ),
                                                  tooltip: 'Remove Product',
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Color(
                                                      0xFFF8F9FA,
                                                    ),
                                                    padding: EdgeInsets.all(8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),

                              // Pagination
                              if (purchaseReturnItems.length > 10) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 0
                                            ? () =>
                                                  setState(() => _currentPage--)
                                            : null,
                                      ),
                                      Text(
                                        'Page ${_currentPage + 1} of ${_getTotalPages()}',
                                        style: TextStyle(
                                          color: Color(0xFF6C757D),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.chevron_right),
                                        onPressed:
                                            _currentPage < _getTotalPages() - 1
                                            ? () =>
                                                  setState(() => _currentPage++)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (purchaseReturnItems.isNotEmpty) ...[
                        const SizedBox(height: 32),

                        // Order Summary Section
                        _buildSectionHeader('Return Summary', Icons.receipt),
                        const SizedBox(height: 24),

                        // Order Tax and Discount Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _orderTaxController,
                                decoration: InputDecoration(
                                  labelText: 'Order Tax (%)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _orderDiscountController,
                                decoration: InputDecoration(
                                  labelText: 'Order Discount (Rs.)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Status Selector
                        Container(
                          width: double.infinity,
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: ['Pending', 'Completed'].map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Row(
                                  children: [
                                    Icon(
                                      status == 'Completed'
                                          ? Icons.check_circle_rounded
                                          : Icons.pending,
                                      color: status == 'Completed'
                                          ? Color(0xFF28A745)
                                          : Color(0xFFFFA726),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: Color(0xFF343A40),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Subtotal
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Subtotal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${_calculateSubtotal().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Grand Total
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFE8F5E8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFF28A745)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Return Amount',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF28A745),
                                ),
                              ),
                              Text(
                                'Rs. ${_calculateGrandTotal().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF28A745),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description Box
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 32),
                      ],

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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text('Create Purchase Return'),
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

class PurchaseReturnItem {
  int? productId;
  int quantity;
  double purchasePrice;
  double discount;
  double taxPercentage;
  double pendingPayment;
  String description;

  PurchaseReturnItem({
    this.productId,
    this.quantity = 1,
    this.purchasePrice = 0,
    this.discount = 0,
    this.taxPercentage = 0,
    this.pendingPayment = 0,
    this.description = '',
  });

  double get taxAmount {
    double priceAfterDiscount = purchasePrice * (1 - discount / 100);
    return priceAfterDiscount * (taxPercentage / 100);
  }

  double get unitCost {
    double priceAfterDiscount = purchasePrice * (1 - discount / 100);
    return priceAfterDiscount + taxAmount;
  }

  double get totalCost {
    return unitCost * quantity;
  }

  String get productName {
    // This will be set when product is selected from dropdown
    return description.isNotEmpty ? description : 'Select Product';
  }

  PurchaseReturnItem copyWith({
    int? productId,
    int? quantity,
    double? purchasePrice,
    double? discount,
    double? taxPercentage,
    double? pendingPayment,
    String? description,
  }) {
    return PurchaseReturnItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      discount: discount ?? this.discount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      pendingPayment: pendingPayment ?? this.pendingPayment,
      description: description ?? this.description,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../services/sales_service.dart';

class PosPaymentMethods extends StatefulWidget {
  final double totalAmount;
  final Function(String, double) onPaymentComplete;
  final List<Map<String, dynamic>> orderItems;
  final Map<String, dynamic>? selectedCustomer;

  const PosPaymentMethods({
    super.key,
    required this.totalAmount,
    required this.onPaymentComplete,
    required this.orderItems,
    this.selectedCustomer,
  });

  @override
  State<PosPaymentMethods> createState() => _PosPaymentMethodsState();
}

class _PosPaymentMethodsState extends State<PosPaymentMethods> {
  Future<void> _processPosPayment({
    required int paymentModeId,
    required int transactionTypeId,
    required double paidAmount,
  }) async {
    print('🔄 POS PAYMENT: Starting payment processing...');
    print(
      '📊 Payment Details: Mode=$paymentModeId, Type=$transactionTypeId, Amount=$paidAmount',
    );

    try {
      // Prepare order details
      final details = widget.orderItems.map((item) {
        return {
          'product_id': item['id'],
          'qty': item['quantity'] ?? 1,
          'sale_price': item['price'] ?? 0.0,
        };
      }).toList();

      // Get customer ID (default to 2 for walk-in customers if no customer selected)
      final customerId = widget.selectedCustomer != null
          ? 2
          : 2; // TODO: Get actual customer ID

      // Current date in YYYY-MM-DD format
      final invDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      print('📦 Order Details: ${details.length} items');
      print('👤 Customer ID: $customerId');
      print('📅 Invoice Date: $invDate');

      // Call POS API
      print('🌐 Calling POS API...');
      await SalesService.createPosInvoice(
        invDate: invDate,
        customerId: customerId,
        tax: 0.0,
        discPer: 0.0,
        discAmount: 0.0,
        invAmount: widget.totalAmount,
        paid: paidAmount,
        paymentModeId: paymentModeId,
        transactionTypeId: transactionTypeId,
        details: details,
      );

      print('✅ POS API call successful!');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment processed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Call the original onPaymentComplete callback
      widget.onPaymentComplete(
        _getPaymentMethodName(paymentModeId),
        paidAmount,
      );
    } catch (e) {
      print('❌ POS PAYMENT ERROR: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPaymentMethodName(int paymentModeId) {
    switch (paymentModeId) {
      case 1:
        return 'Cash';
      case 2:
        return 'Bank';
      case 3:
        return 'Credit';
      default:
        return 'Unknown';
    }
  }

  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPaymentButton(
                'Cash',
                Icons.money,
                Colors.green,
                () => _showCashPaymentDialog(),
              ),
              const SizedBox(width: 12),
              _buildPaymentButton(
                'Credit',
                Icons.credit_card,
                Colors.blue,
                () => _showCreditPaymentDialog(),
              ),
              const SizedBox(width: 12),
              _buildPaymentButton(
                'Bank',
                Icons.account_balance,
                Colors.orange,
                () => _showBankPaymentDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showCreditPaymentDialog() {
    // Mock credit customers data - in real app this would come from API
    final List<Map<String, dynamic>> creditCustomers = [
      {
        'id': '1',
        'name': 'John Doe',
        'code': 'CC001',
        'totalPending': 2500.0,
        'paymentRecords': [
          {
            'invoiceNumber': 'INV-001',
            'date': DateTime(2025, 10, 1),
            'time': '10:30 AM',
            'totalAmount': 1000.0,
            'pendingAmount': 400.0,
          },
          {
            'invoiceNumber': 'INV-002',
            'date': DateTime(2025, 10, 5),
            'time': '2:15 PM',
            'totalAmount': 1500.0,
            'pendingAmount': 600.0,
          },
        ],
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'code': 'CC002',
        'totalPending': 1800.0,
        'paymentRecords': [
          {
            'invoiceNumber': 'INV-003',
            'date': DateTime(2025, 10, 3),
            'time': '11:45 AM',
            'totalAmount': 800.0,
            'pendingAmount': 300.0,
          },
          {
            'invoiceNumber': 'INV-004',
            'date': DateTime(2025, 10, 7),
            'time': '4:20 PM',
            'totalAmount': 1000.0,
            'pendingAmount': 200.0,
          },
        ],
      },
    ];

    String? selectedCustomerId;
    Map<String, dynamic>? selectedCustomer;
    double paidAmount = 0.0;
    String paymentMethod = 'Cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 900,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D1845), Color(0xFF1A237E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
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
                          Icons.credit_card,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Credit Payment',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Process credit payment for customer',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Selection
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: DropdownButtonFormField<String>(
                            value: selectedCustomerId,
                            decoration: InputDecoration(
                              labelText: 'Select Credit Customer',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: creditCustomers.map((customer) {
                              return DropdownMenuItem<String>(
                                value: customer['id'],
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Color(0xFF0D1845),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${customer['name']} (${customer['code']})',
                                      style: const TextStyle(
                                        color: Color(0xFF343A40),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCustomerId = value;
                                selectedCustomer = creditCustomers.firstWhere(
                                  (customer) => customer['id'] == value,
                                );
                              });
                            },
                          ),
                        ),

                        // Existing Credit Records
                        if (selectedCustomer != null &&
                            selectedCustomer!['paymentRecords'] != null &&
                            selectedCustomer!['paymentRecords'].isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Existing Credit Records',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF343A40),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        200, // Limit height to prevent overflow
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: DataTable(
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                              Color(0xFFF8F9FA),
                                            ),
                                        dataRowMinHeight: 45, // Reduced from 50
                                        dataRowMaxHeight: 60,
                                        columnSpacing: 20,
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              'Invoice #',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Date',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Time',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Total Amount',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Pending Amount',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: selectedCustomer!['paymentRecords']
                                            .map<DataRow>((record) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      record['invoiceNumber'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      DateFormat(
                                                        'dd/MM/yyyy',
                                                      ).format(record['date']),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(record['time']),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      'Rs${record['totalAmount'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF28A745,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      'Rs${record['pendingAmount'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFFDC3545,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // New Payment Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFFDEE2E6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.payment,
                                    color: Color(0xFF0D1845),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'New Payment Entry',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF343A40),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Total Bill Amount
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Color(0xFFDEE2E6)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Bill Amount:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF343A40),
                                      ),
                                    ),
                                    Text(
                                      'Rs${widget.totalAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF28A745),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Paid Amount and Pending Amount Row
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: paidAmount.toString(),
                                      decoration: InputDecoration(
                                        labelText: 'Paid Amount',
                                        prefixText: 'Rs',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          paidAmount =
                                              double.tryParse(value) ?? 0.0;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Color(0xFFDEE2E6),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Pending Amount:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF343A40),
                                            ),
                                          ),
                                          Text(
                                            'Rs${(widget.totalAmount - paidAmount).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  paidAmount >=
                                                      widget.totalAmount
                                                  ? Color(0xFF28A745)
                                                  : Color(0xFFDC3545),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Payment Method Selection
                              DropdownButtonFormField<String>(
                                value: paymentMethod,
                                decoration: InputDecoration(
                                  labelText: 'Payment Method',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: ['Cash'].map((method) {
                                  return DropdownMenuItem<String>(
                                    value: method,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.money,
                                          color: Color(0xFF28A745),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(method),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    paymentMethod = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    selectedCustomerId != null &&
                                        paidAmount > 0 &&
                                        paidAmount <= widget.totalAmount
                                    ? () async {
                                        await _processPosPayment(
                                          paymentModeId: 3, // Credit customer
                                          transactionTypeId:
                                              2, // Credit transaction
                                          paidAmount: paidAmount,
                                        );
                                        Navigator.of(context).pop();
                                        _showPrintDialog();
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D1845),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Process Credit Payment'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCashPaymentDialog() {
    double receivedAmount = 0.0;
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cash Payment'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Amount: Rs${widget.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Paying Amount',
                    prefixText: 'Rs',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      receivedAmount = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (receivedAmount >= widget.totalAmount)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Change / Balance:',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs${(receivedAmount - widget.totalAmount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: receivedAmount >= widget.totalAmount
                  ? () async {
                      await _processPosPayment(
                        paymentModeId: 1, // Cash
                        transactionTypeId: 1, // Cash transaction
                        paidAmount: receivedAmount,
                      );
                      Navigator.of(context).pop();
                      _showPrintDialog();
                    }
                  : null,
              child: const Text('Complete Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBankPaymentDialog() {
    double receivedAmount = 0.0;
    String selectedReceiverAccount = 'JazzCash'; // Default receiver account
    String selectedSenderBank = 'JazzCash'; // Default sender bank
    final TextEditingController amountController = TextEditingController();
    final TextEditingController senderBankNameController =
        TextEditingController();
    final TextEditingController accountHolderNameController =
        TextEditingController();
    final TextEditingController accountNumberController =
        TextEditingController();

    // Mock receiver accounts - in real app this would come from API (Bank pages)
    final List<String> receiverAccounts = [
      'JazzCash',
      'EasyPaisa',
      'Bank Account',
    ];

    // Sender bank options
    final List<String> senderBanks = ['JazzCash', 'EasyPaisa', 'Bank'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.95,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D1845), Color(0xFF1A237E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
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
                          Icons.account_balance,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Transfer Payment',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Process bank transfer payment details',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Amount Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDEE2E6)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF343A40),
                                ),
                              ),
                              Text(
                                'Rs${widget.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF28A745),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Receiver's Account Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDEE2E6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: const Color(0xFF0D1845),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Receiver\'s Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF343A40),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Receiver Account Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedReceiverAccount,
                                decoration: InputDecoration(
                                  labelText: 'Select Receiver Account',
                                  hintText:
                                      'Choose the account receiving payment',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: receiverAccounts.map((account) {
                                  return DropdownMenuItem<String>(
                                    value: account,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getAccountIcon(account),
                                          color: const Color(0xFF0D1845),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(account),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedReceiverAccount = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sender's Bank Details Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDEE2E6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.send,
                                    color: const Color(0xFF0D1845),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sender\'s Bank Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF343A40),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Sender's Bank Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedSenderBank,
                                decoration: InputDecoration(
                                  labelText: 'Sender\'s Bank',
                                  hintText:
                                      'Select the bank sending the payment',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: senderBanks.map((bank) {
                                  return DropdownMenuItem<String>(
                                    value: bank,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getBankIcon(bank),
                                          color: const Color(0xFF0D1845),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(bank),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedSenderBank = value!;
                                    // Clear bank name if not "Bank"
                                    if (value != 'Bank') {
                                      senderBankNameController.clear();
                                    }
                                  });
                                },
                              ),

                              const SizedBox(height: 16),

                              // Sender's Bank Name (only show if "Bank" is selected)
                              if (selectedSenderBank == 'Bank')
                                TextField(
                                  controller: senderBankNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Sender\'s Bank Name',
                                    hintText: 'Enter the full bank name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.business),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),

                              if (selectedSenderBank == 'Bank')
                                const SizedBox(height: 16),

                              // Account Holder's Name
                              TextField(
                                controller: accountHolderNameController,
                                decoration: InputDecoration(
                                  labelText: 'Account Holder\'s Name',
                                  hintText: 'Enter the account holder name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.person),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Account Number
                              TextField(
                                controller: accountNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Account Number',
                                  hintText: 'Enter the account number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.account_box),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Paid Amount
                              TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Paid Amount',
                                  hintText: 'Enter payment amount',
                                  prefixText: 'Rs',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.payment),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    receivedAmount =
                                        double.tryParse(value) ?? 0.0;
                                  });
                                },
                              ),

                              const SizedBox(height: 16),

                              // Balance Display
                              if (receivedAmount >= widget.totalAmount)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Balance Amount:',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Rs${(receivedAmount - widget.totalAmount).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    receivedAmount >= widget.totalAmount &&
                                        accountHolderNameController.text
                                            .trim()
                                            .isNotEmpty &&
                                        accountNumberController.text
                                            .trim()
                                            .isNotEmpty &&
                                        (selectedSenderBank != 'Bank' ||
                                            senderBankNameController.text
                                                .trim()
                                                .isNotEmpty)
                                    ? () async {
                                        await _processPosPayment(
                                          paymentModeId: 2, // Bank
                                          transactionTypeId:
                                              3, // Bank transaction
                                          paidAmount: receivedAmount,
                                        );
                                        Navigator.of(context).pop();
                                        _showPrintDialog();
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D1845),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Complete Bank Payment'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(String account) {
    switch (account) {
      case 'JazzCash':
        return Icons.phone_android;
      case 'EasyPaisa':
        return Icons.mobile_friendly;
      case 'Bank Account':
        return Icons.account_balance;
      default:
        return Icons.account_balance_wallet;
    }
  }

  IconData _getBankIcon(String bank) {
    switch (bank) {
      case 'JazzCash':
        return Icons.phone_android;
      case 'EasyPaisa':
        return Icons.mobile_friendly;
      case 'Bank':
        return Icons.business;
      default:
        return Icons.account_balance;
    }
  }

  Future<void> _generateInvoicePdf() async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    // Add a page to the document
    final PdfPage page = document.pages.add();

    // Create PDF graphics for the page
    final PdfGraphics graphics = page.graphics;

    // Set page size and margins
    final Size pageSize = page.getClientSize();
    const double margin = 50;
    final Rect bounds = Rect.fromLTWH(
      margin,
      margin,
      pageSize.width - 2 * margin,
      pageSize.height - 2 * margin,
    );

    // Define fonts
    final PdfFont titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      24,
      style: PdfFontStyle.bold,
    );
    final PdfFont headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      16,
      style: PdfFontStyle.bold,
    );
    final PdfFont normalFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfFont boldFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      12,
      style: PdfFontStyle.bold,
    );

    // Header - Company Name
    graphics.drawString(
      'POS INVOICE',
      titleFont,
      bounds: Rect.fromLTWH(bounds.left, bounds.top, bounds.width, 30),
    );

    // Invoice details
    double yPosition = bounds.top + 50;
    graphics.drawString(
      'Invoice Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
      normalFont,
      bounds: Rect.fromLTWH(bounds.left, yPosition, bounds.width, 20),
    );
    yPosition += 25;
    graphics.drawString(
      'Invoice Time: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      normalFont,
      bounds: Rect.fromLTWH(bounds.left, yPosition, bounds.width, 20),
    );
    yPosition += 25;
    graphics.drawString(
      'Customer: ${widget.selectedCustomer?['name'] ?? 'Walk-in Customer'}',
      normalFont,
      bounds: Rect.fromLTWH(bounds.left, yPosition, bounds.width, 20),
    );

    // Items header
    yPosition += 50;
    graphics.drawString(
      'Items',
      headerFont,
      bounds: Rect.fromLTWH(bounds.left, yPosition, bounds.width, 20),
    );
    yPosition += 30;

    // Draw table header
    graphics.drawString(
      'Product',
      boldFont,
      bounds: Rect.fromLTWH(bounds.left, yPosition, 200, 20),
    );
    graphics.drawString(
      'Qty',
      boldFont,
      bounds: Rect.fromLTWH(bounds.left + 210, yPosition, 50, 20),
    );
    graphics.drawString(
      'Price',
      boldFont,
      bounds: Rect.fromLTWH(bounds.left + 270, yPosition, 80, 20),
    );
    graphics.drawString(
      'Total',
      boldFont,
      bounds: Rect.fromLTWH(bounds.left + 360, yPosition, 80, 20),
    );

    // Draw header line
    graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      Offset(bounds.left, yPosition + 25),
      Offset(bounds.right, yPosition + 25),
    );

    yPosition += 35;

    // Draw items
    for (var item in widget.orderItems) {
      graphics.drawString(
        item['name'] ?? 'Unknown Product',
        normalFont,
        bounds: Rect.fromLTWH(bounds.left, yPosition, 200, 20),
      );
      graphics.drawString(
        '${item['quantity'] ?? 1}',
        normalFont,
        bounds: Rect.fromLTWH(bounds.left + 210, yPosition, 50, 20),
      );
      graphics.drawString(
        'Rs${(item['price'] ?? 0.0).toStringAsFixed(2)}',
        normalFont,
        bounds: Rect.fromLTWH(bounds.left + 270, yPosition, 80, 20),
      );
      graphics.drawString(
        'Rs${((item['price'] ?? 0.0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
        normalFont,
        bounds: Rect.fromLTWH(bounds.left + 360, yPosition, 80, 20),
      );
      yPosition += 25;
    }

    // Draw separator line
    yPosition += 10;
    graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      Offset(bounds.left, yPosition),
      Offset(bounds.right, yPosition),
    );
    yPosition += 20;

    // Total
    graphics.drawString(
      'Total Amount: Rs${widget.totalAmount.toStringAsFixed(2)}',
      headerFont,
      bounds: Rect.fromLTWH(bounds.left, yPosition, bounds.width, 20),
    );

    // Footer
    yPosition = bounds.bottom - 50;
    graphics.drawString(
      'Thank you for your business!',
      normalFont,
      bounds: Rect.fromLTWH(bounds.left, yPosition, bounds.width, 20),
    );
    yPosition += 20;
    graphics.drawString(
      'Generated by POS System',
      normalFont,
      bounds: Rect.fromLTWH(bounds.left, yPosition, bounds.width, 20),
    );

    // Save and print the document
    final Uint8List bytes = Uint8List.fromList(await document.save());
    document.dispose();

    // Print the PDF
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  void _showPrintDialog() {
    final TextEditingController staffNoteController = TextEditingController();
    final TextEditingController paymentNoteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 450,
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header with Gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1845), Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Receipt',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Print Order Details',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Order Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0D1845).withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D1845).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF66BB6A),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment Completed',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D1845),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Order processed successfully',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1845).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Rs${widget.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Staff Note Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Staff Note',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: staffNoteController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Add any staff notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Note Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payment_rounded,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Payment Note',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: paymentNoteController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Add payment notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Skip Print'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final staffNote = staffNoteController.text
                                      .trim();
                                  final paymentNote = paymentNoteController.text
                                      .trim();

                                  try {
                                    await _generateInvoicePdf();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Invoice generated and sent to printer!\n'
                                          '${staffNote.isNotEmpty ? 'Staff Note: $staffNote\n' : ''}'
                                          '${paymentNote.isNotEmpty ? 'Payment Note: $paymentNote' : ''}',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to generate invoice: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.picture_as_pdf_rounded),
                                label: const Text('Generate Invoice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
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
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement actual print functionality
                              final staffNote = staffNoteController.text.trim();
                              final paymentNote = paymentNoteController.text
                                  .trim();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Order receipt printed successfully!\n'
                                    '${staffNote.isNotEmpty ? 'Staff Note: $staffNote\n' : ''}'
                                    '${paymentNote.isNotEmpty ? 'Payment Note: $paymentNote' : ''}',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.print_rounded),
                            label: const Text('Print Receipt Only'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF0D1845)),
                              foregroundColor: const Color(0xFF0D1845),
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
            ],
          ),
        ),
      ),
    );
  }
}

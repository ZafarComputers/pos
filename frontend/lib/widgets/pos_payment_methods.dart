import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PosPaymentMethods extends StatefulWidget {
  final double totalAmount;
  final Function(String, double) onPaymentComplete;

  const PosPaymentMethods({
    super.key,
    required this.totalAmount,
    required this.onPaymentComplete,
  });

  @override
  State<PosPaymentMethods> createState() => _PosPaymentMethodsState();
}

class _PosPaymentMethodsState extends State<PosPaymentMethods> {
  @override
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
    String bankAccountNumber = '';
    String accountHolderName = '';
    String bankName = '';

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
                                items: ['Cash', 'Bank Transfer'].map((method) {
                                  return DropdownMenuItem<String>(
                                    value: method,
                                    child: Row(
                                      children: [
                                        Icon(
                                          method == 'Cash'
                                              ? Icons.money
                                              : Icons.account_balance,
                                          color: method == 'Cash'
                                              ? Color(0xFF28A745)
                                              : Color(0xFF1976D2),
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

                              // Bank Transfer Fields
                              if (paymentMethod == 'Bank Transfer') ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Bank Account Number',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    bankAccountNumber = value;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Account Holder Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    accountHolderName = value;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Bank Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    bankName = value;
                                  },
                                ),
                              ],
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
                                    ? () {
                                        widget.onPaymentComplete(
                                          'Credit',
                                          paidAmount,
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
                  ? () {
                      widget.onPaymentComplete('Cash', receivedAmount);
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
    // Mock bank accounts data - in real app this would come from API (admin's saved bank accounts)
    final List<Map<String, dynamic>> bankAccounts = [
      {
        'id': '1',
        'name': 'JazzCash',
        'accountNumber': '03001234567',
        'accountHolder': 'Business Account',
      },
      {
        'id': '2',
        'name': 'EasyPaisa',
        'accountNumber': '03109876543',
        'accountHolder': 'Business Account',
      },
      {
        'id': '3',
        'name': 'Bank Account',
        'accountNumber': 'PK1234567890123456',
        'accountHolder': 'Business Name',
      },
    ];

    String? selectedReceiverAccountId;
    Map<String, dynamic>? selectedReceiverAccount;
    double paidAmount = widget.totalAmount;
    String senderBank = '';
    String senderBankName = '';
    String senderAccountHolderName = '';
    String senderAccountNumber = '';

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
                              'Bank Payment',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Process bank transfer payment',
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
                        // Receiver's Account Selection
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: DropdownButtonFormField<String>(
                            value: selectedReceiverAccountId,
                            decoration: InputDecoration(
                              labelText: 'Receiver\'s Account',
                              hintText: 'Select admin\'s bank account',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: bankAccounts.map((account) {
                              return DropdownMenuItem<String>(
                                value: account['id'],
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance,
                                      color: Color(0xFF0D1845),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account['name'],
                                            style: const TextStyle(
                                              color: Color(0xFF343A40),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '****${account['accountNumber'].substring(account['accountNumber'].length - 4)}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedReceiverAccountId = value;
                                selectedReceiverAccount = bankAccounts
                                    .firstWhere(
                                      (account) => account['id'] == value,
                                    );
                              });
                            },
                          ),
                        ),

                        // Selected Account Details
                        if (selectedReceiverAccount != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
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
                                      Icons.account_balance_wallet,
                                      color: Color(0xFF0D1845),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Receiver Account Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF343A40),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Account Type',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            selectedReceiverAccount!['name'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF343A40),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Account Holder',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            selectedReceiverAccount!['accountHolder'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF343A40),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account Number',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      selectedReceiverAccount!['accountNumber'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF343A40),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Sender's Bank Details Section
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
                                    Icons.send,
                                    color: Color(0xFF0D1845),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sender\'s Bank Details',
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

                              // Sender's Bank Dropdown
                              DropdownButtonFormField<String>(
                                value: senderBank.isEmpty ? null : senderBank,
                                decoration: InputDecoration(
                                  labelText: 'Sender\'s Bank',
                                  hintText: 'Select sender\'s bank type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                items: ['JazzCash', 'EasyPaisa', 'Bank'].map((
                                  bank,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: bank,
                                    child: Row(
                                      children: [
                                        Icon(
                                          bank == 'Bank'
                                              ? Icons.account_balance
                                              : Icons.phone_android,
                                          color: bank == 'Bank'
                                              ? Color(0xFF1976D2)
                                              : Color(0xFF4CAF50),
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
                                    senderBank = value!;
                                    // Reset bank name if not Bank
                                    if (value != 'Bank') {
                                      senderBankName = '';
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              // Bank Name (only show if Bank is selected)
                              if (senderBank == 'Bank') ...[
                                TextFormField(
                                  initialValue: senderBankName,
                                  decoration: InputDecoration(
                                    labelText: 'Bank Name',
                                    hintText: 'e.g., HBL, UBL, MCB',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    senderBankName = value;
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Account Holder Name
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Account Holder\'s Name',
                                  hintText: 'Enter sender\'s full name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  senderAccountHolderName = value;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Account Number
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Account Number',
                                  hintText: 'Enter sender\'s account number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  senderAccountNumber = value;
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
                                    selectedReceiverAccountId != null &&
                                        senderBank.isNotEmpty &&
                                        senderAccountHolderName.isNotEmpty &&
                                        senderAccountNumber.isNotEmpty &&
                                        (senderBank != 'Bank' ||
                                            senderBankName.isNotEmpty)
                                    ? () {
                                        widget.onPaymentComplete(
                                          'Bank',
                                          paidAmount,
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
                                child: const Text('Process Bank Payment'),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Skip Print'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                            label: const Text('Print Receipt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D1845),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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

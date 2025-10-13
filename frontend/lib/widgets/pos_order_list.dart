import 'package:flutter/material.dart';

class PosOrderList extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final Function(String) onRemoveItem;
  final Function(String, int) onUpdateQuantity;
  final Function(String) onSelectCustomer;
  final Function(double) onTotalChanged;

  const PosOrderList({
    super.key,
    required this.orderItems,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onSelectCustomer,
    required this.onTotalChanged,
  });

  @override
  State<PosOrderList> createState() => _PosOrderListState();
}

class _PosOrderListState extends State<PosOrderList> {
  String _orderId =
      'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  double _discountAmount = 0.0;
  bool _isDiscountPercentage = false;
  double _roundOffAmount = 0.0;

  double get _subtotal {
    return widget.orderItems.fold(
      0.0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  double get _tax => _subtotal * 0.08; // 8% tax
  double get _discount {
    if (_isDiscountPercentage) {
      return _subtotal * (_discountAmount / 100);
    }
    return _discountAmount;
  }

  double get _totalBeforeRoundOff => _subtotal + _tax - _discount;
  double get _total => (_totalBeforeRoundOff + _roundOffAmount);

  @override
  Widget build(BuildContext context) {
    // Notify parent of total changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTotalChanged(_total);
    });

    return Container(
      width: double.infinity, // Use full available width
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Order List Title
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1845),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Order List',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Order ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order ID:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0D1845),
                  ),
                ),
                Text(
                  _orderId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Order Details Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Details Header with Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1845).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF0D1845),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1845),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Items count and Total Amount header with enhanced styling
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.teal[50]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Items: ${widget.orderItems.length}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.teal[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total: Rs${_subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Order Items List with enhanced empty state
                widget.orderItems.isEmpty
                    ? Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your cart is empty',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add items from the menu to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        constraints: BoxConstraints(
                          maxHeight:
                              350, // Increased height for better visibility
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: widget.orderItems.length,
                          itemBuilder: (context, index) {
                            final item = widget.orderItems[index];
                            return _buildEnhancedOrderItem(item);
                          },
                        ),
                      ),
              ],
            ),
          ),

          // Payment Summary Section
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Summary Header with Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Payment Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1845),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total (shown first as per requirement) - Enhanced
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[50]!, Colors.teal[50]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt,
                            color: Colors.green[700],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1845),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rs${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Enhanced Summary Rows
                _buildEnhancedSummaryRow(
                  'Subtotal',
                  _subtotal,
                  Icons.shopping_bag,
                  Colors.blue,
                ),
                _buildEnhancedSummaryRow(
                  'Tax (8%)',
                  _tax,
                  Icons.account_balance_wallet,
                  Colors.orange,
                ),
                if (_discount > 0)
                  _buildEnhancedSummaryRow(
                    'Discount',
                    -_discount,
                    Icons.discount,
                    Colors.red,
                  ),

                const SizedBox(height: 16),

                // Discount Input with enhanced styling
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
                            Icons.local_offer,
                            color: Colors.purple[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Discount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D1845),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Enter discount',
                                hintText: _isDiscountPercentage ? '10' : '5.00',
                                prefixIcon: Icon(
                                  _isDiscountPercentage
                                      ? Icons.percent
                                      : Icons.attach_money,
                                  color: Colors.purple[400],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _discountAmount =
                                      double.tryParse(value) ?? 0.0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ToggleButtons(
                              isSelected: [
                                _isDiscountPercentage,
                                !_isDiscountPercentage,
                              ],
                              onPressed: (index) {
                                setState(() {
                                  _isDiscountPercentage = index == 0;
                                });
                              },
                              constraints: const BoxConstraints(
                                minWidth: 50,
                                minHeight: 48,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              selectedColor: Colors.white,
                              fillColor: Colors.purple[600],
                              children: const [
                                Text(
                                  '%',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Rs',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Round Off Input with enhanced styling
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rounded_corner,
                        color: Colors.indigo[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Round Off:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1845),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _roundOffAmount = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // No Shipping Fee note with icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFF8E1,
                    ), // Using direct color instead of Colors.amber[50]
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFE082),
                    ), // Using direct color instead of Colors.amber[200]
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: Colors.amber[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'No Shipping Fee',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF57C00), // Using direct amber color
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Select Payment Section
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Select Payment Header with Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.credit_card,
                        color: Colors.purple[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1845),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Payment methods will be handled by PosPaymentMethods widget
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOrderItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Name Only
          Expanded(
            child: Text(
              item['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0D1845),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (item['quantity'] > 1) {
                      widget.onUpdateQuantity(
                        item['id'].toString(),
                        item['quantity'] - 1,
                      );
                    }
                  },
                  icon: Icon(
                    Icons.remove,
                    size: 16,
                    color: item['quantity'] > 1
                        ? Colors.red[600]
                        : Colors.grey[400],
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1845),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item['quantity']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    widget.onUpdateQuantity(
                      item['id'].toString(),
                      item['quantity'] + 1,
                    );
                  },
                  icon: Icon(Icons.add, size: 16, color: Colors.green[600]),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ),

          // Remove Button
          IconButton(
            onPressed: () => widget.onRemoveItem(item['id'].toString()),
            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryRow(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Text(
            '${amount >= 0 ? '+' : ''}Rs${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

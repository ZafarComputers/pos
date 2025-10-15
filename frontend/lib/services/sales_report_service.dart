import '../services/services.dart';

class SalesReport {
  final int posInvNo;
  final String productName;
  final String vendor;
  final String category;
  final String qty;
  final String salePrice;
  final double amount;
  final String openingStockQty;
  final String newStockQty;
  final String soldStockQty;
  final String instockQty;

  SalesReport({
    required this.posInvNo,
    required this.productName,
    required this.vendor,
    required this.category,
    required this.qty,
    required this.salePrice,
    required this.amount,
    required this.openingStockQty,
    required this.newStockQty,
    required this.soldStockQty,
    required this.instockQty,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      posInvNo: json['pos_inv_no'] ?? 0,
      productName: json['product_name'] ?? '',
      vendor: json['vendor'] ?? '',
      category: json['category'] ?? '',
      qty: json['qty']?.toString() ?? '0',
      salePrice: json['sale_price']?.toString() ?? '0',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      openingStockQty: json['opening_stock_qty']?.toString() ?? '0',
      newStockQty: json['new_stock_qty']?.toString() ?? '0',
      soldStockQty: json['sold_stock_qty']?.toString() ?? '0',
      instockQty: json['instock_qty']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pos_inv_no': posInvNo,
      'product_name': productName,
      'vendor': vendor,
      'category': category,
      'qty': qty,
      'sale_price': salePrice,
      'amount': amount,
      'opening_stock_qty': openingStockQty,
      'new_stock_qty': newStockQty,
      'sold_stock_qty': soldStockQty,
      'instock_qty': instockQty,
    };
  }
}

class SalesReportResponse {
  final List<SalesReport> data;

  SalesReportResponse({required this.data});

  factory SalesReportResponse.fromJson(Map<String, dynamic> json) {
    return SalesReportResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => SalesReport.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class SalesReportService {
  static const String salesReportEndpoint = '/salesRep';

  static Future<SalesReportResponse> getSalesReport() async {
    try {
      final response = await ApiService.get(salesReportEndpoint);

      if (response.containsKey('data')) {
        final salesReportResponse = SalesReportResponse.fromJson(response);
        return salesReportResponse;
      } else {
        return SalesReportResponse(data: []);
      }
    } catch (e) {
      throw Exception('Failed to load sales report: $e');
    }
  }
}

import '../services/services.dart';

// Purchase Detail Model
class PurchaseDetail {
  final String productId;
  final String productName;
  final String quantity;
  final String unitPrice;
  final String discPer;
  final String discAmount;
  final String amount;

  PurchaseDetail({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discPer,
    required this.discAmount,
    required this.amount,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseDetail(
      productId: json['product_id']?.toString() ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity']?.toString() ?? '0',
      unitPrice: json['unit_price']?.toString() ?? '0.00',
      discPer: json['discPer']?.toString() ?? '0.00',
      discAmount: json['discAmount']?.toString() ?? '0.00',
      amount: json['amount']?.toString() ?? '0.00',
    );
  }
}

// Purchase Report Model
class PurchaseReport {
  final int purInvId;
  final String purInvBarcode;
  final String purDate;
  final String vendorId;
  final String vendorName;
  final String venInvNo;
  final String venInvDate;
  final String venInvRef;
  final String? description;
  final String invDiscPer;
  final String invDiscAmount;
  final String invAmount;
  final String paymentStatus;
  final String createdAt;
  final List<PurchaseDetail> purDetails;

  PurchaseReport({
    required this.purInvId,
    required this.purInvBarcode,
    required this.purDate,
    required this.vendorId,
    required this.vendorName,
    required this.venInvNo,
    required this.venInvDate,
    required this.venInvRef,
    this.description,
    required this.invDiscPer,
    required this.invDiscAmount,
    required this.invAmount,
    required this.paymentStatus,
    required this.createdAt,
    required this.purDetails,
  });

  factory PurchaseReport.fromJson(Map<String, dynamic> json) {
    return PurchaseReport(
      purInvId: json['Pur_Inv_id'] ?? 0,
      purInvBarcode: json['pur_inv_barcode'] ?? '',
      purDate: json['pur_date'] ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      vendorName: json['vendorName'] ?? '',
      venInvNo: json['ven_inv_no'] ?? '',
      venInvDate: json['ven_inv_date'] ?? '',
      venInvRef: json['ven_inv_ref'] ?? '',
      description: json['description'],
      invDiscPer: json['invDiscPer']?.toString() ?? '0.00',
      invDiscAmount: json['invDiscAmount']?.toString() ?? '0.00',
      invAmount: json['inv_amount']?.toString() ?? '0.00',
      paymentStatus: json['payment_status'] ?? '',
      createdAt: json['created_at'] ?? '',
      purDetails:
          (json['PurDetails'] as List<dynamic>?)
              ?.map((item) => PurchaseDetail.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// Response models
class PurchaseReportsResponse {
  final List<PurchaseReport> data;

  PurchaseReportsResponse({required this.data});

  factory PurchaseReportsResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseReportsResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => PurchaseReport.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// Service class
class PurchaseReportingService {
  static const String purchaseReportEndpoint = '/purReport';

  static Future<PurchaseReportsResponse> getPurchaseReports() async {
    try {
      final response = await ApiService.get(purchaseReportEndpoint);

      if (response.containsKey('data')) {
        final purchaseReportsResponse = PurchaseReportsResponse.fromJson(
          response,
        );
        return purchaseReportsResponse;
      } else {
        return PurchaseReportsResponse(data: []);
      }
    } catch (e) {
      throw Exception('Failed to load purchase reports: $e');
    }
  }
}

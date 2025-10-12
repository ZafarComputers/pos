import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services.dart';

class Invoice {
  final int invId;
  final String invDate;
  final String customerName;
  final double invAmount;
  final double paidAmount;
  final double dueAmount;

  Invoice({
    required this.invId,
    required this.invDate,
    required this.customerName,
    required this.invAmount,
    required this.paidAmount,
    required this.dueAmount,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final invAmount = double.tryParse(json['inv_amount'].toString()) ?? 0.0;
    final paidAmount = double.tryParse(json['paid_amount'].toString()) ?? 0.0;
    final dueAmount = invAmount - paidAmount;

    return Invoice(
      invId: json['Inv_id'] ?? 0,
      invDate: json['InvDate'] ?? '',
      customerName: json['customer_name'] ?? '',
      invAmount: invAmount,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Inv_id': invId,
      'InvDate': invDate,
      'customer_name': customerName,
      'inv_amount': invAmount.toString(),
      'paid_amount': paidAmount.toString(),
    };
  }
}

class InvoiceResponse {
  final List<Invoice> data;

  InvoiceResponse({required this.data});

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => Invoice.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SalesService {
  static const String invoicesEndpoint = '/pos';

  // Get all invoices
  static Future<InvoiceResponse> getInvoices() async {
    try {
      final response = await ApiService.get(invoicesEndpoint);

      if (response.containsKey('data')) {
        final invoiceResponse = InvoiceResponse.fromJson(response);
        return invoiceResponse;
      } else {
        return InvoiceResponse(data: []);
      }
    } catch (e) {
      throw Exception('Failed to load invoices: $e');
    }
  }
}

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

class InvoiceDetail {
  final int id;
  final String productId;
  final String productName;
  final String quantity;
  final String price;
  final double subtotal;

  InvoiceDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceDetail(
      id: json['id'] ?? 0,
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}

class InvoiceDetailResponse {
  final int invId;
  final String invDate;
  final String customerName;
  final String invAmount;
  final String paidAmount;
  final List<InvoiceDetail> details;

  InvoiceDetailResponse({
    required this.invId,
    required this.invDate,
    required this.customerName,
    required this.invAmount,
    required this.paidAmount,
    required this.details,
  });

  factory InvoiceDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return InvoiceDetailResponse(
      invId: data['Inv_id'] ?? 0,
      invDate: data['InvDate']?.toString() ?? '',
      customerName: data['customer_name']?.toString() ?? '',
      invAmount: data['inv_amount']?.toString() ?? '',
      paidAmount: data['paid_amount']?.toString() ?? '',
      details:
          (data['details'] as List<dynamic>?)
              ?.map((detail) => InvoiceDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Inv_id': invId,
      'InvDate': invDate,
      'customer_name': customerName,
      'inv_amount': invAmount,
      'paid_amount': paidAmount,
      'details': details.map((detail) => detail.toJson()).toList(),
    };
  }
}

class Links {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  Links({this.first, this.last, this.prev, this.next});

  factory Links.fromJson(Map<String, dynamic> json) {
    return Links(
      first: json['first'],
      last: json['last'],
      prev: json['prev'],
      next: json['next'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'first': first, 'last': last, 'prev': prev, 'next': next};
  }
}

class Link {
  final String? url;
  final String label;
  final int? page;
  final bool active;

  Link({this.url, required this.label, this.page, required this.active});

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: json['url'],
      label: json['label'] ?? '',
      page: json['page'],
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'label': label, 'page': page, 'active': active};
  }
}

class Meta {
  final int currentPage;
  final int? from;
  final int lastPage;
  final List<Link> links;
  final String path;
  final int perPage;
  final int? to;
  final int total;

  Meta({
    required this.currentPage,
    this.from,
    required this.lastPage,
    required this.links,
    required this.path,
    required this.perPage,
    this.to,
    required this.total,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currentPage: json['current_page'] ?? 1,
      from: json['from'],
      lastPage: json['last_page'] ?? 1,
      links:
          (json['links'] as List<dynamic>?)
              ?.map((item) => Link.fromJson(item))
              .toList() ??
          [],
      path: json['path'] ?? '',
      perPage: json['per_page'] ?? 10,
      to: json['to'],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'from': from,
      'last_page': lastPage,
      'links': links.map((link) => link.toJson()).toList(),
      'path': path,
      'per_page': perPage,
      'to': to,
      'total': total,
    };
  }
}

class InvoiceResponse {
  final List<Invoice> data;
  final Links links;
  final Meta meta;

  InvoiceResponse({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((invoice) => Invoice.fromJson(invoice))
              .toList() ??
          [],
      links: Links.fromJson(json['links'] ?? {}),
      meta: Meta.fromJson(json['meta'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((invoice) => invoice.toJson()).toList(),
      'links': links.toJson(),
      'meta': meta.toJson(),
    };
  }
}

class SalesReturnCustomer {
  final int id;
  final String name;

  SalesReturnCustomer({required this.id, required this.name});

  factory SalesReturnCustomer.fromJson(Map<String, dynamic> json) {
    return SalesReturnCustomer(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class SalesReturnDetail {
  final int id;
  final String productId;
  final String productName;
  final String qty;
  final String returnUnitPrice;
  final double total;

  SalesReturnDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.returnUnitPrice,
    required this.total,
  });

  factory SalesReturnDetail.fromJson(Map<String, dynamic> json) {
    return SalesReturnDetail(
      id: json['id'] ?? 0,
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      qty: json['qty']?.toString() ?? '',
      returnUnitPrice: json['return_unit_price']?.toString() ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'qty': qty,
      'return_unit_price': returnUnitPrice,
      'total': total,
    };
  }
}

class SalesReturn {
  final int id;
  final String invRetDate;
  final String returnInvAmount;
  final String posId;
  final SalesReturnCustomer customer;
  final List<SalesReturnDetail> details;
  final String createdAt;

  SalesReturn({
    required this.id,
    required this.invRetDate,
    required this.returnInvAmount,
    required this.posId,
    required this.customer,
    required this.details,
    required this.createdAt,
  });

  factory SalesReturn.fromJson(Map<String, dynamic> json) {
    return SalesReturn(
      id: json['id'] ?? 0,
      invRetDate: json['invRet_date'] ?? '',
      returnInvAmount: json['return_inv_amout'] ?? '',
      posId: json['pos_id']?.toString() ?? '',
      customer: SalesReturnCustomer.fromJson(json['customer'] ?? {}),
      details:
          (json['details'] as List<dynamic>?)
              ?.map((detail) => SalesReturnDetail.fromJson(detail))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invRet_date': invRetDate,
      'return_inv_amout': returnInvAmount,
      'pos_id': posId,
      'customer': customer.toJson(),
      'details': details.map((detail) => detail.toJson()).toList(),
      'created_at': createdAt,
    };
  }
}

class SalesReturnResponse {
  final bool status;
  final List<SalesReturn> data;

  SalesReturnResponse({required this.status, required this.data});

  factory SalesReturnResponse.fromJson(Map<String, dynamic> json) {
    return SalesReturnResponse(
      status: json['status'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((salesReturn) => SalesReturn.fromJson(salesReturn))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((salesReturn) => salesReturn.toJson()).toList(),
    };
  }
}

class SalesService {
  static const String invoicesEndpoint = '/pos';
  static const String salesReturnsEndpoint = '/posReturn';

  // Get all sales returns
  static Future<SalesReturnResponse> getSalesReturns() async {
    try {
      final response = await ApiService.get(salesReturnsEndpoint);

      if (response.containsKey('data')) {
        final salesReturnResponse = SalesReturnResponse.fromJson(response);
        return salesReturnResponse;
      } else {
        return SalesReturnResponse(status: false, data: []);
      }
    } catch (e) {
      throw Exception('Failed to load sales returns: $e');
    }
  }

  // Get sales return by ID
  static Future<SalesReturn> getSalesReturnById(String returnId) async {
    try {
      final response = await ApiService.get('$salesReturnsEndpoint/$returnId');

      if (response.containsKey('data')) {
        final salesReturn = SalesReturn.fromJson(response['data']);
        return salesReturn;
      } else {
        throw Exception('Sales return data not found in response');
      }
    } catch (e) {
      throw Exception('Failed to load sales return: $e');
    }
  }

  // Update sales return
  static Future<SalesReturn> updateSalesReturn(
    String returnId,
    Map<String, dynamic> returnData,
  ) async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}$salesReturnsEndpoint/$returnId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(returnData),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded.containsKey('data')) {
          final salesReturn = SalesReturn.fromJson(decoded['data']);
          return salesReturn;
        } else {
          throw Exception('Sales return data not found in response');
        }
      } else if (response.statusCode == 401) {
        await ApiService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Update failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete sales return
  static Future<Map<String, dynamic>> deleteSalesReturn(
    String returnId,
    Map<String, dynamic> deleteData,
  ) async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}$salesReturnsEndpoint/$returnId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(deleteData),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded;
      } else if (response.statusCode == 401) {
        await ApiService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Delete failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get all invoices
  static Future<InvoiceResponse> getInvoices() async {
    try {
      final response = await ApiService.get(invoicesEndpoint);

      if (response.containsKey('data')) {
        final invoiceResponse = InvoiceResponse.fromJson(response);
        return invoiceResponse;
      } else {
        return InvoiceResponse(
          data: [],
          links: Links(),
          meta: Meta(
            currentPage: 1,
            lastPage: 1,
            links: [],
            path: '',
            perPage: 10,
            total: 0,
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to load invoices: $e');
    }
  }

  // Get invoice by ID
  static Future<InvoiceDetailResponse> getInvoiceById(int invoiceId) async {
    try {
      final response = await ApiService.get('$invoicesEndpoint/$invoiceId');

      if (response.containsKey('data')) {
        final invoiceDetailResponse = InvoiceDetailResponse.fromJson(response);
        return invoiceDetailResponse;
      } else {
        throw Exception('Invoice data not found in response');
      }
    } catch (e) {
      throw Exception('Failed to load invoice: $e');
    }
  }

  // Update invoice
  static Future<Map<String, dynamic>> updateInvoice(
    int invoiceId,
    Map<String, dynamic> invoiceData,
  ) async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}$invoicesEndpoint/$invoiceId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded;
      } else if (response.statusCode == 401) {
        await ApiService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Update failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete invoice
  static Future<Map<String, dynamic>> deleteInvoice(int invoiceId) async {
    final token = await ApiService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}$invoicesEndpoint/$invoiceId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final decoded = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'message': 'Invoice deleted successfully'};
        return decoded;
      } else if (response.statusCode == 401) {
        await ApiService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Delete failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

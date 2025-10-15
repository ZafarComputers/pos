import '../services/services.dart';

// Common models
class Category {
  final int id;
  final String categoryName;

  Category({required this.id, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      categoryName: json['CategoryName'] ?? '',
    );
  }
}

class SubCategory {
  final int id;
  final String subCatName;

  SubCategory({required this.id, required this.subCatName});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] ?? 0,
      subCatName: json['subCatName'] ?? '',
    );
  }
}

class Vendor {
  final int id;
  final String vendorName;

  Vendor({required this.id, required this.vendorName});

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(id: json['id'] ?? 0, vendorName: json['vendorName'] ?? '');
  }
}

// In Hand Product Model
class InHandProduct {
  final int id;
  final String productName;
  final String barcode;
  final String designCode;
  final String? imagePath;
  final Category category;
  final SubCategory subCategory;
  final String balanceStock;
  final Vendor vendor;
  final String productStatus;

  InHandProduct({
    required this.id,
    required this.productName,
    required this.barcode,
    required this.designCode,
    required this.imagePath,
    required this.category,
    required this.subCategory,
    required this.balanceStock,
    required this.vendor,
    required this.productStatus,
  });

  factory InHandProduct.fromJson(Map<String, dynamic> json) {
    return InHandProduct(
      id: json['id'] ?? 0,
      productName: json['productName'] ?? '',
      barcode: json['barcode'] ?? '',
      designCode: json['design_code'] ?? '',
      imagePath: json['image_path'],
      category: Category.fromJson(json['category'] ?? {}),
      subCategory: SubCategory.fromJson(json['sub_category'] ?? {}),
      balanceStock: json['balance_stock'] ?? '0',
      vendor: Vendor.fromJson(json['vendor'] ?? {}),
      productStatus: json['productStatus'] ?? '',
    );
  }
}

// History Product Model
class HistoryProduct {
  final int id;
  final String productName;
  final String barcode;
  final String designCode;
  final String? imagePath;
  final Category category;
  final SubCategory subCategory;
  final String salePrice;
  final String openingStock;
  final String newStock;
  final String soldStock;
  final String balanceStock;
  final Vendor vendor;
  final String productStatus;

  HistoryProduct({
    required this.id,
    required this.productName,
    required this.barcode,
    required this.designCode,
    required this.imagePath,
    required this.category,
    required this.subCategory,
    required this.salePrice,
    required this.openingStock,
    required this.newStock,
    required this.soldStock,
    required this.balanceStock,
    required this.vendor,
    required this.productStatus,
  });

  factory HistoryProduct.fromJson(Map<String, dynamic> json) {
    return HistoryProduct(
      id: json['id'] ?? 0,
      productName: json['productName'] ?? '',
      barcode: json['barcode'] ?? '',
      designCode: json['design_code'] ?? '',
      imagePath: json['image_path'],
      category: Category.fromJson(json['category'] ?? {}),
      subCategory: SubCategory.fromJson(json['sub_category'] ?? {}),
      salePrice: json['sale_price'] ?? '0.00',
      openingStock: json['opening_stock'] ?? '0',
      newStock: json['new_stock'] ?? '0',
      soldStock: json['sold_stock'] ?? '0',
      balanceStock: json['balance_stock'] ?? '0',
      vendor: Vendor.fromJson(json['vendor'] ?? {}),
      productStatus: json['productStatus'] ?? '',
    );
  }
}

// Sold Product Model
class SoldProduct {
  final int id;
  final String productName;
  final String barcode;
  final String designCode;
  final String? imagePath;
  final Category category;
  final SubCategory subCategory;
  final String soldStock;
  final String balanceStock;
  final Vendor vendor;
  final String productStatus;

  SoldProduct({
    required this.id,
    required this.productName,
    required this.barcode,
    required this.designCode,
    required this.imagePath,
    required this.category,
    required this.subCategory,
    required this.soldStock,
    required this.balanceStock,
    required this.vendor,
    required this.productStatus,
  });

  factory SoldProduct.fromJson(Map<String, dynamic> json) {
    return SoldProduct(
      id: json['id'] ?? 0,
      productName: json['productName'] ?? '',
      barcode: json['barcode'] ?? '',
      designCode: json['design_code'] ?? '',
      imagePath: json['image_path'],
      category: Category.fromJson(json['category'] ?? {}),
      subCategory: SubCategory.fromJson(json['sub_category'] ?? {}),
      soldStock: json['sold_stock'] ?? '0',
      balanceStock: json['balance_stock'] ?? '0',
      vendor: Vendor.fromJson(json['vendor'] ?? {}),
      productStatus: json['productStatus'] ?? '',
    );
  }
}

// Response models
class InHandProductsResponse {
  final List<InHandProduct> data;

  InHandProductsResponse({required this.data});

  factory InHandProductsResponse.fromJson(Map<String, dynamic> json) {
    return InHandProductsResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => InHandProduct.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class HistoryProductsResponse {
  final List<HistoryProduct> data;

  HistoryProductsResponse({required this.data});

  factory HistoryProductsResponse.fromJson(Map<String, dynamic> json) {
    return HistoryProductsResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => HistoryProduct.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class SoldProductsResponse {
  final List<SoldProduct> data;

  SoldProductsResponse({required this.data});

  factory SoldProductsResponse.fromJson(Map<String, dynamic> json) {
    return SoldProductsResponse(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => SoldProduct.fromJson(item))
              .toList() ??
          [],
    );
  }
}

// Service class
class InventoryReportingService {
  static const String inHandEndpoint = '/InvtoryReport';
  static const String historyEndpoint = '/InvtoryInHistory';
  static const String soldEndpoint = '/InventorySold';

  static Future<InHandProductsResponse> getInHandProducts() async {
    try {
      final response = await ApiService.get(inHandEndpoint);

      if (response.containsKey('data')) {
        final inHandProductsResponse = InHandProductsResponse.fromJson(
          response,
        );
        return inHandProductsResponse;
      } else {
        return InHandProductsResponse(data: []);
      }
    } catch (e) {
      throw Exception('Failed to load in-hand products: $e');
    }
  }

  static Future<HistoryProductsResponse> getHistoryProducts() async {
    try {
      final response = await ApiService.get(historyEndpoint);

      if (response.containsKey('data')) {
        final historyProductsResponse = HistoryProductsResponse.fromJson(
          response,
        );
        return historyProductsResponse;
      } else {
        return HistoryProductsResponse(data: []);
      }
    } catch (e) {
      throw Exception('Failed to load history products: $e');
    }
  }

  static Future<SoldProductsResponse> getSoldProducts() async {
    try {
      final response = await ApiService.get(soldEndpoint);

      if (response.containsKey('data')) {
        final soldProductsResponse = SoldProductsResponse.fromJson(response);
        return soldProductsResponse;
      } else {
        return SoldProductsResponse(data: []);
      }
    } catch (e) {
      throw Exception('Failed to load sold products: $e');
    }
  }
}

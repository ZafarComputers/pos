class Product {
  final int id;
  final String title;
  final String designCode;
  final String? imagePath;
  final String subCategoryId;
  final String salePrice;
  final String openingStockQuantity;
  final String vendorId;
  final ProductVendor vendor;
  final String barcode;
  final String status;
  final String createdAt;
  final String updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.designCode,
    this.imagePath,
    required this.subCategoryId,
    required this.salePrice,
    required this.openingStockQuantity,
    required this.vendorId,
    required this.vendor,
    required this.barcode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Try different possible field names for id
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final id =
        parseId(json['id']) ??
        parseId(json['product_id']) ??
        parseId(json['ID']) ??
        0;

    return Product(
      id: id,
      title:
          json['title']?.toString() ??
          json['name']?.toString() ??
          json['productName']?.toString() ??
          '',
      designCode: json['design_code']?.toString() ?? '',
      imagePath: json['image_path']?.toString(),
      subCategoryId: json['sub_category_id']?.toString() ?? '',
      salePrice: json['sale_price']?.toString() ?? '',
      openingStockQuantity: json['opening_stock_quantity']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      vendor: json['vendor'] != null
          ? ProductVendor.fromJson(json['vendor'])
          : ProductVendor.empty(),
      barcode: json['barcode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class ProductVendor {
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String status;
  final String createdAt;
  final String updatedAt;

  ProductVendor({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVendor.fromJson(Map<String, dynamic> json) {
    // Combine first_name and last_name if available, otherwise use name
    String? vendorName;
    if (json['first_name'] != null && json['last_name'] != null) {
      vendorName = '${json['first_name']} ${json['last_name']}';
    } else {
      vendorName = json['name']?.toString();
    }

    return ProductVendor(
      id: json['id'] ?? 0,
      name: vendorName,
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  factory ProductVendor.empty() {
    return ProductVendor(
      id: 0,
      name: null,
      email: null,
      phone: null,
      address: null,
      status: '',
      createdAt: '',
      updatedAt: '',
    );
  }
}

class ProductResponse {
  final List<Product> data;
  final Links links;
  final Meta meta;

  ProductResponse({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      data: (json['data'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
      links: Links.fromJson(json['links']),
      meta: Meta.fromJson(json['meta']),
    );
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
          (json['links'] as List?)
              ?.map((item) => Link.fromJson(item))
              .toList() ??
          [],
      path: json['path'] ?? '',
      perPage: json['per_page'] ?? 10,
      to: json['to'],
      total: json['total'] ?? 0,
    );
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
}

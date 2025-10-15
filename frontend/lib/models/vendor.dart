class Vendor {
  final int id;
  final String firstName;
  final String lastName;
  final String cnic;
  final String? address;
  final String cityId;
  final String status;
  final String createdAt;
  final String updatedAt;
  final City city;

  Vendor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.cnic,
    this.address,
    required this.cityId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.city,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      cnic: json['cnic'],
      address: json['address'] as String?,
      cityId: json['city_id'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      city: City.fromJson(json['city']),
    );
  }

  String get fullName => '$firstName $lastName';
  String get vendorCode => 'V${id.toString().padLeft(3, '0')}';
}

class City {
  final int id;
  final String title;
  final String stateId;
  final String status;
  final String createdAt;
  final String updatedAt;

  City({
    required this.id,
    required this.title,
    required this.stateId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      title: json['title'],
      stateId: json['state_id'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class VendorResponse {
  final List<Vendor> data;
  final Links links;
  final Meta meta;

  VendorResponse({required this.data, required this.links, required this.meta});

  factory VendorResponse.fromJson(Map<String, dynamic> json) {
    return VendorResponse(
      data: (json['data'] as List)
          .map((item) => Vendor.fromJson(item))
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
      currentPage: json['current_page'],
      from: json['from'],
      lastPage: json['last_page'],
      links: (json['links'] as List)
          .map((item) => Link.fromJson(item))
          .toList(),
      path: json['path'],
      perPage: json['per_page'],
      to: json['to'],
      total: json['total'],
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
      label: json['label'],
      page: json['page'],
      active: json['active'],
    );
  }
}

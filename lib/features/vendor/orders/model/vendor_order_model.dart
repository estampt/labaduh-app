// vendor_order_model.dart
//
// Models for: GET /api/v1/vendors/{vendorId}/shops/{shopId}/orders
// Based on the JSON you provided.

class VendorOrdersPage {
  const VendorOrdersPage({
    required this.orders,
    required this.cursor,
  });

  final List<VendorOrderModel> orders;
  final String? cursor;

  factory VendorOrdersPage.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => VendorOrderModel.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    return VendorOrdersPage(
      orders: list,
      cursor: json['cursor'] as String?,
    );
  }
}

class VendorOrderModel {
  const VendorOrderModel({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.shopId,
    required this.acceptedShop,
    required this.customer,
    required this.itemsCount,
    required this.services,
    required this.items,
  });

  final int id;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int shopId;

  final VendorShopModel? acceptedShop;
  final VendorCustomerModel? customer;

  final int itemsCount;
  final List<String> services;
  final List<VendorOrderItemModel> items;

  factory VendorOrderModel.fromJson(Map<String, dynamic> json) {
    return VendorOrderModel(
      id: _toInt(json['id']) ?? 0,
      status: (json['status'] as String?) ?? 'unknown',
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      shopId: _toInt(json['shop_id']) ?? 0,
      acceptedShop: (json['accepted_shop'] is Map)
          ? VendorShopModel.fromJson((json['accepted_shop'] as Map).cast<String, dynamic>())
          : null,
      customer: (json['customer'] is Map)
          ? VendorCustomerModel.fromJson((json['customer'] as Map).cast<String, dynamic>())
          : null,
      itemsCount: _toInt(json['items_count']) ?? 0,
      services: (json['services'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => VendorOrderItemModel.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  String get idLabel => '#$id';

  String get statusLabel => _statusToLabel(status);

  String get customerName => customer?.name ?? 'Customer';

  String get servicesLabel =>
      services.isEmpty ? 'No services' : services.join(', ');
}

class VendorShopModel {
  const VendorShopModel({
    required this.id,
    required this.name,
    required this.profilePhotoUrl,
    required this.latitude,
    required this.longitude,
    required this.avgRating,
    required this.ratingsCount,
  });

  final int id;
  final String name;
  final String profilePhotoUrl;
  final double? latitude;
  final double? longitude;
  final double? avgRating;
  final int? ratingsCount;

  factory VendorShopModel.fromJson(Map<String, dynamic> json) {
    return VendorShopModel(
      id: _toInt(json['id']) ?? 0,
      name: (json['name'] as String?) ?? 'Shop',
      profilePhotoUrl: (json['profile_photo_url'] as String?) ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      avgRating: _toDouble(json['avg_rating']),
      ratingsCount: _toInt(json['ratings_count']),
    );
  }
}

class VendorCustomerModel {
  const VendorCustomerModel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory VendorCustomerModel.fromJson(Map<String, dynamic> json) {
    return VendorCustomerModel(
      id: _toInt(json['id']) ?? 0,
      name: (json['name'] as String?) ?? 'Customer',
    );
  }
}

class VendorOrderItemModel {
  const VendorOrderItemModel({
    required this.id,
    required this.quantity,
    required this.service,
    required this.options,
  });

  final int id;
  final int quantity;
  final VendorServiceModel? service;
  final List<VendorOrderOptionModel> options;

  factory VendorOrderItemModel.fromJson(Map<String, dynamic> json) {
    return VendorOrderItemModel(
      id: _toInt(json['id']) ?? 0,
      quantity: _toInt(json['quantity']) ?? 1,
      service: (json['service'] is Map)
          ? VendorServiceModel.fromJson((json['service'] as Map).cast<String, dynamic>())
          : null,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => VendorOrderOptionModel.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

class VendorServiceModel {
  const VendorServiceModel({
    required this.id,
    required this.name,
    required this.description,
  });

  final int id;
  final String name;
  final String description;

  factory VendorServiceModel.fromJson(Map<String, dynamic> json) {
    return VendorServiceModel(
      id: _toInt(json['id']) ?? 0,
      name: (json['name'] as String?) ?? 'Service',
      description: (json['description'] as String?) ?? '',
    );
  }
}

class VendorOrderOptionModel {
  const VendorOrderOptionModel({
    required this.id,
    required this.qty,
    required this.serviceOption,
  });

  final int id;
  final int qty;
  final VendorServiceOptionModel? serviceOption;

  factory VendorOrderOptionModel.fromJson(Map<String, dynamic> json) {
    return VendorOrderOptionModel(
      id: _toInt(json['id']) ?? 0,
      qty: _toInt(json['qty']) ?? 1,
      serviceOption: (json['service_option'] is Map)
          ? VendorServiceOptionModel.fromJson(
              (json['service_option'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class VendorServiceOptionModel {
  const VendorServiceOptionModel({
    required this.id,
    required this.name,
    required this.description,
  });

  final int id;
  final String name;
  final String description;

  factory VendorServiceOptionModel.fromJson(Map<String, dynamic> json) {
    return VendorServiceOptionModel(
      id: _toInt(json['id']) ?? 0,
      name: (json['name'] as String?) ?? 'Option',
      description: (json['description'] as String?) ?? '',
    );
  }
}

// ----------------------------
// Helpers (null-safe parsing)
// ----------------------------

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _toDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
  return null;
}

String _statusToLabel(String status) {
  final s = status.trim();
  if (s.isEmpty) return 'Unknown';

  return s
      .split('_')
      .where((p) => p.trim().isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');
}

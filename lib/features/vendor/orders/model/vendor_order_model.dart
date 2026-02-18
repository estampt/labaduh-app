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
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
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
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
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
      subtotal: _toDouble(json['subtotal']) ?? 0,
      deliveryFee: _toDouble(json['delivery_fee']) ?? 0,
      serviceFee: _toDouble(json['service_fee']) ?? 0,
      discount: _toDouble(json['discount']) ?? 0,

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

  double get grandTotal => subtotal + deliveryFee + serviceFee - discount;
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
    this.profilePhotoUrl,
    this.addressLine1,
    this.addressLine2,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;

  final String? profilePhotoUrl;
  final String? addressLine1;
  final String? addressLine2;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  factory VendorCustomerModel.fromJson(Map<String, dynamic> json) {
    return VendorCustomerModel(
      id: _toInt(json['id']) ?? 0,
      name: (json['name'] as String?) ?? 'Customer',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  String get addressLabel {
    final parts = [
      addressLine1,
      addressLine2,
      postalCode,
    ].where((e) => (e ?? '').trim().isNotEmpty);

    return parts.isEmpty ? '—' : parts.join(', ');
  }
}

class VendorOrderItemModel {
  const VendorOrderItemModel({
    required this.id,
    required this.quantity,
    required this.qtyEstimated,
    required this.qtyActual,
    required this.uom,
    required this.pricingModel,
    required this.minimum,
    required this.minPrice,
    required this.pricePerUom,
    required this.computedPrice,
    required this.estimatedPrice,
    required this.finalPrice,
    required this.service,
    required this.options,
  });

  final int id;

  /// Primary quantity used by UI (derived from `qty` or `quantity` in JSON)
  final int quantity;

  final int? qtyEstimated;
  final int? qtyActual;

  final String? uom;

  /// e.g. tiered_min_plus, per_kg_min, etc.
  final String? pricingModel;

  /// Monetary / numeric fields (API sometimes returns strings)
  final double? minimum;
  final double? minPrice;
  final double? pricePerUom;

  /// Price snapshots
  final double? computedPrice;
  final double? estimatedPrice;
  final double? finalPrice;

  final VendorServiceModel? service;
  final List<VendorOrderOptionModel> options;

  factory VendorOrderItemModel.fromJson(Map<String, dynamic> json) {
    final qty = _toInt(json['qty']) ?? _toInt(json['quantity']) ?? 1;

    return VendorOrderItemModel(
      id: _toInt(json['id']) ?? 0,
      quantity: qty,
      qtyEstimated: _toInt(json['qty_estimated']),
      qtyActual: _toInt(json['qty_actual']),
      uom: (json['uom'] as String?)?.trim(),
      pricingModel: (json['pricing_model'] as String?)?.trim(),
      minimum: _toDouble(json['minimum']),
      minPrice: _toDouble(json['min_price']),
      pricePerUom: _toDouble(json['price_per_uom']),
      computedPrice: _toDouble(json['computed_price']),
      estimatedPrice: _toDouble(json['estimated_price']),
      finalPrice: _toDouble(json['final_price']),
      service: (json['service'] is Map)
          ? VendorServiceModel.fromJson(
              (json['service'] as Map).cast<String, dynamic>(),
            )
          : null,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => VendorOrderOptionModel.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  /// Convenience label like "3 KG"
  String get qtyLabel {
    final u = (uom ?? '').trim();
    return u.isEmpty ? '$quantity' : '$quantity ${u.toUpperCase()}';
  }

  /// computed_price + options computed_price (best-effort)
  double get totalComputed {
    final base = computedPrice ?? 0.0;
    final addOns = options.fold<double>(0.0, (sum, o) => sum + (o.computedPrice ?? 0.0));
    return base + addOns;
  }
}

class VendorServiceModel {
  const VendorServiceModel({
    required this.id,
    required this.name,
    required this.description,
  });

  final int id;

  /// These may be missing depending on your payload / snapshot rules.
  final String? name;
  final String? description;

  factory VendorServiceModel.fromJson(Map<String, dynamic> json) {
    return VendorServiceModel(
      id: _toInt(json['id']) ?? 0,
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  String get displayName => (name == null || name!.trim().isEmpty) ? 'Service' : name!.trim();

  String get displayDescription =>
      (description == null || description!.trim().isEmpty) ? '—' : description!.trim();
}

class VendorOrderOptionModel {
  const VendorOrderOptionModel({
    required this.id,
    required this.serviceOptionId,
    required this.qty,
    required this.price,
    required this.isRequired,
    required this.computedPrice,
    required this.serviceOption,
  });

  final int id;

  final int? serviceOptionId;

  /// Option quantity; API can send null, default to 1
  final int qty;

  /// Base price snapshot
  final double? price;

  final bool isRequired;

  /// Computed snapshot price for this option (best for displaying totals)
  final double? computedPrice;

  final VendorServiceOptionModel? serviceOption;

  factory VendorOrderOptionModel.fromJson(Map<String, dynamic> json) {
    final rawReq = json['is_required'];
    final req = rawReq == true || rawReq == 1 || rawReq == '1';

    return VendorOrderOptionModel(
      id: _toInt(json['id']) ?? 0,
      serviceOptionId: _toInt(json['service_option_id']),
      qty: _toInt(json['qty']) ?? 1,
      price: _toDouble(json['price']),
      isRequired: req,
      computedPrice: _toDouble(json['computed_price']),
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

  /// May be missing depending on payload
  final String? name;
  final String? description;

  factory VendorServiceOptionModel.fromJson(Map<String, dynamic> json) {
    return VendorServiceOptionModel(
      id: _toInt(json['id']) ?? 0,
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  String get displayName => (name == null || name!.trim().isEmpty) ? 'Option' : name!.trim();

  String get displayDescription =>
      (description == null || description!.trim().isEmpty) ? '—' : description!.trim();
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

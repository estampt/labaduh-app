
// lib/features/customer/order/models/latest_orders_models.dart
//
// Models for: GET /api/v1/customer/orders/latest
// Backward-compatible with the older lightweight response (shop/driver + item.price + option.name)
// and the newer expanded response (accepted_shop/vendor_shop + item.computed_price + option.service_option_id).
//
// NOTE: Keep fields nullable where backend may omit them.

class LatestOrdersResponse {
  final List<LatestOrder> data;
  final String? cursor;

  const LatestOrdersResponse({
    required this.data,
    required this.cursor,
  });

  factory LatestOrdersResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['data'] as List?) ?? const [];
    return LatestOrdersResponse(
      data: raw
          .whereType<Map>()
          .map((e) => LatestOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      cursor: json['cursor']?.toString(),
    );
  }
}

class LatestOrder {
  final int id;

  final int? customerId;
  final String status;
  final String? pricingStatus;

  // Totals (new response has "total"/"subtotal"/fees)
  final String? subtotal;
  final String? deliveryFee;
  final String? serviceFee;
  final String? discount;
  final String? total;

  // Old response had estimated_total/final_total at order level.
  final String? estimatedTotal;
  final String? finalTotal;

  final String createdAt;
  final String? updatedAt;

  // Partner/shop (old: shop, new: vendor_shop or accepted_shop)
  final OrderShopSummary? _shop; // old key: "shop"
  final OrderShopSummary? vendorShop; // new key: "vendor_shop"
  final OrderShopSummary? acceptedShop; // new key: "accepted_shop"

  // Driver (old: driver)
  final OrderDriverSummary? driver;

  final List<LatestOrderItem> items;

  const LatestOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.items,
    this.customerId,
    this.pricingStatus,
    this.subtotal,
    this.deliveryFee,
    this.serviceFee,
    this.discount,
    this.total,
    this.estimatedTotal,
    this.finalTotal,
    this.updatedAt,
    this.vendorShop,
    this.acceptedShop,
    OrderShopSummary? shop,
    this.driver,
  }) : _shop = shop;

  /// Unified shop accessor for UI code that previously used `order.shop`.
  /// Priority: vendorShop -> acceptedShop -> legacy shop.
  OrderShopSummary? get shop => vendorShop ?? acceptedShop ?? _shop;

  /// Numeric-ish total that prefers the latest canonical "total" if present.
  /// (UI can still use its own fallback computations.)
  String? get displayTotal => total ?? finalTotal ?? estimatedTotal;

  factory LatestOrder.fromJson(Map<String, dynamic> json) {
    final itemsRaw = (json['items'] as List?) ?? const [];

    return LatestOrder(
      id: _asInt(json['id']) ?? 0,
      customerId: _asInt(json['customer_id']),
      status: (json['status'] ?? '').toString(),
      pricingStatus: json['pricing_status']?.toString(),
      subtotal: json['subtotal']?.toString(),
      deliveryFee: json['delivery_fee']?.toString(),
      serviceFee: json['service_fee']?.toString(),
      discount: json['discount']?.toString(),
      total: json['total']?.toString(),
      estimatedTotal: json['estimated_total']?.toString(),
      finalTotal: json['final_total']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: json['updated_at']?.toString(),
      shop: json['shop'] is Map ? OrderShopSummary.fromJson(Map<String, dynamic>.from(json['shop'])) : null,
      vendorShop: json['vendor_shop'] is Map ? OrderShopSummary.fromJson(Map<String, dynamic>.from(json['vendor_shop'])) : null,
      acceptedShop: json['accepted_shop'] is Map ? OrderShopSummary.fromJson(Map<String, dynamic>.from(json['accepted_shop'])) : null,
      driver: json['driver'] is Map ? OrderDriverSummary.fromJson(Map<String, dynamic>.from(json['driver'])) : null,
      items: itemsRaw
          .whereType<Map>()
          .map((e) => LatestOrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class OrderShopSummary {
  final int id;
  final String name;

  final String? profilePhotoUrl;

  final double? avgRating;
  final int? ratingsCount;

  // only present in vendor_shop block
  final double? distanceKm;

  const OrderShopSummary({
    required this.id,
    required this.name,
    this.profilePhotoUrl,
    this.avgRating,
    this.ratingsCount,
    this.distanceKm,
  });

  factory OrderShopSummary.fromJson(Map<String, dynamic> json) {
    return OrderShopSummary(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      avgRating: _asDouble(json['avg_rating']),
      ratingsCount: _asInt(json['ratings_count']),
      distanceKm: _asDouble(json['distance_km']),
    );
  }
}

class OrderDriverSummary {
  final int id;
  final String name;

  const OrderDriverSummary({
    required this.id,
    required this.name,
  });

  factory OrderDriverSummary.fromJson(Map<String, dynamic> json) {
    return OrderDriverSummary(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class LatestOrderItem {
  final int id;
  final int serviceId;
  final num qty;

  // Old: "price"
  // New: "computed_price" (preferred)
  final String? price;
  final String? computedPrice;

  // New (optional, for future UI)
  final String? uom;

  final List<LatestOrderItemOption> options;

  const LatestOrderItem({
    required this.id,
    required this.serviceId,
    required this.qty,
    required this.options,
    this.price,
    this.computedPrice,
    this.uom,
  });

  /// Prefer computed_price when present, otherwise fallback to legacy price.
  String? get displayPrice => computedPrice ?? price;

  factory LatestOrderItem.fromJson(Map<String, dynamic> json) {
    final optsRaw = (json['options'] as List?) ?? const [];
    return LatestOrderItem(
      id: _asInt(json['id']) ?? 0,
      serviceId: _asInt(json['service_id']) ?? 0,
      qty: _asNum(json['qty']) ?? 0,
      uom: json['uom']?.toString(),
      computedPrice: json['computed_price']?.toString(),
      price: json['price']?.toString(),
      options: optsRaw
          .whereType<Map>()
          .map((e) => LatestOrderItemOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class LatestOrderItemOption {
  final int id;

  // Old response: {id, name, price}
  final String? name;
  final String? price;

  // New response: {service_option_id, computed_price, is_required}
  final int? serviceOptionId;
  final bool? isRequired;
  final String? computedPrice;

  const LatestOrderItemOption({
    required this.id,
    this.name,
    this.price,
    this.serviceOptionId,
    this.isRequired,
    this.computedPrice,
  });

  /// Prefer computed_price when present, otherwise fallback to legacy price.
  String? get displayPrice => computedPrice ?? price;

  factory LatestOrderItemOption.fromJson(Map<String, dynamic> json) {
    return LatestOrderItemOption(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      price: json['price']?.toString(),
      serviceOptionId: _asInt(json['service_option_id']),
      isRequired: json['is_required'] is bool
          ? json['is_required'] as bool
          : (json['is_required'] is num ? (json['is_required'] as num) == 1 : null),
      computedPrice: json['computed_price']?.toString(),
    );
  }
}

// ---- helpers ----

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

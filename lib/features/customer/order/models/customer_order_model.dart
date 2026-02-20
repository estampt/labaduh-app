// Updated models for /api/v1/customer/orders/latest
// Supports BOTH older format and latest format that includes nested:
// - order.vendor_shop / accepted_shop
// - item.service {id,name,description}
// - option.service_option {id,name,description}
// ✅ Also supports /orders/by_id/{id} where:
// - data is a SINGLE object: {"data": {...}}
// - includes media_attachments: [{..., url, category, ...}]
// - includes item qty_estimated / qty_actual

/// Holds current list + cursor
class CustomerOrderState {
  final List<CustomerOrder> orders;
  final String? cursor;
  final bool isLoadingMore;

  const CustomerOrderState({
    required this.orders,
    required this.cursor,
    required this.isLoadingMore,
  });

  CustomerOrderState copyWith({
    List<CustomerOrder>? orders,
    String? cursor,
    bool? isLoadingMore,
  }) {
    return CustomerOrderState(
      orders: orders ?? this.orders,
      cursor: cursor ?? this.cursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class CustomerOrders {
  CustomerOrders({
    required this.data,
    required this.cursor,
  });

  final List<CustomerOrder> data;
  final String? cursor;

  factory CustomerOrders.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];

    // ✅ Supports:
    // - {"data":[...]}  (list)
    // - {"data":{...}}  (single object)
    final List<dynamic> list = raw is List
        ? raw
        : (raw is Map ? <dynamic>[raw] : const <dynamic>[]);

    return CustomerOrders(
      data: list
          .map((e) => CustomerOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      cursor: json['cursor']?.toString(),
    );
  }
}

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.status,
    required this.pricingStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.mediaAttachments,

    // totals (older/newer)
    this.estimatedTotal,
    this.finalTotal,
    this.total,

    // ✅ NEW: currency + fee breakdown (API keys: currency, subtotal, delivery_fee, service_fee, discount, total)
    this.currency,
    this.subtotal,
    this.deliveryFee,
    this.serviceFee,
    this.discount,

    //Weight review
    this.pricingNotes,
    this.notes,

    // partner info
    this.vendorShop,
    this.acceptedShop,
    this.shop,
    this.driver,
  });

  final int id;
  final String status;
  final String pricingStatus;
  final String createdAt;
  final String updatedAt;

  // totals (new format - string)
  final String? total;

  // totals (old format - string)
  final String? estimatedTotal;
  final String? finalTotal;

  // ✅ NEW: fee breakdown (numeric; parsed from string/num)
  final String? currency;
  final num? subtotal;
  final num? deliveryFee;
  final num? serviceFee;
  final num? discount;

  // partner info
  final VendorShop? vendorShop;   // new: vendor_shop
  final VendorShop? acceptedShop; // new: accepted_shop (subset)
  final VendorShop? shop;         // old: shop
  final OrderDriver? driver;

  final List<CustomerOrderItem> items;

  // ✅ New: media_attachments (weight_review, delivery_proof, etc.)
  final List<CustomerMediaAttachment> mediaAttachments;
  
  final String? pricingNotes;
  final String? notes;

  VendorShop? get partner => vendorShop ?? acceptedShop ?? shop;

  // ✅ Convenience getters for UI (so UI never shows 0 by mistake)
  String get currencyCode =>
      (currency == null || currency!.trim().isEmpty) ? 'SGD' : currency!.trim();

  num get subtotalAmount => subtotal ?? 0;
  num get deliveryFeeAmount => deliveryFee ?? 0;
  num get serviceFeeAmount => serviceFee ?? 0;
  num get discountAmount => discount ?? 0;

  // Prefer json['total'] (new). Fallback to old total fields.
  num get totalAmount =>
      _asNum(total) ?? _asNum(finalTotal) ?? _asNum(estimatedTotal) ?? 0;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = (rawItems is List)
        ? rawItems
            .map((e) =>
                CustomerOrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <CustomerOrderItem>[];

    final rawMedia = json['media_attachments'];
    final media = (rawMedia is List)
        ? rawMedia
            .map((e) => CustomerMediaAttachment.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <CustomerMediaAttachment>[];

    return CustomerOrder(
      id: _asInt(json['id']) ?? 0,
      status: (json['status'] ?? '').toString(),
      pricingStatus: (json['pricing_status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),

      // totals
      total: json['total']?.toString(),
      estimatedTotal: json['estimated_total']?.toString(),
      finalTotal: json['final_total']?.toString(),

      // ✅ NEW: currency + fees (match your API exactly)
      currency: json['currency']?.toString(),
      subtotal: _asNum(json['subtotal']),
      deliveryFee: _asNum(json['delivery_fee']),
      serviceFee: _asNum(json['service_fee']),
      discount: _asNum(json['discount']),

      vendorShop: json['vendor_shop'] is Map
          ? VendorShop.fromJson(Map<String, dynamic>.from(json['vendor_shop']))
          : null,
      acceptedShop: json['accepted_shop'] is Map
          ? VendorShop.fromJson(
              Map<String, dynamic>.from(json['accepted_shop']))
          : null,
      shop: json['shop'] is Map
          ? VendorShop.fromJson(Map<String, dynamic>.from(json['shop']))
          : null,
      driver: json['driver'] is Map
          ? OrderDriver.fromJson(Map<String, dynamic>.from(json['driver']))
          : null,
      items: items,

      // ✅ media attachments
      mediaAttachments: media,
    );
  }
}

class CustomerOrderItem {
  CustomerOrderItem({
    required this.id,
    required this.serviceId,
    required this.qty,
    this.qtyEstimated,
    this.qtyActual,
    this.uom,
    this.price,
    this.computedPrice,
    this.service,
    required this.options,
  });

  final int id;
  final int serviceId;
  final num qty;

  // ✅ New: qty_estimated / qty_actual (strings or nums from API)
  final num? qtyEstimated;
  final num? qtyActual;

  final String? uom;

  // old format: price
  final String? price;

  // new format: computed_price
  final String? computedPrice;

  // new: nested service
  final OrderService? service;

  final List<CustomerOrderItemOption> options;

  String? get displayPrice => computedPrice ?? price;

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final opts = (rawOptions is List)
        ? rawOptions
            .map((e) => CustomerOrderItemOption.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList()
        : <CustomerOrderItemOption>[];

    return CustomerOrderItem(
      id: _asInt(json['id']) ?? 0,
      serviceId: _asInt(json['service_id']) ?? 0,
      qty: _asNum(json['qty']) ?? 0,
      qtyEstimated: _asNum(json['qty_estimated']),
      qtyActual: _asNum(json['qty_actual']),
      uom: json['uom']?.toString(),
      price: json['price']?.toString(),
      computedPrice: json['computed_price']?.toString(),
      service: json['service'] is Map
          ? OrderService.fromJson(Map<String, dynamic>.from(json['service']))
          : null,
      options: opts,
    );
  }
}

class CustomerOrderItemOption {
  CustomerOrderItemOption({
    required this.id,
    this.name,
    this.price,
    this.computedPrice,
    this.isRequired,
    this.serviceOptionId,
    this.serviceOption,
  });

  final int id;

  // old format may include name; new format uses nested service_option
  final String? name;

  // old: price
  final String? price;

  // new: computed_price
  final String? computedPrice;

  final bool? isRequired;
  final int? serviceOptionId;

  // new: nested service_option
  final CustomerOrderServiceOPtion? serviceOption;

  String? get displayName =>
      serviceOption?.name ?? ((name?.trim().isNotEmpty ?? false) ? name : null);

  String? get displayPrice => computedPrice ?? price;

  factory CustomerOrderItemOption.fromJson(Map<String, dynamic> json) {
    return CustomerOrderItemOption(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      price: json['price']?.toString(),
      computedPrice: json['computed_price']?.toString(),
      isRequired:
          json['is_required'] == null ? null : _asBool(json['is_required']),
      serviceOptionId: _asInt(json['service_option_id']),
      serviceOption: json['service_option'] is Map
          ? CustomerOrderServiceOPtion.fromJson(
              Map<String, dynamic>.from(json['service_option']))
          : null,
    );
  }
}

class OrderService {
  OrderService({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory OrderService.fromJson(Map<String, dynamic> json) {
    return OrderService(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }
}

class CustomerOrderServiceOPtion {
  CustomerOrderServiceOPtion(
      {required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory CustomerOrderServiceOPtion.fromJson(Map<String, dynamic> json) {
    return CustomerOrderServiceOPtion(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }
}

class VendorShop {
  VendorShop({
    required this.id,
    required this.name,
    this.profilePhotoUrl,
    this.avgRating,
    this.ratingsCount,
    this.distanceKm,
  });

  final int id;
  final String name;
  final String? profilePhotoUrl;
  final double? avgRating;
  final int? ratingsCount;
  final double? distanceKm;

  factory VendorShop.fromJson(Map<String, dynamic> json) {
    return VendorShop(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      profilePhotoUrl:
          (json['profile_photo_url'] ?? json['profilePhotoUrl'])?.toString(),
      avgRating: _asDouble(json['avg_rating']),
      ratingsCount: _asInt(json['ratings_count']),
      distanceKm: _asDouble(json['distance_km']),
    );
  }
}

class OrderDriver {
  OrderDriver({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory OrderDriver.fromJson(Map<String, dynamic> json) {
    return OrderDriver(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class CustomerMediaAttachment {
  CustomerMediaAttachment({
    required this.id,
    required this.ownerId,
    this.disk,
    this.path,
    this.mime,
    this.sizeBytes,
    this.category,
    this.createdAt,
    this.url,
  });

  final int id;
  final int ownerId;
  final String? disk;
  final String? path;
  final String? mime;
  final int? sizeBytes;
  final String? category;
  final String? createdAt;
  final String? url;

  factory CustomerMediaAttachment.fromJson(Map<String, dynamic> json) {
    return CustomerMediaAttachment(
      id: _asInt(json['id']) ?? 0,
      ownerId: _asInt(json['owner_id']) ?? 0,
      disk: json['disk']?.toString(),
      path: json['path']?.toString(),
      mime: json['mime']?.toString(),
      sizeBytes: _asInt(json['size_bytes']),
      category: json['category']?.toString(),
      createdAt: json['created_at']?.toString(),
      url: json['url']?.toString(),
    );
  }
}

// --- helpers ---
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase().trim();
  return s == 'true' || s == '1' || s == 'yes';
}
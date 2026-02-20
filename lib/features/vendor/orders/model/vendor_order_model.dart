// vendor_order_model.dart
import 'package:labaduh/core/utils/order_status_utils.dart';

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
    // ✅ Support BOTH shapes:
    // A) vendor orders endpoint: { id, status, subtotal, ... }
    // B) broadcast endpoint: { order_id, order:{status,total,created_at}, customer:{...}, items:[...] }

    final orderObj = (json['order'] is Map)
        ? (json['order'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final id = _toInt(json['id']) ?? _toInt(json['order_id']) ?? 0;

    final status =
        (json['status'] as String?) ?? (orderObj['status'] as String?) ?? 'unknown';

    final createdAt = _toDateTime(json['created_at']) ?? _toDateTime(orderObj['created_at']);
    final updatedAt = _toDateTime(json['updated_at']) ?? _toDateTime(orderObj['updated_at']);

    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => VendorOrderItemModel.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    // totals
    final subtotal = _toDouble(json['subtotal']) ??
        _toDouble(orderObj['subtotal']) ??
        // broadcast only has `order.total` in your payload:
        _toDouble(orderObj['total']) ??
        // fallback: sum computed lines
        items.fold<double>(0, (sum, it) => sum + it.totalComputed);

    final deliveryFee = _toDouble(json['delivery_fee']) ?? _toDouble(orderObj['delivery_fee']) ?? 0;
    final serviceFee = _toDouble(json['service_fee']) ?? _toDouble(orderObj['service_fee']) ?? 0;
    final discount = _toDouble(json['discount']) ?? _toDouble(orderObj['discount']) ?? 0;

    final shopId = _toInt(json['shop_id']) ?? 0;

    final customer = (json['customer'] is Map)
        ? VendorCustomerModel.fromJson((json['customer'] as Map).cast<String, dynamic>())
        : null;

    final acceptedShop = (json['accepted_shop'] is Map)
        ? VendorShopModel.fromJson((json['accepted_shop'] as Map).cast<String, dynamic>())
        : null;

    final services = items
        .map((it) => it.service?.displayName ?? 'Service')
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    final itemsCount = _toInt(json['items_count']) ?? items.length;

    return VendorOrderModel(
      id: id,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      shopId: shopId,
      acceptedShop: acceptedShop,
      customer: customer,
      itemsCount: itemsCount,
      services: services,
      items: items,
    );
  }

  String get idLabel => '#$id';

  String get statusLabel => OrderStatusUtils.statusLabel(status);

  String get customerName => customer?.name ?? 'Customer';

  String get servicesLabel => services.isEmpty ? 'No services' : services.join(', ');

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
    final parts = [addressLine1, addressLine2, postalCode]
        .where((e) => (e ?? '').trim().isNotEmpty);
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
  final int quantity;
  final int? qtyEstimated;
  final int? qtyActual;
  final String? uom;
  final String? pricingModel;
  final double? minimum;
  final double? minPrice;
  final double? pricePerUom;
  final double? computedPrice;
  final double? estimatedPrice;
  final double? finalPrice;

  final VendorServiceModel? service;
  final List<VendorOrderOptionModel> options;

  factory VendorOrderItemModel.fromJson(Map<String, dynamic> json) {
    // ✅ qty can be "7.00" in broadcast payload
    final qty = _toInt(json['qty']) ?? _toInt(json['quantity']) ?? 1;

    // ✅ service can be nested OR snapshot fields like service_name/service_description
    VendorServiceModel? service;
    if (json['service'] is Map) {
      service = VendorServiceModel.fromJson((json['service'] as Map).cast<String, dynamic>());
    } else {
      final sid = _toInt(json['service_id']) ?? 0;
      final sname = json['service_name'] as String?;
      final sdesc = json['service_description'] as String?;
      if ((sname ?? '').trim().isNotEmpty || (sdesc ?? '').trim().isNotEmpty || sid != 0) {
        service = VendorServiceModel(id: sid, name: sname, description: sdesc);
      }
    }

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
      service: service,
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => VendorOrderOptionModel.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  String get qtyLabel {
    final u = (uom ?? '').trim();
    return u.isEmpty ? '$quantity' : '$quantity ${u.toUpperCase()}';
  }

  double get totalComputed {
    final base = computedPrice ?? estimatedPrice ?? finalPrice ?? 0.0;
    final addOns = options.fold<double>(0.0, (sum, o) => sum + (o.computedPrice ?? o.price ?? 0.0));
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
  final int qty;
  final double? price;
  final bool isRequired;
  final double? computedPrice;
  final VendorServiceOptionModel? serviceOption;

  factory VendorOrderOptionModel.fromJson(Map<String, dynamic> json) {
    final rawReq = json['is_required'];
    final req = rawReq == true || rawReq == 1 || rawReq == '1';

    VendorServiceOptionModel? opt;
    if (json['service_option'] is Map) {
      opt = VendorServiceOptionModel.fromJson(
        (json['service_option'] as Map).cast<String, dynamic>(),
      );
    } else {
      // ✅ broadcast snapshot fields: service_option_name/service_option_description
      final oid = _toInt(json['service_option_id']) ?? 0;
      final oname = json['service_option_name'] as String?;
      final odesc = json['service_option_description'] as String?;
      if ((oname ?? '').trim().isNotEmpty || (odesc ?? '').trim().isNotEmpty || oid != 0) {
        opt = VendorServiceOptionModel(id: oid, name: oname, description: odesc);
      }
    }

    return VendorOrderOptionModel(
      id: _toInt(json['id']) ?? 0,
      serviceOptionId: _toInt(json['service_option_id']),
      qty: _toInt(json['qty']) ?? 1,
      price: _toDouble(json['price']),
      isRequired: req,
      computedPrice: _toDouble(json['computed_price']),
      serviceOption: opt,
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
// Helpers
// ----------------------------

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    // ✅ handles "7.00"
    final asInt = int.tryParse(s);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(s);
    if (asDouble != null) return asDouble.toInt();
  }
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
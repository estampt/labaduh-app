bool _asBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
  }
  return fallback;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

String _asString(dynamic v, {String fallback = ''}) {
  if (v == null) return fallback;
  return v.toString();
}

class ServiceOptionDto {
  final int id;
  final String name;
  final String description;
  final String kind;
  final String? price;
  final bool isActive;
  final int sortOrder;

  ServiceOptionDto({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    this.price,
    required this.isActive,
    required this.sortOrder,
  });

  factory ServiceOptionDto.fromJson(Map<String, dynamic> j) => ServiceOptionDto(
        id: _asInt(j['id']),
        name: _asString(j['name']),
        description: _asString(j['description']),
        kind: _asString(j['kind']),
        price: j['price']?.toString(),
        isActive: _asBool(j['is_active'], fallback: false),
        sortOrder: _asInt(j['sort_order']),
      );
}

class ShopServiceOptionDto {
  final int id;
  final String name;
  final String description;
  final int shopServiceId;
  final int serviceOptionId;
  final String price;
  final bool isActive;
  final int sortOrder;
  final ServiceOptionDto? serviceOption;

  ShopServiceOptionDto({
    required this.id,
    required this.name,
    required this.description,
    required this.shopServiceId,
    required this.serviceOptionId,
    required this.price,
    required this.isActive,
    required this.sortOrder,
    this.serviceOption,
  });

  /// ✅ Supports API shape:
  /// options[] = ServiceOption + pivot{shop_service_id, service_option_id, price, is_active, sort_order}
  factory ShopServiceOptionDto.fromJson(Map<String, dynamic> j) {
    final pivot = (j['pivot'] is Map<String, dynamic>)
        ? (j['pivot'] as Map<String, dynamic>)
        : const <String, dynamic>{};

    return ShopServiceOptionDto(
      // using the ServiceOption id as this object's id (since no pivot id exists)
      id: _asInt(j['id']),
      name: _asString(j['name']),
      description: _asString(j['description']),

      shopServiceId: _asInt(pivot['shop_service_id']),
      serviceOptionId: _asInt(pivot['service_option_id'] ?? j['id']),

      // ✅ prefer pivot price (shop-specific)
      price: (pivot['price'] ?? j['price'])?.toString() ?? '0.00',

      isActive: _asBool(pivot['is_active'] ?? j['is_active'], fallback: false),

      sortOrder: _asInt(pivot['sort_order'] ?? j['sort_order']),

      // ✅ service option details are the object itself
      serviceOption: ServiceOptionDto.fromJson(j),
    );
  }
}

import 'shop_service_options_dtos.dart'; // <- add this import

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

class ServiceDto {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final String? icon;
  final String? baseUnit;

  ServiceDto({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.icon,
    this.baseUnit,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> j) => ServiceDto(
        id: _asInt(j['id']),
        name: _asString(j['name']),
        description: j['description']?.toString(),
        // ✅ API uses is_active (often bool/int/string). Some older payloads use "active".
        isActive: _asBool(j['is_active'] ?? j['active'], fallback: true),
        icon: j['icon']?.toString(),
        baseUnit: j['base_unit']?.toString(),
      );
}

class ShopServiceDto {
  final int id;
  final int shopId;
  final int serviceId;
  final String pricingModel;
  final String uom;
  final String? minimum;
  final String? minPrice;
  final String? pricePerUom;
  final bool isActive;
  final String currency;
  final int sortOrder;
  final ServiceDto? service;
  final List<ShopServiceOptionDto> options;

  ShopServiceDto({
    required this.id,
    required this.shopId,
    required this.serviceId,
    required this.pricingModel,
    required this.uom,
    this.minimum,
    this.minPrice,
    this.pricePerUom,
    required this.isActive,
    required this.currency,
    required this.sortOrder,
    this.service,
    this.options = const [], // ✅ default empty
  });

  factory ShopServiceDto.fromJson(Map<String, dynamic> j) => ShopServiceDto(
        id: _asInt(j['id']),
        shopId: _asInt(j['shop_id']),
        serviceId: _asInt(j['service_id']),
        pricingModel: _asString(j['pricing_model']),
        uom: _asString(j['uom']),
        minimum: j['minimum']?.toString(),
        minPrice: j['min_price']?.toString(),
        pricePerUom: j['price_per_uom']?.toString(),
        isActive: _asBool(j['is_active'], fallback: false),
        currency: _asString(j['currency'], fallback: 'SGD'),
        sortOrder: _asInt(j['sort_order']),
        service: (j['service'] is Map<String, dynamic>)
            ? ServiceDto.fromJson(j['service'] as Map<String, dynamic>)
            : null,
        options: (j['options'] is List)
            ? (j['options'] as List)
                .whereType<Map<String, dynamic>>()
                .map(ShopServiceOptionDto.fromJson)
                .toList()
            : const [],
      );
}

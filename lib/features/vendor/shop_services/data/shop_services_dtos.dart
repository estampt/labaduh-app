import 'shop_service_options_dtos.dart'; // <- add this import


class ServiceDto {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final String? icon;
  final String? baseUnit;

  ServiceDto({required this.id, required this.name, this.description, this.isActive = true, this.icon, this.baseUnit});

  factory ServiceDto.fromJson(Map<String, dynamic> j) => ServiceDto(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        description: j['description'] as String?,
        isActive: (j['active'] ?? false) as bool,
        icon: j['icon'] as String?,
        baseUnit: j['base_unit'] as String?,
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
        id: j['id'] as int,
        shopId: j['shop_id'] as int,
        serviceId: j['service_id'] as int,
        pricingModel: (j['pricing_model'] ?? '') as String,
        uom: (j['uom'] ?? '') as String,
        minimum: j['minimum']?.toString(),
        minPrice: j['min_price']?.toString(),
        pricePerUom: j['price_per_uom']?.toString(),
        isActive: (j['is_active'] ?? false) as bool,
        currency: (j['currency'] ?? 'SGD') as String,
        sortOrder: (j['sort_order'] ?? 0) as int,
        service: j['service'] == null ? null : ServiceDto.fromJson(j['service']),
        options: (j['options'] is List)
          ? (j['options'] as List)
              .cast<Map<String, dynamic>>()
              .map(ShopServiceOptionDto.fromJson)
              .toList()
          : const [],
      );
}

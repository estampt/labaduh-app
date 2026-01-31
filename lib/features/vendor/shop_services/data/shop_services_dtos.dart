class ServiceDto {
  final int id;
  final String name;
  final String? icon;

  ServiceDto({required this.id, required this.name, this.icon});

  factory ServiceDto.fromJson(Map<String, dynamic> j) => ServiceDto(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        icon: j['icon'] as String?,
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
      );
}

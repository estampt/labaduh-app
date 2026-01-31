class ServiceOptionDto {
  final int id;
  final String name;
  final String? description;
  final String kind;
  final String? price;
  final bool isActive;
  final int sortOrder;

  ServiceOptionDto({
    required this.id,
    required this.name,
    this.description,
    required this.kind,
    this.price,
    required this.isActive,
    required this.sortOrder,
  });

  factory ServiceOptionDto.fromJson(Map<String, dynamic> j) => ServiceOptionDto(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        description: j['description'] as String?,
        kind: (j['kind'] ?? '') as String,
        price: j['price']?.toString(),
        isActive: (j['is_active'] ?? false) as bool,
        sortOrder: (j['sort_order'] ?? 0) as int,
      );
}

class ShopServiceOptionDto {
  final int id;
  final int shopServiceId;
  final int serviceOptionId;
  final String price;
  final bool isActive;
  final int sortOrder;
  final ServiceOptionDto? serviceOption;

  ShopServiceOptionDto({
    required this.id,
    required this.shopServiceId,
    required this.serviceOptionId,
    required this.price,
    required this.isActive,
    required this.sortOrder,
    this.serviceOption,
  });

  factory ShopServiceOptionDto.fromJson(Map<String, dynamic> j) =>
    ShopServiceOptionDto(
      id: j['id'] as int,
      shopServiceId: j['shop_service_id'] as int,
      serviceOptionId: j['service_option_id'] as int,
      price: j['price']?.toString() ?? '0.00',
      isActive: (j['is_active'] ?? false) as bool,
      sortOrder: (j['sort_order'] ?? 0) as int,
      serviceOption: j['service_option'] == null
          ? null
          : ServiceOptionDto.fromJson(
              (j['service_option'] as Map<String, dynamic>),
            ),
    );

}

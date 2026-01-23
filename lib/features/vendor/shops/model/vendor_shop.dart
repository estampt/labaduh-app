class VendorShop {
  final int id;
  final int vendorId;
  final String name;
  final String? phone;

  final String? addressLine1;
  final String? addressLine2;
  final String? postalCode;

  final int? countryId;
  final int? stateProvinceId;
  final int? cityId;

  final String latitude;
  final String longitude;

  final int? defaultMaxOrdersPerDay;
  final String? defaultMaxKgPerDay;

  final bool isActive;

  VendorShop({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.postalCode,
    required this.countryId,
    required this.stateProvinceId,
    required this.cityId,
    required this.latitude,
    required this.longitude,
    required this.defaultMaxOrdersPerDay,
    required this.defaultMaxKgPerDay,
    required this.isActive,
  });

  factory VendorShop.fromJson(Map<String, dynamic> j) => VendorShop(
        id: j['id'],
        vendorId: j['vendor_id'],
        name: (j['name'] ?? '').toString(),
        phone: j['phone']?.toString(),
        addressLine1: j['address_line1']?.toString(),
        addressLine2: j['address_line2']?.toString(),
        postalCode: j['postal_code']?.toString(),
        countryId: j['country_id'],
        stateProvinceId: j['state_province_id'],
        cityId: j['city_id'],
        latitude: (j['latitude'] ?? '').toString(),
        longitude: (j['longitude'] ?? '').toString(),
        defaultMaxOrdersPerDay: j['default_max_orders_per_day'],
        defaultMaxKgPerDay: j['default_max_kg_per_day']?.toString(),
        isActive: j['is_active'] == true,
      );
}

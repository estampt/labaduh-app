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
  final double? latitude;
  final double? longitude;
  final int? defaultMaxOrdersPerDay;
  final double? defaultMaxKgPerDay;
  final String? profilePhotoURL;
  final bool isActive;

  VendorShop({
    required this.id,
    required this.vendorId,
    required this.name,
    this.phone,
    this.addressLine1,
    this.addressLine2,
    this.postalCode,
    this.countryId,
    this.stateProvinceId,
    this.cityId,
    this.latitude,
    this.longitude,
    this.defaultMaxOrdersPerDay,
    this.defaultMaxKgPerDay,
    this.profilePhotoURL,
    required this.isActive,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory VendorShop.fromJson(Map<String, dynamic> json) {
    return VendorShop(
      id: _toInt(json['id']) ?? 0,
      vendorId: _toInt(json['vendor_id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      postalCode: json['postal_code']?.toString(),
      countryId: _toInt(json['country_id']),
      stateProvinceId: _toInt(json['state_province_id']),
      cityId: _toInt(json['city_id']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      defaultMaxOrdersPerDay: _toInt(json['default_max_orders_per_day']),
      defaultMaxKgPerDay: _toDouble(json['default_max_kg_per_day']),
      profilePhotoURL: json['profile_photo_url']?.toString(),
      isActive: json['is_active'] == true,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'postal_code': postalCode,
      'country_id': countryId,
      'state_province_id': stateProvinceId,
      'city_id': cityId,
      'latitude': latitude?.toString(),
      'longitude': longitude?.toString(),
      'default_max_orders_per_day': defaultMaxOrdersPerDay,
      'default_max_kg_per_day': defaultMaxKgPerDay?.toStringAsFixed(2),
      'profile_photo_url': profilePhotoURL,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateJson() => toCreateJson();

  VendorShop copyWith({
    String? name,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? postalCode,
    int? countryId,
    int? stateProvinceId,
    int? cityId,
    double? latitude,
    double? longitude,
    int? defaultMaxOrdersPerDay,
    double? defaultMaxKgPerDay,
    String? profilePhotoURL,
    bool? isActive,
  }) {
    return VendorShop(
      id: id,
      vendorId: vendorId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      postalCode: postalCode ?? this.postalCode,
      countryId: countryId ?? this.countryId,
      stateProvinceId: stateProvinceId ?? this.stateProvinceId,
      cityId: cityId ?? this.cityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      defaultMaxOrdersPerDay: defaultMaxOrdersPerDay ?? this.defaultMaxOrdersPerDay,
      defaultMaxKgPerDay: defaultMaxKgPerDay ?? this.defaultMaxKgPerDay,
      profilePhotoURL: profilePhotoURL ?? this.profilePhotoURL,
      isActive: isActive ?? this.isActive,
    );
  }
}

class VendorServicePrice {
  VendorServicePrice({
    required this.serviceId,
    required this.serviceName,
    required this.baseKg,
    required this.basePrice,
    required this.excessPerKg,
  });

  final String serviceId;
  final String serviceName;
  final int baseKg;
  final int basePrice;
  final int excessPerKg;

  VendorServicePrice copyWith({int? baseKg, int? basePrice, int? excessPerKg}) {
    return VendorServicePrice(
      serviceId: serviceId,
      serviceName: serviceName,
      baseKg: baseKg ?? this.baseKg,
      basePrice: basePrice ?? this.basePrice,
      excessPerKg: excessPerKg ?? this.excessPerKg,
    );
  }
}

class VendorPricing {
  const VendorPricing({required this.useSystemPricing, required this.services});
  final bool useSystemPricing;
  final List<VendorServicePrice> services;

  VendorPricing copyWith({bool? useSystemPricing, List<VendorServicePrice>? services}) {
    return VendorPricing(
      useSystemPricing: useSystemPricing ?? this.useSystemPricing,
      services: services ?? this.services,
    );
  }
}

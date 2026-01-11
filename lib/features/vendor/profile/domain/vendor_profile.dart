class VendorProfile {
  const VendorProfile({
    required this.shopName,
    required this.address,
    required this.openHours,
    required this.capacityKgPerDay,
    required this.vacationMode,
  });

  final String shopName;
  final String address;
  final String openHours;
  final int capacityKgPerDay;
  final bool vacationMode;

  VendorProfile copyWith({
    String? shopName,
    String? address,
    String? openHours,
    int? capacityKgPerDay,
    bool? vacationMode,
  }) {
    return VendorProfile(
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      openHours: openHours ?? this.openHours,
      capacityKgPerDay: capacityKgPerDay ?? this.capacityKgPerDay,
      vacationMode: vacationMode ?? this.vacationMode,
    );
  }
}

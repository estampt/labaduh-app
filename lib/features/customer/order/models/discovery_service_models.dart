class DiscoveryServiceRow {
  final int serviceId;
  final ServiceInfo service;

  final num baseQty;
  final num basePriceMin;
  final num basePriceMax;
  final num excessPriceMin;
  final num excessPriceMax;

  DiscoveryServiceRow({
    required this.serviceId,
    required this.service,
    required this.baseQty,
    required this.basePriceMin,
    required this.basePriceMax,
    required this.excessPriceMin,
    required this.excessPriceMax,
  });

  static num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  factory DiscoveryServiceRow.fromJson(Map<String, dynamic> j) {
    return DiscoveryServiceRow(
      serviceId: j['service_id'] as int,
      service: ServiceInfo.fromJson(Map<String, dynamic>.from(j['service'])),
      baseQty: _toNum(j['base_qty']),
      basePriceMin: _toNum(j['base_price_min']),
      basePriceMax: _toNum(j['base_price_max']),
      excessPriceMin: _toNum(j['excess_price_min']),
      excessPriceMax: _toNum(j['excess_price_max']),
    );
  }
}

class ServiceInfo {
  final int id;
  final String name;
  final String? icon;
  final String baseUnit; // kg | pc

  ServiceInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.baseUnit,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> j) => ServiceInfo(
        id: j['id'] as int,
        name: (j['name'] ?? '').toString(),
        icon: j['icon']?.toString(),
        baseUnit: (j['base_unit'] ?? 'kg').toString(),
      );
}

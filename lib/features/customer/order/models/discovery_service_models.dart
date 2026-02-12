class DiscoveryServiceRow {
  final int serviceId;
  final ServiceInfo service;

  final num baseQty;
  final num basePriceMin;
  final num basePriceMax;
  final num excessPriceMin;
  final num excessPriceMax;

  // ✅ New API fields (backward compatible)
  final List<ServiceOptionItem> addons;
  final List<DiscoveryOptionGroup> optionGroups;

  DiscoveryServiceRow({
    required this.serviceId,
    required this.service,
    required this.baseQty,
    required this.basePriceMin,
    required this.basePriceMax,
    required this.excessPriceMin,
    required this.excessPriceMax,
    this.addons = const [],
    this.optionGroups = const [],
  });

  static num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
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

      // ✅ These keys may not exist in old API → default to empty lists.
      addons: ((j['addons'] as List?) ?? const [])
          .map((e) => ServiceOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.isActive)
          .toList(),
      optionGroups: ((j['option_groups'] as List?) ?? const [])
          .map((e) => DiscoveryOptionGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
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

// ----------------------------------------------------------------------------
// ✅ New: Options / Add-ons models
// ----------------------------------------------------------------------------

class DiscoveryOptionGroup {
  final String? groupKey;
  final bool isRequired;
  final bool isMultiSelect;
  final List<ServiceOptionItem> items;

  const DiscoveryOptionGroup({
    required this.groupKey,
    required this.isRequired,
    required this.isMultiSelect,
    required this.items,
  });

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  factory DiscoveryOptionGroup.fromJson(Map<String, dynamic> j) {
    final items = ((j['items'] as List?) ?? const [])
        .map((e) => ServiceOptionItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return DiscoveryOptionGroup(
      groupKey: j['group_key']?.toString(),
      isRequired: _toBool(j['is_required']),
      isMultiSelect: _toBool(j['is_multi_select']),
      items: items,
    );
  }
}

class ServiceOptionItem {
  final int id;
  final String kind; // addon | option
  final String? groupKey;
  final String name;
  final String? description;

  final num priceMin;
  final num priceMax;
  final String priceType; // fixed | etc

  final bool isRequired;
  final bool isMultiSelect;
  final bool isDefaultSelected;

  final int sortOrder;
  final bool isActive;

  const ServiceOptionItem({
    required this.id,
    required this.kind,
    required this.groupKey,
    required this.name,
    required this.description,
    required this.priceMin,
    required this.priceMax,
    required this.priceType,
    required this.isRequired,
    required this.isMultiSelect,
    required this.isDefaultSelected,
    required this.sortOrder,
    required this.isActive,
  });

  static num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  factory ServiceOptionItem.fromJson(Map<String, dynamic> j) {
    return ServiceOptionItem(
      id: (j['id'] ?? 0) as int,
      kind: (j['kind'] ?? '').toString(),
      groupKey: j['group_key']?.toString(),
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      priceMin: _toNum(j['price_min']),
      priceMax: _toNum(j['price_max']),
      priceType: (j['price_type'] ?? 'fixed').toString(),
      isRequired: _toBool(j['is_required']),
      isMultiSelect: _toBool(j['is_multi_select']),
      isDefaultSelected: _toBool(j['is_default_selected']),
      sortOrder: (j['sort_order'] ?? 0) as int,
      isActive: _toBool(j['is_active']),
    );
  }
}

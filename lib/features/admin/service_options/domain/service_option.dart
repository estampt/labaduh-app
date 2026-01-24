enum ServiceOptionKind { option, addon }
enum ServiceOptionPriceType { fixed, perKg, perItem }

class ServiceOption {
  final int id;
  final String name;
  final String? description;
  final ServiceOptionKind kind;
  final String? groupKey;
  final String price; // keep string to avoid double issues
  final ServiceOptionPriceType priceType;
  final bool isRequired;
  final bool isMultiSelect;
  final bool? isDefaultSelected; // nullable
  final int sortOrder;
  final bool isActive;

  ServiceOption({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.groupKey,
    required this.price,
    required this.priceType,
    required this.isRequired,
    required this.isMultiSelect,
    required this.isDefaultSelected,
    required this.sortOrder,
    required this.isActive,
  });

  static ServiceOptionKind _kindFrom(String v) =>
      v == 'addon' ? ServiceOptionKind.addon : ServiceOptionKind.option;

  static ServiceOptionPriceType _priceTypeFrom(String v) {
    switch (v) {
      case 'per_kg':
        return ServiceOptionPriceType.perKg;
      case 'per_item':
        return ServiceOptionPriceType.perItem;
      default:
        return ServiceOptionPriceType.fixed;
    }
  }

  factory ServiceOption.fromJson(Map<String, dynamic> j) {
    return ServiceOption(
      id: j['id'] as int,
      name: (j['name'] ?? '') as String,
      description: j['description'] as String?,
      kind: _kindFrom((j['kind'] ?? 'option') as String),
      groupKey: j['group_key'] as String?,
      price: (j['price'] ?? '0.00').toString(),
      priceType: _priceTypeFrom((j['price_type'] ?? 'fixed') as String),
      isRequired: (j['is_required'] ?? false) as bool,
      isMultiSelect: (j['is_multi_select'] ?? false) as bool,
      isDefaultSelected: j['is_default_selected'] as bool?,
      sortOrder: (j['sort_order'] ?? 0) as int,
      isActive: (j['is_active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toPayload() {
    String kindTo(ServiceOptionKind k) => k == ServiceOptionKind.addon ? 'addon' : 'option';
    String ptTo(ServiceOptionPriceType p) {
      switch (p) {
        case ServiceOptionPriceType.perKg:
          return 'per_kg';
        case ServiceOptionPriceType.perItem:
          return 'per_item';
        default:
          return 'fixed';
      }
    }

    final m = <String, dynamic>{
      'name': name,
      'description': description,
      'kind': kindTo(kind),
      'group_key': groupKey,
      'price': price,
      'price_type': ptTo(priceType),
      'is_required': isRequired,
      'is_multi_select': isMultiSelect,
      'sort_order': sortOrder,
      'is_active': isActive,
    };

    if (isDefaultSelected != null) {
      m['is_default_selected'] = isDefaultSelected;
    }

    return m;
  }

  ServiceOption copyWith({
    int? id,
    String? name,
    String? description,
    ServiceOptionKind? kind,
    String? groupKey,
    String? price,
    ServiceOptionPriceType? priceType,
    bool? isRequired,
    bool? isMultiSelect,
    bool? isDefaultSelected,
    int? sortOrder,
    bool? isActive,
  }) {
    return ServiceOption(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      groupKey: groupKey ?? this.groupKey,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      isRequired: isRequired ?? this.isRequired,
      isMultiSelect: isMultiSelect ?? this.isMultiSelect,
      isDefaultSelected: isDefaultSelected ?? this.isDefaultSelected,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

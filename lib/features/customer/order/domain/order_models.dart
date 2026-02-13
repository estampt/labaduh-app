enum PickupOption { asap, tomorrow, scheduled }
enum DeliveryOption { pickupAndDeliver, walkIn }
enum UnitType { kilo, piece }

class ServiceCatalogItem {
  final int id;
  final String name;
  final num baseQty;
  final UnitType unitType;
  final num basePrice;
  final num excessPerUnit;
  final String? icon;
  
  const ServiceCatalogItem({
    required this.id,
    required this.name,
    required this.baseQty,
    required this.unitType,
    required this.basePrice,
    required this.excessPerUnit,
    this.icon,
  });
}

class ServiceSelection {
  final ServiceCatalogItem service;
  final int qty;

  const ServiceSelection({
    required this.service,
    required this.qty,
  });

  String get unitLabel => service.unitType == UnitType.kilo ? 'KG' : 'pc';
  String get qtyLabel => '$qty $unitLabel';

  num get price {
    final extra = (qty - service.baseQty);
    return service.basePrice + (extra > 0 ? extra * service.excessPerUnit : 0);
  }

  Map<String, dynamic> toPayload() {
    return {
      'service_id': service.id,
      'qty': qty,
      'options': <Map<String, dynamic>>[],
    };
  }

  ServiceSelection copyWith({int? qty}) =>
      ServiceSelection(service: service, qty: qty ?? this.qty);
}


class OrderDraft {
  final List<ServiceSelection> selections;
  final PickupOption pickupOption;
  final DeliveryOption deliveryOption;
  final String addressLabel;

  const OrderDraft({
    required this.selections,
    required this.pickupOption,
    required this.deliveryOption,
    required this.addressLabel,
  });

  factory OrderDraft.initial() => const OrderDraft(
        selections: [],
        pickupOption: PickupOption.tomorrow,
        deliveryOption: DeliveryOption.pickupAndDeliver,
        addressLabel: 'Set pickup address',
      );

  num get subtotal =>
      selections.fold<num>(0, (sum, s) => sum + s.price);

  num get deliveryFee =>
      deliveryOption == DeliveryOption.walkIn ? 0 : 49;

  num get serviceFee => 15;

  num get total => subtotal + deliveryFee + serviceFee;

  List<Map<String, dynamic>> toItemsPayload() =>
      selections.map((s) => s.toPayload()).toList();

  OrderDraft copyWith({
    List<ServiceSelection>? selections,
    PickupOption? pickupOption,
    DeliveryOption? deliveryOption,
    String? addressLabel,
  }) {
    return OrderDraft(
      selections: selections ?? this.selections,
      pickupOption: pickupOption ?? this.pickupOption,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      addressLabel: addressLabel ?? this.addressLabel,
    );
  }
}

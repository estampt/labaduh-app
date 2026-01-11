enum UnitType { kilo, piece }

class LaundryService {
  LaundryService({
    required this.id,
    required this.name,
    required this.baseQty,
    required this.unitType,
    required this.basePrice,
    this.excessPerUnit = 0,
    this.icon,
  });

  final String id;
  final String name;
  final int baseQty;
  final UnitType unitType;
  final int basePrice;
  final int excessPerUnit;
  final String? icon;
}

class ServiceSelection {
  const ServiceSelection({required this.service, required this.qty});
  final LaundryService service;
  final int qty;

  int get price {
    final excess = qty - service.baseQty;
    final extra = excess > 0 ? excess * service.excessPerUnit : 0;
    return service.basePrice + extra;
  }

  String get qtyLabel {
    final unit = service.unitType == UnitType.kilo ? 'KG' : 'pc';
    return '$qty $unit';
  }
}

enum PickupOption { asap, tomorrow, scheduled }
enum DeliveryOption { pickupAndDeliver, walkIn }

class OrderDraft {
  const OrderDraft({
    this.selections = const [],
    this.pickupOption = PickupOption.asap,
    this.deliveryOption = DeliveryOption.pickupAndDeliver,
    this.addressLabel = 'Set pickup address',
  });

  final List<ServiceSelection> selections;
  final PickupOption pickupOption;
  final DeliveryOption deliveryOption;
  final String addressLabel;

  int get subtotal => selections.fold<int>(0, (sum, s) => sum + s.price);
  int get deliveryFee => deliveryOption == DeliveryOption.walkIn ? 0 : 49;
  int get serviceFee => subtotal == 0 ? 0 : (subtotal * 0.05).round();
  int get total => subtotal + deliveryFee + serviceFee;

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

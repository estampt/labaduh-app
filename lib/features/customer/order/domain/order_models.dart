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

  /// e.g. 6 KG minimum, or 1 piece for blankets
  final int baseQty;

  final UnitType unitType;

  /// price for the baseQty
  final int basePrice;

  /// additional cost per extra unit above baseQty (kilo or piece)
  final int excessPerUnit;

  final String? icon;
}

class ServiceSelection {
  const ServiceSelection({required this.service, required this.qty});
  final LaundryService service;
  final int qty;

  int get price {
    final excess = (qty - service.baseQty);
    final extra = excess > 0 ? excess * service.excessPerUnit : 0;
    return service.basePrice + extra;
  }

  String get qtyLabel {
    final unit = service.unitType == UnitType.kilo ? 'KG' : 'pc';
    return '$qty $unit';
  }
}

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

  /// Simple placeholder fees (UI-only). Replace later with backend.
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

enum PickupOption { asap, tomorrow, scheduled }
enum DeliveryOption { pickupAndDeliver, walkIn }

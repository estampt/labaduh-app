class CreateOrderPayload {
  final double searchLat;
  final double searchLng;
  final int radiusKm;

  final String pickupMode;     // asap|tomorrow|schedule
  final String deliveryMode;   // pickup_deliver|walk_in

  final int pickupAddressId;
  final int deliveryAddressId;

  final List<CreateOrderItemPayload> items;

  CreateOrderPayload({
    required this.searchLat,
    required this.searchLng,
    required this.radiusKm,
    required this.pickupMode,
    required this.deliveryMode,
    required this.pickupAddressId,
    required this.deliveryAddressId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'search_lat': searchLat,
        'search_lng': searchLng,
        'radius_km': radiusKm,
        'pickup_mode': pickupMode,
        'delivery_mode': deliveryMode,
        'pickup_address_id': pickupAddressId,
        'delivery_address_id': deliveryAddressId,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class CreateOrderItemPayload {
  final int serviceId;
  final num qty;
  final String uom;
  final String pricingModel;

  final num minimum;
  final num minPrice;
  final num pricePerUom;
  final num computedPrice;

  final List<CreateOrderItemOptionPayload> options;

  CreateOrderItemPayload({
    required this.serviceId,
    required this.qty,
    required this.uom,
    required this.pricingModel,
    required this.minimum,
    required this.minPrice,
    required this.pricePerUom,
    required this.computedPrice,
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
        'service_id': serviceId,
        'qty': qty,
        'uom': uom,
        'pricing_model': pricingModel,
        'minimum': minimum,
        'min_price': minPrice,
        'price_per_uom': pricePerUom,
        'computed_price': computedPrice,
        'options': options.map((e) => e.toJson()).toList(),
      };
}

class CreateOrderItemOptionPayload {
  final int serviceOptionId;
  final num price;
  final bool isRequired;
  final num computedPrice;

  CreateOrderItemOptionPayload({
    required this.serviceOptionId,
    required this.price,
    required this.isRequired,
    required this.computedPrice,
  });

  Map<String, dynamic> toJson() => {
        'service_option_id': serviceOptionId,
        'price': price,
        'is_required': isRequired,
        'computed_price': computedPrice,
      };
}

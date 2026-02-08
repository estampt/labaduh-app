import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discovery_service_models.dart';
import '../models/order_payloads.dart';

class DraftSelectedService {
  final DiscoveryServiceRow row;
  final num qty;

  const DraftSelectedService({required this.row, required this.qty});

  DraftSelectedService copyWith({num? qty}) => DraftSelectedService(
        row: row,
        qty: qty ?? this.qty,
      );

  String get uom => row.service.baseUnit;

  // v1: estimate using MIN prices from discovery (safe)
  num get minimum => row.baseQty;
  num get minPrice => row.basePriceMin;
  num get pricePerUom => row.excessPriceMin;

  num get computedPrice {
    final q = qty;
    final minQ = minimum;
    if (q <= minQ) return minPrice;
    return minPrice + ((q - minQ) * pricePerUom);
  }
}

class OrderDraftState {
  final double lat;
  final double lng;
  final int radiusKm;

  final String pickupMode;   // asap|tomorrow|schedule
  final String deliveryMode; // pickup_deliver|walk_in

  final int pickupAddressId;   // placeholder until address module
  final int deliveryAddressId;

  final List<DraftSelectedService> services;

  const OrderDraftState({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.pickupMode,
    required this.deliveryMode,
    required this.pickupAddressId,
    required this.deliveryAddressId,
    required this.services,
  });

  OrderDraftState copyWith({
    double? lat,
    double? lng,
    int? radiusKm,
    String? pickupMode,
    String? deliveryMode,
    int? pickupAddressId,
    int? deliveryAddressId,
    List<DraftSelectedService>? services,
  }) {
    return OrderDraftState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      pickupMode: pickupMode ?? this.pickupMode,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      pickupAddressId: pickupAddressId ?? this.pickupAddressId,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      services: services ?? this.services,
    );
  }

  num get subtotal => services.fold<num>(0, (s, e) => s + e.computedPrice);

  // Placeholder fees until backend fee breakdown is final
  num get deliveryFee => deliveryMode == 'walk_in' ? 0 : 49;
  num get serviceFee => 15;
  num get discount => 0;
  num get total => subtotal + deliveryFee + serviceFee - discount;

  CreateOrderPayload toCreatePayload() {
    return CreateOrderPayload(
      searchLat: lat,
      searchLng: lng,
      radiusKm: radiusKm,
      pickupMode: pickupMode,
      deliveryMode: deliveryMode,
      pickupAddressId: pickupAddressId,
      deliveryAddressId: deliveryAddressId,
      items: services.map((s) {
        return CreateOrderItemPayload(
          serviceId: s.row.service.id,
          qty: s.qty,
          uom: s.uom,
          pricingModel: 'tiered_min_plus',
          minimum: s.minimum,
          minPrice: s.minPrice,
          pricePerUom: s.pricePerUom,
          computedPrice: s.computedPrice,
          options: const [], // add-ons later when API exists
        );
      }).toList(),
    );
  }
}

class OrderDraftController extends Notifier<OrderDraftState> {
  @override
  OrderDraftState build() {
    return const OrderDraftState(
      lat: 1.3001,
      lng: 103.8001,
      radiusKm: 50,
      pickupMode: 'tomorrow',
      deliveryMode: 'pickup_deliver',
      pickupAddressId: 10,
      deliveryAddressId: 10,
      services: [],
    );
  }

  void setLocation({required double lat, required double lng, int? radiusKm}) {
    state = state.copyWith(lat: lat, lng: lng, radiusKm: radiusKm);
  }

  void setPickupMode(String v) => state = state.copyWith(pickupMode: v);
  void setDeliveryMode(String v) => state = state.copyWith(deliveryMode: v);

  void setAddresses({required int pickupId, required int deliveryId}) {
    state = state.copyWith(pickupAddressId: pickupId, deliveryAddressId: deliveryId);
  }

  bool isSelected(int serviceId) =>
      state.services.any((e) => e.row.serviceId == serviceId);

  void toggleService(DiscoveryServiceRow row) {
    final list = [...state.services];
    final idx = list.indexWhere((e) => e.row.serviceId == row.serviceId);

    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(DraftSelectedService(row: row, qty: row.baseQty));
    }

    state = state.copyWith(services: list);
  }

  void setQty(int serviceId, num qty) {
    final list = state.services.map((e) {
      if (e.row.serviceId == serviceId) return e.copyWith(qty: qty);
      return e;
    }).toList();

    state = state.copyWith(services: list);
  }

  void reset() {
    state = build(); // reset to default initial state
  }

  bool get hasAnyService => state.services.isNotEmpty;
}

final orderDraftControllerProvider =
    NotifierProvider<OrderDraftController, OrderDraftState>(OrderDraftController.new);

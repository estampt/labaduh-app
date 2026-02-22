import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import '../models/discovery_service_models.dart';
import '../models/order_payloads.dart';

class DraftSelectedService {
  final DiscoveryServiceRow row;
  final num qty;

  // ✅ v2: selected options/add-ons (IDs)
  final Set<int> selectedOptionIds;

  const DraftSelectedService({
    required this.row,
    required this.qty,
    this.selectedOptionIds = const <int>{},
  });

  DraftSelectedService copyWith({num? qty, Set<int>? selectedOptionIds}) =>
      DraftSelectedService(
        row: row,
        qty: qty ?? this.qty,
        selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      );

  String get uom => row.service.baseUnit;

  // v1: estimate using MIN prices from discovery (safe)
  num get minimum => row.baseQty;
  num get minPrice => row.basePriceMin;
  num get pricePerUom => row.excessPriceMin;

  Map<int, ServiceOptionItem> get _optionIndex {
    final m = <int, ServiceOptionItem>{};
    for (final a in row.addons) {
      m[a.id] = a;
    }
    for (final g in row.optionGroups) {
      for (final it in g.items) {
        m[it.id] = it;
      }
    }
    return m;
  }

  num get computedPrice {
    final q = qty;
    final minQ = minimum;
    final base = (q <= minQ) ? minPrice : (minPrice + ((q - minQ) * pricePerUom));

    // ✅ Add option/add-on totals (use priceMin to match your estimation style)
    final idx = _optionIndex;
    final optTotal = selectedOptionIds.fold<num>(
      0,
      (sum, id) => sum + (idx[id]?.priceMin ?? 0),
    );

    return base + optTotal;
  }

  /// Builds payload option objects expected by CreateOrderItemPayload:
  /// List<CreateOrderItemOptionPayload>
  List<CreateOrderItemOptionPayload> buildOptionPayloads() {
    final idx = _optionIndex;
    final result = <CreateOrderItemOptionPayload>[];

    for (final id in selectedOptionIds) {
      final opt = idx[id];
      if (opt == null) continue;

      final p = opt.priceMin;
      result.add(
        CreateOrderItemOptionPayload(
          serviceOptionId: opt.id,
          price: p,
          isRequired: opt.isRequired,
          computedPrice: p,
        ),
      );
    }

    return result;
  }
}

class OrderDraftState {
  final double lat;
  final double lng;
  final int radiusKm;

  final String pickupMode;   // asap|tomorrow|schedule
  final String deliveryMode; // pickup_deliver|walk_in

  // ✅ When pickupMode == 'schedule'
  final DateTime? pickupWindowStart;
  final DateTime? pickupWindowEnd;

  final int pickupAddressId;   // placeholder until address module
  final int deliveryAddressId;

  final List<DraftSelectedService> services;

  const OrderDraftState({
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.pickupMode,
    required this.deliveryMode,
    this.pickupWindowStart,
    this.pickupWindowEnd,
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
    DateTime? pickupWindowStart,
    DateTime? pickupWindowEnd,
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
      pickupWindowStart: pickupWindowStart ?? this.pickupWindowStart,
      pickupWindowEnd: pickupWindowEnd ?? this.pickupWindowEnd,
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

  /// ✅ Main payload builder used by submit provider
  CreateOrderPayload toCreatePayload() {
  return CreateOrderPayload(
    searchLat: lat,
    searchLng: lng,
    radiusKm: radiusKm,
    pickupMode: pickupMode,
    deliveryMode: deliveryMode,
    pickupAddressId: pickupAddressId,
    deliveryAddressId: deliveryAddressId,

    // ✅ ADD THIS (API field: pickup_window_start)
    pickupWindowStart: pickupWindowStart,

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
        options: s.buildOptionPayloads(),
      );
    }).toList(),
  );
}


  // ✅ Backward-compat method (some parts of app call draft.CreateOrderPayload())
  // ignore: non_constant_identifier_names
 // CreateOrderPayload CreateOrderPayload() => toCreatePayload();

  // ✅ Another common naming pattern
  CreateOrderPayload createOrderPayload() => toCreatePayload();
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
      pickupWindowStart: null,
      pickupWindowEnd: null,
      pickupAddressId: 10,
      deliveryAddressId: 10,
      services: [],
    );
  }

  void setLocation({required double lat, required double lng, int? radiusKm}) {
    state = state.copyWith(lat: lat, lng: lng, radiusKm: radiusKm);
  }

  void setPickupMode(String v) {
    final mode = v.toLowerCase();

    // Rule:
    // - asap     -> set pickupWindowStart = now (today)
    // - tomorrow -> set pickupWindowStart = now + 1 day
    // - schedule -> keep existing window (user will pick)
    // - other    -> clear window

    if (mode == 'asap') {
      state = state.copyWith(
        pickupMode: v,
        pickupWindowStart: DateTime.now(),
        pickupWindowEnd: null,
      );
      return;
    }

  if (mode == 'tomorrow') {
    final tomorrowStart = DateTime.now().add(const Duration(days: 1));

    debugPrint('📦 Pickup Mode: tomorrow');
    debugPrint('📅 pickupWindowStart: $tomorrowStart');
    debugPrint('📅 pickupWindowEnd: null');

    state = state.copyWith(
      pickupMode: v,
      pickupWindowStart: tomorrowStart,
      pickupWindowEnd: null,
    );

    return;
  }
    if (mode == 'schedule') {
      state = state.copyWith(pickupMode: v);
      return;
    }

    state = state.copyWith(
      pickupMode: v,
      pickupWindowStart: null,
      pickupWindowEnd: null,
    );
  }

  // ✅ Schedule window setters (used by OrderScheduleScreen)
  void setPickupWindow(DateTime start, DateTime end) {
    // Setting a window implies schedule mode.
    state = state.copyWith(
      pickupMode: 'schedule',
      pickupWindowStart: start,
      pickupWindowEnd: end,
    );
  }

  void setPickupWindowStart(dynamic v) {
    final dt = _coerceDateTime(v);
    state = state.copyWith(
      pickupMode: 'schedule',
      pickupWindowStart: dt,
    );
  }

  void setPickupWindowEnd(dynamic v) {
    final dt = _coerceDateTime(v);
    state = state.copyWith(
      pickupMode: 'schedule',
      pickupWindowEnd: dt,
    );
  }

  // Some screens may call these naming variants
  void setPickupDate(dynamic v) => setPickupWindowStart(v);

  // Explicit schedule setter (also forces pickupMode to 'schedule')
  void setScheduledPickupDate(dynamic v) => setPickupWindowStart(v);


  
  void setDeliveryMode(String v) => state = state.copyWith(deliveryMode: v);

 
  DateTime? _coerceDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  void setAddresses({required int pickupId, required int deliveryId}) {
    state = state.copyWith(
      pickupAddressId: pickupId,
      deliveryAddressId: deliveryId,
    );
  }

  bool isSelected(int serviceId) =>
      state.services.any((e) => e.row.serviceId == serviceId);

  DraftSelectedService? _selected(int serviceId) {
    try {
      return state.services.firstWhere((e) => e.row.serviceId == serviceId);
    } catch (_) {
      return null;
    }
  }

  Set<int> _initialOptionSelection(DiscoveryServiceRow row) {
    final selected = <int>{};

    // Default-selected items
    for (final a in row.addons) {
      if (a.isDefaultSelected) selected.add(a.id);
    }
    for (final g in row.optionGroups) {
      for (final it in g.items) {
        if (it.isDefaultSelected) selected.add(it.id);
      }
    }

    // Ensure required groups have something selected
    for (final g in row.optionGroups) {
      if (!g.isRequired || g.items.isEmpty) continue;
      final has = g.items.any((it) => selected.contains(it.id));
      if (!has) {
        final sorted = [...g.items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        selected.add(sorted.first.id);
      }
    }

    return selected;
  }

  void toggleService(DiscoveryServiceRow row) {
    final list = [...state.services];
    final idx = list.indexWhere((e) => e.row.serviceId == row.serviceId);

    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(
        DraftSelectedService(
          row: row,
          qty: row.baseQty,
          selectedOptionIds: _initialOptionSelection(row),
        ),
      );
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

  // --------------------------------------------------------------------------
  // ✅ v2: Options selection API used by OrderServicesScreen
  // --------------------------------------------------------------------------

  void toggleAddonOption({
    required int serviceId,
    required ServiceOptionItem option,
  }) {
    final current = _selected(serviceId);
    if (current == null) return;

    final next = {...current.selectedOptionIds};
    final already = next.contains(option.id);

    // For add-ons: if not multi-select, restrict within same group_key bucket
    final bucket = option.groupKey ?? '__addon__';
    final bucketIds = current.row.addons
        .where((a) => (a.groupKey ?? '__addon__') == bucket)
        .map((a) => a.id)
        .toSet();

    if (!option.isMultiSelect) {
      if (already) {
        // if required bucket, don't allow removing last selected
        final requiredBucket = current.row.addons
            .where((a) => (a.groupKey ?? '__addon__') == bucket)
            .any((a) => a.isRequired);
        if (requiredBucket) {
          final remaining = next.difference({option.id}).intersection(bucketIds);
          if (remaining.isEmpty) return;
        }
        next.remove(option.id);
      } else {
        next.removeAll(bucketIds);
        next.add(option.id);
      }
    } else {
      if (already) {
        if (option.isRequired) {
          final remaining = next.difference({option.id}).intersection(bucketIds);
          if (remaining.isEmpty) return;
        }
        next.remove(option.id);
      } else {
        next.add(option.id);
      }
    }

    _replace(serviceId, current.copyWith(selectedOptionIds: next));
  }

  void toggleGroupedOption({
    required int serviceId,
    required DiscoveryOptionGroup group,
    required ServiceOptionItem option,
  }) {
    final current = _selected(serviceId);
    if (current == null) return;

    final next = {...current.selectedOptionIds};
    final already = next.contains(option.id);
    final groupIds = group.items.map((e) => e.id).toSet();

    if (!group.isMultiSelect) {
      if (already) {
        if (group.isRequired) {
          final remaining = next.difference({option.id}).intersection(groupIds);
          if (remaining.isEmpty) return;
        }
        next.remove(option.id);
      } else {
        next.removeAll(groupIds);
        next.add(option.id);
      }
    } else {
      if (already) {
        if (group.isRequired) {
          final remaining = next.difference({option.id}).intersection(groupIds);
          if (remaining.isEmpty) return;
        }
        next.remove(option.id);
      } else {
        next.add(option.id);
      }
    }

    _replace(serviceId, current.copyWith(selectedOptionIds: next));
  }

  void _replace(int serviceId, DraftSelectedService next) {
    final list = state.services.map((e) {
      if (e.row.serviceId == serviceId) return next;
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

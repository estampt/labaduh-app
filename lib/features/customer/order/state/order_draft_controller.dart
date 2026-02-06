import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order_models.dart';

final orderDraftProvider =
    NotifierProvider<OrderDraftController, OrderDraft>(
        OrderDraftController.new);

class OrderDraftController extends Notifier<OrderDraft> {
  @override
  OrderDraft build() => OrderDraft.initial();

  // -----------------------------
  // Get qty for UI
  // -----------------------------
  int qtyFor(int serviceId) {
    final found =
        state.selections.where((s) => s.service.id == serviceId);
    if (found.isEmpty) return 0;
    return found.first.qty;
  }

  // -----------------------------
  // Add / Update qty
  // -----------------------------
  void setServiceQty(ServiceCatalogItem service, int qty) {
    final list = [...state.selections];
    final idx =
        list.indexWhere((s) => s.service.id == service.id);

    if (qty <= 0) {
      if (idx != -1) list.removeAt(idx);
    } else if (idx == -1) {
      list.add(ServiceSelection(service: service, qty: qty));
    } else {
      list[idx] = list[idx].copyWith(qty: qty);
    }

    state = state.copyWith(selections: list);
  }

  // -----------------------------
  // REMOVE SERVICE (missing earlier)
  // -----------------------------
  void removeService(int serviceId) {
    final list = state.selections
        .where((s) => s.service.id != serviceId)
        .toList();

    state = state.copyWith(selections: list);
  }

  // -----------------------------
  // Pickup option
  // -----------------------------
  void setPickupOption(PickupOption option) {
    state = state.copyWith(pickupOption: option);
  }

  // -----------------------------
  // Delivery option
  // -----------------------------
  void setDeliveryOption(DeliveryOption option) {
    state = state.copyWith(deliveryOption: option);
  }

  // -----------------------------
  // Address label
  // -----------------------------
  void setAddressLabel(String label) {
    state = state.copyWith(addressLabel: label);
  }

  // -----------------------------
  // Reset draft
  // -----------------------------
  void reset() {
    state = OrderDraft.initial();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order_models.dart';

final orderDraftProvider = StateNotifierProvider<OrderDraftController, OrderDraft>((ref) {
  return OrderDraftController();
});

class OrderDraftController extends StateNotifier<OrderDraft> {
  OrderDraftController() : super(const OrderDraft());

  void reset() => state = const OrderDraft();

  void setAddressLabel(String label) => state = state.copyWith(addressLabel: label);
  void setPickupOption(PickupOption option) => state = state.copyWith(pickupOption: option);
  void setDeliveryOption(DeliveryOption option) => state = state.copyWith(deliveryOption: option);

  void setServiceQty(LaundryService service, int qty) {
    final minQty = service.baseQty;
    final safeQty = qty < minQty ? minQty : qty;

    final selections = [...state.selections];
    final idx = selections.indexWhere((s) => s.service.id == service.id);

    if (idx == -1) {
      selections.add(ServiceSelection(service: service, qty: safeQty));
    } else {
      selections[idx] = ServiceSelection(service: service, qty: safeQty);
    }

    state = state.copyWith(selections: selections);
  }

  void removeService(String serviceId) {
    state = state.copyWith(selections: state.selections.where((s) => s.service.id != serviceId).toList());
  }

  int qtyFor(String serviceId) {
    final found = state.selections.where((s) => s.service.id == serviceId);
    return found.isEmpty ? 0 : found.first.qty;
  }
}

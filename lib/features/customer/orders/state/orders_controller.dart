import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order_summary.dart';

final ordersProvider = StateNotifierProvider<OrdersController, List<OrderSummary>>((ref) {
  return OrdersController()..seed();
});

class OrdersController extends StateNotifier<List<OrderSummary>> {
  OrdersController() : super(const []);

  void seed() {
    state = [
      OrderSummary(
        id: '1024',
        title: 'Wash & Fold + Whites',
        createdAtLabel: 'Today, 5:10 PM',
        totalLabel: '₱ 498',
        status: OrderStatus.washing,
      ),
      OrderSummary(
        id: '1023',
        title: 'Colored (6KG)',
        createdAtLabel: 'Yesterday, 2:40 PM',
        totalLabel: '₱ 358',
        status: OrderStatus.delivered,
      ),
    ];
  }
}

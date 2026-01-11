import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/order_draft_controller.dart';
import 'widgets/section_title.dart';
import 'widgets/sticky_bottom_bar.dart';

class OrderReviewScreen extends ConsumerWidget {
  const OrderReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const SectionTitle('Services'),
              ...draft.selections.map((s) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(s.service.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(s.qtyLabel),
                    trailing: Text('₱ ${s.price}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                );
              }),

              const SizedBox(height: 18),
              const SectionTitle('Fees'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _line('Subtotal', '₱ ${draft.subtotal}'),
                      const SizedBox(height: 8),
                      _line('Delivery', '₱ ${draft.deliveryFee}'),
                      const SizedBox(height: 8),
                      _line('Service fee', '₱ ${draft.serviceFee}'),
                      const Divider(height: 20),
                      _line('Total', '₱ ${draft.total}', strong: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              const SectionTitle('Pickup details'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(draft.addressLabel),
                  subtitle: const Text('Pickup schedule selected (placeholder)'),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: StickyBottomBar(
              title: 'Total: ₱ ${draft.total}',
              subtitle: 'Next: find laundry partner',
              buttonText: 'Confirm & Find',
              onPressed: () => context.go('/c/order/matching'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String left, String right, {bool strong = false}) {
    final style = TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w600);
    return Row(
      children: [
        Expanded(child: Text(left, style: style)),
        Text(right, style: style),
      ],
    );
  }
}

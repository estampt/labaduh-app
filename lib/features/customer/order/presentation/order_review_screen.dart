import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/order_draft_controller.dart';
import '../state/order_submit_provider.dart';
import 'widgets/sticky_bottom_bar.dart';
import 'widgets/section_title.dart';
import '../../../../core/ui/service_icons.dart';

class OrderReviewScreen extends ConsumerWidget {
  const OrderReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftControllerProvider);
    final submitState = ref.watch(orderSubmitProvider);
    final isLoading = submitState.isLoading;

    String unitLabel(String baseUnit) {
      final u = baseUnit.toLowerCase().trim();
      return (u == 'kg' || u == 'kilo' || u == 'kilogram') ? 'KG' : 'pc';
    }

    Widget card({required Widget child}) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      );
    }

    Widget feeRow(String label, String value, {bool bold = false}) {
      final style = TextStyle(
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, style: style),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const SectionTitle('Services'),
              const SizedBox(height: 10),

              // ✅ Services list in cards
              ...draft.services.map((s) {
                final unit = unitLabel(s.row.service.baseUnit);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: card(
                    child: Row(
                    children: [
                      /// 🔹 SERVICE ICON
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          ServiceIcons.resolve(s.row.service.icon),
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// 🔹 NAME + QTY
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.row.service.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${s.qty} ${_unitLabel(s.row.service.baseUnit)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            
                          ],
                        ),
                      ),

                      /// 🔹 PRICE
                      Text(
                        '₱ ${s.computedPrice}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  ),
                );
              }),

              const SizedBox(height: 12),
              const SectionTitle('Fees'),
              const SizedBox(height: 10),

              // ✅ Fees card
              card(
                child: Column(
                  children: [
                    feeRow('Subtotal', '₱ ${draft.subtotal}'),
                    feeRow('Delivery', '₱ ${draft.deliveryFee}'),
                    feeRow('Service fee', '₱ ${draft.serviceFee}'),
                    const Divider(height: 18),
                    feeRow('Total', '₱ ${draft.total}', bold: true),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const SectionTitle('Pickup details'),
              const SizedBox(height: 10),

              // ✅ Pickup details card (placeholder UI, same as your design)
              card(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set pickup address',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pickupSubtitle(draft.pickupMode),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: StickyBottomBar(
              title: 'Total: ₱ ${draft.total}',
              subtitle: 'Next: find laundry partner',
              buttonText: isLoading ? 'Sending...' : 'Confirm & Find',
              enabled: !isLoading && draft.services.isNotEmpty,
              onPressed: () async {
                if (isLoading) return;

                final submitCtrl = ref.read(orderSubmitProvider.notifier);

                try {
                  final order = await submitCtrl.submit();

                  // ignore: use_build_context_synchronously
                  context.push('/c/order/matching', extra: order.id);
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send order: $e')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _unitLabel(String baseUnit) {
  final u = baseUnit.toLowerCase().trim();
  return (u == 'kg' || u == 'kilo' || u == 'kilogram') ? 'KG' : 'pc';
}

String _pickupSubtitle(String pickupMode) {
  switch (pickupMode) {
    case 'asap':
      return 'Pickup ASAP selected (placeholder)';
    case 'tomorrow':
      return 'Tomorrow pickup selected (placeholder)';
    case 'schedule':
      return 'Pickup schedule selected (placeholder)';
    default:
      return 'Pickup schedule selected (placeholder)';
  }
}

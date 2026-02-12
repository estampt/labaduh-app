import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/discovery_service_models.dart';
import '../state/order_draft_controller.dart';
import '../state/order_submit_provider.dart';
import 'widgets/sticky_bottom_bar.dart';

class OrderReviewScreen extends ConsumerStatefulWidget {
  const OrderReviewScreen({super.key});

  @override
  ConsumerState<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends ConsumerState<OrderReviewScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(orderDraftControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const Text(
                'Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...draft.services.map((s) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.row.service.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text('₱ ${s.computedPrice}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${s.qty} ${s.row.service.baseUnit}',
                          style: const TextStyle(color: Colors.black54),
                        ),

                        // ✅ NEW: show selected add-ons / options under the service
                        if (s.selectedOptionIds.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SelectedOptionsChips(
                            service: s.row,
                            selectedIds: s.selectedOptionIds,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              _TotalsSection(draft: draft),
            ],
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: StickyBottomBar(
              title: 'Total: ₱ ${draft.total}',
              subtitle: 'Next: find laundry partner',
              buttonText: _isLoading ? 'Sending...' : 'Confirm & Find',
              enabled: !_isLoading && draft.services.isNotEmpty,
              onPressed: () async {
                if (_isLoading) return;

                setState(() => _isLoading = true);

                final submitCtrl = ref.read(orderSubmitProvider.notifier);

                try {
                  final order = await submitCtrl.submit();
                  if (!mounted) return;
                   context.go('/c/orders');
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send order: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedOptionsChips extends StatelessWidget {
  const _SelectedOptionsChips({
    required this.service,
    required this.selectedIds,
  });

  final DiscoveryServiceRow service;
  final Set<int> selectedIds;

  @override
  Widget build(BuildContext context) {
    final allOptions = <ServiceOptionItem>[
      ...service.addons,
      ...service.optionGroups.expand((g) => g.items),
    ];

    final selected = allOptions.where((o) => selectedIds.contains(o.id)).toList();
    if (selected.isEmpty) return const SizedBox.shrink();

    selected.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: selected.map((o) {
        final price = o.priceMin;
        final label = price == 0 ? o.name : '${o.name} • ₱ $price';

        return Chip(label: Text(label));
      }).toList(),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.draft});

  final OrderDraftState draft;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Subtotal', draft.subtotal),
            _row('Delivery Fee', draft.deliveryFee),
            _row('Service Fee', draft.serviceFee),
            _row('Discount', -draft.discount),
            const Divider(),
            _row('Total', draft.total, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, num value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
          Text('₱ $value', style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
        ],
      ),
    );
  }
}

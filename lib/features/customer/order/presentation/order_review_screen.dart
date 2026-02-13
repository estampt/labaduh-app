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


  String _pickupMethodLabel(String v) {
    switch (v) {
      case 'asap':
        return 'ASAP (Today)';
      case 'tomorrow':
        return 'Tomorrow';
      case 'schedule':
        return 'Scheduled';
      default:
        return v;
    }
  }

  String _deliveryMethodLabel(String v) {
    switch (v) {
      case 'pickup_deliver':
        return 'Pickup & Deliver';
      case 'walk_in':
        return 'Walk-in';
      default:
        return v;
    }
  }

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
                          _SelectedAddonsBlock(
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
              const Text(
                'Pickup & Delivery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final scheduledText = _scheduledPickupDateText(draft, context);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _ReviewKeyValueRow(
                            label: 'Pickup method',
                            value: _pickupMethodText(draft, context),
                          ),
                          if (scheduledText != null) ...[
                            const SizedBox(height: 8),
                            _ReviewKeyValueRow(
                              label: 'Pickup date',
                              value: scheduledText,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _ReviewKeyValueRow(
                            label: 'Delivery method',
                            value: _deliveryMethodText(draft),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

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

String _pickupMethodText(dynamic draft, BuildContext context) {
  final mode = (draft.pickupMode ?? '').toString();

  switch (mode) {
    case 'asap':
      return 'ASAP (Today)';
    case 'tomorrow':
      return 'Tomorrow';
    case 'schedule':
      return 'Scheduled';
    default:
      // Fallback if backend/app uses different labels
      return mode.isEmpty ? '—' : mode;
  }
}

String _deliveryMethodText(dynamic draft) {
  final mode = (draft.deliveryMode ?? '').toString();

  switch (mode) {
    case 'pickup_deliver':
      return 'Pickup & Deliver';
    case 'walk_in':
      return 'Walk-in';
    default:
      return mode.isEmpty ? '—' : mode;
  }
}

/// Returns a formatted pickup date if pickupMode == schedule.
/// Supports DateTime or ISO-8601 string fields.
String? _scheduledPickupDateText(dynamic draft, BuildContext context) {
  final mode = (draft.pickupMode ?? '').toString();
  if (mode != 'schedule') return null;

  DateTime? dt;

  // Common field names (try what exists in your draft model)
  try {
    final v = (draft as dynamic).pickupWindowStart;
    if (v is DateTime) dt = v;
    if (v is String) dt = DateTime.tryParse(v);
  } catch (_) {}

  if (dt == null) {
    try {
      final v = (draft as dynamic).scheduledPickupDate;
      if (v is DateTime) dt = v;
      if (v is String) dt = DateTime.tryParse(v);
    } catch (_) {}
  }

  if (dt == null) {
    try {
      final v = (draft as dynamic).pickupDate;
      if (v is DateTime) dt = v;
      if (v is String) dt = DateTime.tryParse(v);
    } catch (_) {}
  }

  if (dt == null) {
    // Mode is schedule but date missing
    return 'Not set';
  }

  final loc = MaterialLocalizations.of(context);
  return loc.formatMediumDate(dt.toLocal());
}

class _ReviewKeyValueRow extends StatelessWidget {
  const _ReviewKeyValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}


class _SelectedAddonsBlock extends StatelessWidget {
  const _SelectedAddonsBlock({
    required this.service,
    required this.selectedIds,
  });

  final DiscoveryServiceRow service;
  final Set<int> selectedIds;

  @override
  Widget build(BuildContext context) {
    // Combine addons + grouped options
    final all = <ServiceOptionItem>[
      ...service.addons,
      ...service.optionGroups.expand((g) => g.items),
    ];

    final selected = all.where((o) => selectedIds.contains(o.id)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (selected.isEmpty) return const SizedBox.shrink();

    // Match the simple, clean list style (similar to your services cards)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Add-ons',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        ...selected.map((o) {
          final price = o.priceMin; // consistent with your estimation logic
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    o.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '₱ $price',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        }),
      ],
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



class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );

    final valueStyle = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: labelStyle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}

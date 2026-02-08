import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/latest_orders_provider.dart';

class OrderMatchingScreen extends ConsumerStatefulWidget {
  const OrderMatchingScreen({super.key});

  @override
  ConsumerState<OrderMatchingScreen> createState() => _OrderMatchingScreenState();
}

class _OrderMatchingScreenState extends ConsumerState<OrderMatchingScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();

    // Light polling so statuses refresh (published -> picked_up -> washing etc.)
    _poll = Timer.periodic(const Duration(seconds: 120), (_) {
      ref.read(latestOrdersProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(latestOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Orders')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load orders: $e')),
        data: (state) {
          // ✅ limit to 3 (top latest)
          final orders = state.orders.take(3).toList();

          if (orders.isEmpty) {
            return const Center(child: Text('No active orders right now.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(latestOrdersProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final o = orders[i];

                // created date label
                final created = _fmtDate(o.createdAt);

                // ✅ timeline index from status
                final activeIndex = timelineIndexFromStatus(normalizeTimelineStatus(o.status));

                // service summary
                final serviceSummary = o.items.isEmpty
                    ? '${o.items.length} item(s)'
                    : 'Service #${o.items.first.serviceId} • Qty ${o.items.first.qty}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderCard(
                    id: o.id,
                    status: o.status,
                    pricingStatus: o.pricingStatus,
                    createdLabel: created,
                    total: o.displayTotal,
                    serviceSummary: serviceSummary,
                    activeIndex: activeIndex,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final int id;
  final String status;
  final String pricingStatus;
  final String createdLabel;
  final num total;
  final String serviceSummary;
  final int activeIndex;

  const _OrderCard({
    required this.id,
    required this.status,
    required this.pricingStatus,
    required this.createdLabel,
    required this.total,
    required this.serviceSummary,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_laundry_service_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$id',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$status • $pricingStatus',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Text(
                '₱ $total',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            serviceSummary,
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 6),
          Text(
            'Created: $createdLabel',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),

          const SizedBox(height: 12),

          // ✅ Timeline
          OrderTimelineBar(activeIndex: activeIndex),
        ],
      ),
    );
  }
}

/// ===== Timeline (matches your Laravel keys) =====

const _timelineSteps = <String>[
  'order_created',
  'pickup_scheduled',
  'picked_up',
  'washing',
  'ready',
  'out_for_delivery',
  'delivered',
  'completed',
];

/// If your API still returns "published", map it to "order_created" so the timeline works.
/// You can extend this mapping as your backend evolves.
String normalizeTimelineStatus(String status) {
  final s = status.toLowerCase().trim();
  if (s == 'published' || s == 'broadcasting') return 'order_created';
  return s;
}

int timelineIndexFromStatus(String statusKey) {
  final idx = _timelineSteps.indexOf(statusKey);
  return idx < 0 ? 0 : idx; // default to first step
}

String timelineLabel(String key) {
  switch (key) {
    case 'order_created':
      return 'Created';
    case 'pickup_scheduled':
      return 'Pickup\nscheduled';
    case 'picked_up':
      return 'Picked\nup';
    case 'washing':
      return 'Washing';
    case 'ready':
      return 'Ready';
    case 'out_for_delivery':
      return 'Out for\ndelivery';
    case 'delivered':
      return 'Delivered';
    case 'completed':
      return 'Completed';
    default:
      return key;
  }
}

class OrderTimelineBar extends StatelessWidget {
  final int activeIndex; // 0..7
  const OrderTimelineBar({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    Widget dot(bool done, bool active) => Container(
          width: active ? 12 : 10,
          height: active ? 12 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? Colors.black : Colors.black26,
          ),
        );

    Widget line(bool done) => Expanded(
          child: Container(
            height: 2,
            color: done ? Colors.black : Colors.black26,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // dots + lines
        Row(
          children: [
            for (int i = 0; i < _timelineSteps.length; i++) ...[
              dot(i <= activeIndex, i == activeIndex),
              if (i != _timelineSteps.length - 1) line(i < activeIndex),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // labels (wrap)
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _timelineSteps.length; i++)
              SizedBox(
                width: 70,
                child: Text(
                  timelineLabel(_timelineSteps[i]),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    color: i <= activeIndex ? Colors.black87 : Colors.black45,
                    fontWeight: i == activeIndex ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

String _fmtDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

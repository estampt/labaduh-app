import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:labaduh/features/vendor/orders/state/vendor_orders_provider.dart';

import '../../orders/data/vendor_orders_repository.dart';

// ✅ Incoming broadcasted orders (headers) – silent background refresh with smart backoff.
final vendorIncomingBroadcastStreamProvider = StreamProvider.autoDispose
    .family<List<BroadcastOrderHeader>, ({int vendorId, int shopId})>((ref, args) async* {
  final vendorId = args.vendorId;
  final shopId = args.shopId;
  // NOTE: Rename this provider if your app uses a different repository provider name.
  final repo = ref.read(vendorOrderRepositoryProvider);

  Duration delay = const Duration(seconds: 15);
  List<BroadcastOrderHeader>? lastGood;

  while (true) {
    try {
      final fresh = await repo.fetchBroadcastedOrderHeadersByShop(
        vendorId: vendorId,
        shopId: shopId,
        perPage: 10,
        cursor: null,
      );
      lastGood = fresh.items;
      delay = const Duration(seconds: 15);
      yield lastGood!;
    } catch (_) {
      // keep UI stable (no flashing) on transient errors
      if (lastGood != null) yield lastGood!;
      if (delay < const Duration(seconds: 30)) {
        delay = const Duration(seconds: 30);
      } else if (delay < const Duration(seconds: 60)) {
        delay = const Duration(seconds: 60);
      } else {
        delay = const Duration(seconds: 120);
      }
    }
    await Future<void>.delayed(delay);
  }
});

class _DashboardBuckets {
  const _DashboardBuckets({
    this.forPickup = 0,
    this.toWeigh = 0,
    this.washing = 0,
    this.ready = 0,
    this.outForDelivery = 0,
    this.delivered = 0,
  });

  final int forPickup;
  final int toWeigh;
  final int washing;
  final int ready;
  final int outForDelivery;
  final int delivered;
}

_DashboardBuckets _computeDashboardBuckets(List<dynamic> orders) {
  int count(Set<String> wanted) {
    var n = 0;
    for (final o in orders) {
      final raw = (o as dynamic).status?.toString() ?? '';
      final s = _normalizeStatus(raw);
      if (wanted.contains(s)) n++;
    }
    return n;
  }

  return _DashboardBuckets(
    // ✅ Vendor action buckets
    forPickup: count({'accepted', 'pickup_scheduled'}),
    toWeigh: count({'picked_up', 'weight_reviewed'}),
    washing: count({'weight_accepted', 'washing'}),
    ready: count({'ready', 'delivery_scheduled'}),
    outForDelivery: count({'out_for_delivery'}),
    // include "completed" as it's typically post-delivery
    delivered: count({'delivered', 'completed'}),
  );
}

/// Normalizes mixed backend/mobile slugs:
/// - "pickupScheduled" -> "pickup_scheduled"
/// - "pickup_scheduled" -> "pickup_scheduled"
/// - trims and lowercases
String _normalizeStatus(String input) {
  var s = input.trim();
  if (s.isEmpty) return s;

  // Insert underscores for camelCase -> snake_case
  s = s.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}');

  s = s.toLowerCase();

  // Collapse multiple underscores
  s = s.replaceAll(RegExp(r'_+'), '_');

  return s;
}

class VendorDashboardTab extends ConsumerWidget {
  const VendorDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const shopId = 2; // TODO: wire from selected shop
    final incomingAsync = ref.watch(vendorIncomingBroadcastStreamProvider((vendorId: 2, shopId: shopId)));
    final ordersAsync = ref.watch(vendorOrdersProvider((vendorId: 2, shopId: shopId)));
    final buckets = ordersAsync.maybeWhen(
      data: (orders) => _computeDashboardBuckets(orders),
      orElse: () => const _DashboardBuckets(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ✅ Incoming Orders (broadcasted)
            incomingAsync.when(
              loading: () => const _StatCardWide(
                title: 'Incoming Orders',
                subtitle: 'Checking broadcasts…',
                value: '—',
                icon: Icons.inbox,
              ),
              error: (_, __) => const _StatCardWide(
                title: 'Incoming Orders',
                subtitle: 'Unable to load broadcasts',
                value: '—',
                icon: Icons.inbox,
              ),
              data: (items) => _StatCardWide(
                title: 'Incoming Orders',
                subtitle: items.isEmpty ? 'No incoming orders right now' : 'Updated automatically',
                value: '${items.length}',
                icon: Icons.inbox,
              ),
            ),
            const SizedBox(height: 12),

            // Keep "Incoming Orders" wide; show the rest as status buckets
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'For Pickup',
                    subtitle: 'Accepted / scheduled',
                    value: '${buckets.forPickup}',
                    icon: Icons.local_shipping_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'To Weigh',
                    subtitle: 'Picked up / review',
                    value: '${buckets.toWeigh}',
                    icon: Icons.monitor_weight_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Washing',
                    subtitle: 'In progress',
                    value: '${buckets.washing}',
                    icon: Icons.local_laundry_service_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Ready',
                    subtitle: 'For delivery',
                    value: '${buckets.ready}',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Out for Delivery',
                    subtitle: 'On the way',
                    value: '${buckets.outForDelivery}',
                    icon: Icons.route_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Delivered',
                    subtitle: 'Completed handoff',
                    value: '${buckets.delivered}',
                    icon: Icons.task_alt_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ Incoming order headers (lightweight)
            incomingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Incoming', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...items.take(5).map((it) => _IncomingOrderTile(item: it)),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),

            _MenuTile(
              icon: Icons.receipt_long,
              title: 'Orders',
              subtitle: 'View and manage incoming orders',
              onTap: () => context.go('/v/orders'),
            ),
            _MenuTile(
              icon: Icons.payments,
              title: 'Earnings',
              subtitle: 'View income and payouts',
              onTap: () => context.go('/v/earnings'),
            ),
            _MenuTile(
              icon: Icons.price_change,
              title: 'Services & Pricing',
              subtitle: 'Set prices and add-ons',
              onTap: () => context.go('/v/profile/pricing'),
            ),
            _MenuTile(
              icon: Icons.schedule,
              title: 'Operating Hours',
              subtitle: 'Manage availability',
              onTap: () => context.go('/v/profile/hours'),
            ),
            _MenuTile(
              icon: Icons.store,
              title: 'Shop Profile',
              subtitle: 'Business details and settings',
              onTap: () => context.go('/v/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardWide extends StatelessWidget {
  const _StatCardWide({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 22, child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
          ],
        ),
      ),
    );
  }
}

class _IncomingOrderTile extends StatelessWidget {
  const _IncomingOrderTile({required this.item});

  final BroadcastOrderHeader item;

  @override
  Widget build(BuildContext context) {
    final c = item.customer;
    final o = item.order;

    final addr1 = (c.addressLine1 ?? '').trim();
    final addr2 = (c.addressLine2 ?? '').trim();

    final address = [
      if (addr1.isNotEmpty) addr1,
      if (addr2.isNotEmpty) addr2,
    ].join('\n');

    final totalLabel = '${o.currency} ${o.total}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.go(
          '/v/orders/${item.orderId}', // 🔥 deeplink
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Customer Name
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// Address
                    if (address.isNotEmpty)
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),

                    const SizedBox(height: 8),

                    /// Modes
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ModeChip(
                          icon: Icons.schedule_outlined,
                          label: o.pickupMode,
                        ),
                        _ModeChip(
                          icon: Icons.local_shipping_outlined,
                          label: o.deliveryMode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// RIGHT — TOTAL AMOUNT
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  }
}
 
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Icon(icon, size: 18),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

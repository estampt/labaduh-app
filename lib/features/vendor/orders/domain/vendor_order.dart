import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/vendor_orders_provider.dart';
import '../model/vendor_order_model.dart';

class VendorOrderScreen extends ConsumerWidget {
  const VendorOrderScreen({
    super.key,
    required this.vendorId,
    required this.shopId,
    this.title = 'Active Orders',
  });

  final int vendorId;
  final int shopId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (vendorId: vendorId, shopId: shopId);
    final asyncOrders = ref.watch(vendorOrdersProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(vendorOrdersProvider(params)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // refresh provider and await completion
          await ref.refresh(vendorOrdersProvider(params).future);
        },
        child: asyncOrders.when(
          loading: () => const _LoadingList(),
          error: (err, st) => _ErrorState(
            message: err.toString(),
            onRetry: () => ref.refresh(vendorOrdersProvider(params)),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return const _EmptyState();
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final o = orders[index];
                return _OrderCard(order: o);
              },
            );
          },
        ),
      ),
    );
  }
}

// ----------------------------
// UI Widgets
// ----------------------------

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    final created = order.createdAt;
    final updated = order.updatedAt;

    final createdLabel = created == null ? '-' : _formatDateTime(created.toLocal());
    final updatedLabel = updated == null ? '-' : _formatDateTime(updated.toLocal());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Order ID + Status chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.idLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                _StatusChip(label: order.statusLabel),
              ],
            ),
            const SizedBox(height: 8),

            // Customer
            Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Services
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_laundry_service, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.servicesLabel,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 10),

            // Meta
            Row(
              children: [
                Expanded(
                  child: _MetaLine(
                    label: 'Items',
                    value: '${order.itemsCount}',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                Expanded(
                  child: _MetaLine(
                    label: 'Created',
                    value: createdLabel,
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetaLine(
                    label: 'Updated',
                    value: updatedLabel,
                    icon: Icons.update_outlined,
                  ),
                ),
                Expanded(
                  child: _MetaLine(
                    label: 'Shop',
                    value: order.acceptedShop?.name ?? '—',
                    icon: Icons.storefront_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (_, __) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const SizedBox(height: 120),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.inbox_outlined, size: 52),
        SizedBox(height: 12),
        Center(
          child: Text(
            'No active orders yet.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: 6),
        Center(child: Text('Pull down to refresh.')),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 90),
        const Icon(Icons.error_outline, size: 52),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Failed to load orders',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}

// ----------------------------
// Formatting helper
// ----------------------------

String _formatDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

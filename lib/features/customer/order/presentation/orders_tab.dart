
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/latest_orders_models.dart';
import '../state/latest_orders_provider.dart';

/// LIVE ORDERS DASHBOARD (Provider-based)
/// Uses your existing `latestOrdersProvider` (AsyncNotifier) for:
/// - initial load
/// - refresh
/// - pagination via cursor (loadMore)
///
/// Also adds lightweight polling (same behavior as tracking) by calling provider.refresh().
class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  Timer? _timer;

  // Adjust based on your needs (battery vs freshness).
  static const _pollInterval = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();

    // Poll by refreshing the provider.
    _timer = Timer.periodic(_pollInterval, (_) {
      ref.read(latestOrdersProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isActiveStatus(String status) {
    final s = status.toLowerCase().trim();
    return s != 'completed' && s != 'cancelled' && s != 'canceled';
  }

  num _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  num _computeOrderTotal(LatestOrder o) {
    final finalTotal = _num(o.finalTotal);
    if (finalTotal > 0) return finalTotal;

    final estimated = _num(o.estimatedTotal);
    if (estimated > 0) return estimated;

    // Fallback: sum items + options
    num sum = 0;
    for (final it in o.items) {
      sum += _num(it.price);
      for (final opt in it.options) {
        sum += _num(opt.price);
      }
    }
    return sum;
  }

  int _countOptions(LatestOrder o) {
    int c = 0;
    for (final it in o.items) {
      c += it.options.length;
    }
    return c;
  }

  Future<void> _showAllOrdersSheet({
    required List<LatestOrder> orders,
    required String? cursor,
    required bool isLoadingMore,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (_, ref, __) {
              final stateAsync = ref.watch(latestOrdersProvider);

              final state = stateAsync.value;
              final sheetOrders = state?.orders ?? orders;
              final sheetCursor = state?.cursor ?? cursor;
              final loadingMore = state?.isLoadingMore ?? isLoadingMore;

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: sheetOrders.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  if (i == sheetOrders.length) {
                    // Footer: load more / end
                    if (sheetCursor == null) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Center(child: Text('End of list')),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(
                        child: TextButton(
                          onPressed: loadingMore
                              ? null
                              : () => ref
                                  .read(latestOrdersProvider.notifier)
                                  .loadMore(),
                          child: Text(loadingMore ? 'Loading…' : 'Load more'),
                        ),
                      ),
                    );
                  }

                  final o = sheetOrders[i];
                  final total = _computeOrderTotal(o);
                  final optCount = _countOptions(o);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Order #${o.id}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${o.status} • ${o.createdAt} • ${o.items.length} item(s) • $optCount option(s)',
                    ),
                    trailing: Text(
                      '₱ $total',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/c/orders/${o.id}');
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestAsync = ref.watch(latestOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(latestOrdersProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: latestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load orders: $e'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(latestOrdersProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          final orders = state.orders;
          final active = orders.where((o) => _isActiveStatus(o.status)).toList();

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No active orders',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When you place an order, it will appear here and update automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.go('/c/home'),
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(latestOrdersProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Live order',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    TextButton(
                      onPressed: () => _showAllOrdersSheet(
                        orders: orders,
                        cursor: state.cursor,
                        isLoadingMore: state.isLoadingMore,
                      ),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (active.isNotEmpty) ...[
                  _ActiveOrderDashboard(
                    order: active.first,
                    total: _computeOrderTotal(active.first),
                    optionsCount: _countOptions(active.first),
                    onOpenDetails: () =>
                        context.push('/c/orders/${active.first.id}'),
                  ),
                  const SizedBox(height: 14),
                  if (active.length > 1)
                    _OtherActiveOrders(
                      orders: active.skip(1).toList(),
                      computeTotal: _computeOrderTotal,
                      countOptions: _countOptions,
                      onOpen: (id) => context.push('/c/orders/$id'),
                    ),
                  const SizedBox(height: 14),
                ] else ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No active orders right now. Tap “View all” to see history.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const Text('Recent',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),

                ...orders.take(5).map((o) {
                  final total = _computeOrderTotal(o);
                  final optCount = _countOptions(o);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        title: Text('Order #${o.id}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                            '${o.status} • ${o.createdAt} • ${o.items.length} item(s) • $optCount option(s)'),
                        trailing: Text('₱ $total',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        onTap: () => context.push('/c/orders/${o.id}'),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActiveOrderDashboard extends StatelessWidget {
  const _ActiveOrderDashboard({
    required this.order,
    required this.total,
    required this.optionsCount,
    required this.onOpenDetails,
  });

  final LatestOrder order;
  final num total;
  final int optionsCount;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id}',
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Text('₱ $total',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.status} • ${order.pricingStatus} • ${order.createdAt}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),

            _InfoRow(label: 'Shop', value: order.shop?.name ?? 'Not assigned yet'),
            const SizedBox(height: 6),
            _InfoRow(label: 'Driver', value: order.driver?.name ?? 'Not assigned yet'),

            const SizedBox(height: 12),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),

            ...order.items.map((it) {
              final optTotal =
                  it.options.fold<num>(0, (s, o) => s + (num.tryParse(o.price.toString()) ?? 0));

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service #${it.serviceId} • Qty ${it.qty}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Base: ₱ ${it.price}',
                        style: const TextStyle(color: Colors.black54)),
                    if (it.options.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: it.options.map((o) {
                          final name = (o.name == null || o.name!.trim().isEmpty)
                              ? 'Option #${o.id}'
                              : o.name!;
                          return Chip(label: Text('$name • ₱ ${o.price}'));
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      Text('Options total: ₱ $optTotal',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ],
                ),
              );
            }),

            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.items.length} item(s) • $optionsCount option(s)',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                TextButton(
                  onPressed: onOpenDetails,
                  child: const Text('Open details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherActiveOrders extends StatelessWidget {
  const _OtherActiveOrders({
    required this.orders,
    required this.computeTotal,
    required this.countOptions,
    required this.onOpen,
  });

  final List<LatestOrder> orders;
  final num Function(LatestOrder) computeTotal;
  final int Function(LatestOrder) countOptions;
  final void Function(int id) onOpen;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Other active orders',
          style: TextStyle(fontWeight: FontWeight.w800)),
      children: orders.map((o) {
        final total = computeTotal(o);
        final optCount = countOptions(o);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Order #${o.id}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${o.status} • ${o.items.length} item(s) • $optCount option(s)'),
          trailing: Text('₱ $total',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          onTap: () => onOpen(o.id),
        );
      }).toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

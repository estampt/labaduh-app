
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/latest_orders_models.dart';
import '../state/latest_orders_provider.dart';

/// OrdersTab (Live Dashboard)
/// - Shows ONLY ACTIVE orders from latestOrdersProvider (auto-refresh).
/// - "View history" loads COMPLETED orders via /api/v1/customer/orders?status=completed (one-time fetch per open).
class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  Timer? _timer;

  // Adjust based on your needs (battery vs freshness).
  static const _pollInterval = Duration(seconds: 8);

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

  Future<void> _openHistorySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Consumer(
              builder: (_, ref, __) {
                final historyAsync = ref.watch(completedOrdersProvider);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order history',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: historyAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Failed to load history: $e'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => ref.refresh(completedOrdersProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (orders) {
                          if (orders.isEmpty) {
                            return const Center(child: Text('No completed orders yet.'));
                          }

                          return ListView.separated(
                            itemCount: orders.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final o = orders[i];
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
                    ),
                  ],
                );
              },
            ),
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
                  onPressed: () => ref.read(latestOrdersProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          final active = state.orders.where((o) => _isActiveStatus(o.status)).toList();

          // ✅ UX: show only active orders. History is separate and fetched once on demand.
          if (active.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No active orders',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When you place an order, it will appear here and update automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _openHistorySheet,
                      child: const Text('View history'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
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
                    const Text('Active orders', style: TextStyle(fontWeight: FontWeight.w900)),
                    TextButton(
                      onPressed: _openHistorySheet,
                      child: const Text('View history'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...active.map((o) {
                  final total = _computeOrderTotal(o);
                  final optCount = _countOptions(o);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text('Order #${o.id}',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                          '${o.status} • ${o.createdAt} • ${o.items.length} item(s) • $optCount option(s)',
                        ),
                        trailing: Text('₱ $total',
                            style: const TextStyle(fontWeight: FontWeight.w900)),
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

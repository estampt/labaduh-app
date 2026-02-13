
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/latest_orders_models.dart';
import '../state/latest_orders_provider.dart';
import '../data/customer_orders_api.dart';
import '../../../../core/network/api_client.dart';
import 'order_feedback.dart';

/// OrdersTab - default UI similar to your tracking card screenshot:
/// - Partner card (vendor shop name, photo, rating, distance)
/// - Items card (with selected options)
/// - Tracking steps card
///
/// Data source:
/// - Active orders ONLY from latestOrdersProvider (auto-refresh)
/// - History via completedOrdersProvider (bottom sheet, fetched on demand; NOT polled)
class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  Timer? _timer;
  static const _pollInterval = Duration(seconds: 60);

  void _startPolling() {
    if (_timer != null) return;
    _timer = Timer.periodic(_pollInterval, (_) {
      ref.read(latestOrdersProvider.notifier).refresh();
    });
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void initState() {
    super.initState();

    // Start polling by default. We'll stop automatically when there are no active orders.
    _startPolling();

    // Stop polling when there are no active orders.
    // Polling will resume after a manual refresh if active orders appear again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.listen(latestOrdersProvider, (prev, next) {
        next.whenData((state) {
          final hasActive = state.orders.any((o) => _isActiveStatus(o.status));
          if (hasActive) {
            _startPolling();
          } else {
            _stopPolling();
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _stopPolling();
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
    // New response: "total" is canonical
    final total = _num(o.total);
    if (total > 0) return total;

    final finalTotal = _num(o.finalTotal);
    if (finalTotal > 0) return finalTotal;

    final estimated = _num(o.estimatedTotal);
    if (estimated > 0) return estimated;

    // Fallback: sum items + options
    num sum = 0;
    for (final it in o.items) {
      sum += _num(it.displayPrice);
      for (final opt in it.options) {
        sum += _num(opt.displayPrice);
      }
    }
    return sum;
  }

  /// Maps backend status -> step index in the UI timeline.
  /// Adjust these mappings as your backend statuses finalize.
  int _statusToStepIndex(String status) {
    final s = status.toLowerCase().trim();

    // ordered steps (0..4)
    // 0 pickup scheduled
    // 1 picked up
    // 2 washing
    // 3 ready
    // 4 delivered
    if (s == 'published' || s == 'matched' || s == 'accepted' || s == 'scheduled') return 0;
    if (s == 'picked_up' || s == 'pickedup') return 1;
    if (s == 'washing') return 2;
    if (s == 'ready') return 3;
    if (s == 'delivered' || s == 'completed') return 4;

    // default: earliest step
    return 0;
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

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Order #${o.id}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text('${o.status} • ${o.createdAt}'),
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
          TextButton(
            onPressed: _openHistorySheet,
            child: const Text('History'),
          ),
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

          if (active.isEmpty) {
            // Keep pull-to-refresh available even when empty.
            return RefreshIndicator(
              onRefresh: () => ref.read(latestOrdersProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 48),
                      const Text(
                        'No active orders',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _openHistorySheet,
                        child: const Text('View history'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/c/home'),
                        child: const Text('Go to Home'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pull down to refresh.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(latestOrdersProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: active.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final o = active[i];
                final total = _computeOrderTotal(o);
                final stepIndex = _statusToStepIndex(o.status);

                return _OrderDashboardCard(
                  order: o,
                  total: total,
                  stepIndex: stepIndex,
                  onOpenDetails: () => context.push('/c/orders/${o.id}'),
                  onChatVendor: (o.partner == null) 
                      ? null
                      : () => context.push('/messages/${o.partner!.id}'),
                  onCompleteOrder: (o.status.toLowerCase().trim() == 'delivered')
                      ? () async {
                          try {
                            final client = ref.read(apiClientProvider);
                            final ordersApi = CustomerOrdersApi(client.dio);

                            await ordersApi.confirmDelivery(o.id);

                            if (!context.mounted) return;

                            // Navigate to feedback / review screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderFeedbackScreen(
                                  orderId: o.id,
                                  showOrderCompletedMessage: true,
                                ),
                              ),
                            );

                            // Refresh after navigate (no await)
                            // ignore: unawaited_futures
                            ref.read(latestOrdersProvider.notifier).refresh();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to complete order: $e')),
                            );
                          }
                        }
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderDashboardCard extends StatelessWidget {
  const _OrderDashboardCard({
    required this.order,
    required this.total,
    required this.stepIndex,
    required this.onOpenDetails,
    this.onChatVendor,
    this.onCompleteOrder,
    super.key,
  });

  final LatestOrder order;
  final num total;
  final int stepIndex;
  final VoidCallback onOpenDetails;
  final VoidCallback? onChatVendor;
  final VoidCallback? onCompleteOrder;

  String _serviceLabel(LatestOrderItem it) => it.service?.name ?? 'Service #${it.serviceId}';

  String _optionLabel(LatestOrderItemOption o) {
    // Prefer nested service_option.name, fallback to name, then id.
    final n = (o.serviceOption?.name ?? o.name ?? '').trim();
    if (n.isNotEmpty) return n;
    if (o.serviceOptionId != null) return 'Option #${o.serviceOptionId}';
    return 'Option #${o.id}';
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final shop = order.vendorShop ?? order.shop; // prefer vendor_shop for distance/rating
    final rating = shop?.avgRating;
    final dist = shop?.distanceKm;
    final ratingCount = shop?.ratingsCount;

    return Column(
      children: [
        // Partner card (real data from vendor_shop/accepted_shop)
        _RoundedCard(
          radius: radius,
          child: ListTile(
            dense: true,
            leading: _ShopAvatar(url: shop?.profilePhotoUrl),
            title: Text(
              shop?.name ?? 'Searching for available Labaduh partners...',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              _partnerSubtitle(rating: rating, ratingCount: ratingCount, distanceKm: dist),
              style: const TextStyle(color: Colors.black54),
            ),
            //onTap: onOpenDetails, // Optional: open details when tapping partner card as well
          ),
        ),
        const SizedBox(height: 10),

        
            // Items card (show item details + options)
          _RoundedCard(
            radius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ---------- HEADER ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Order Number (left)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              'Order #${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Order placed',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date (rightmost)
                      Text(
                        _formatDate(order.createdAt),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // ---------- SPACE BEFORE ITEMS ----------
                  const SizedBox(height: 16),

                  // Divider (optional but nice)
                  Divider(
                    height: 1,
                    color: Colors.grey.withOpacity(0.25),
                  ),

                  const SizedBox(height: 12),

                const Text('Items', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),

                ...order.items.map((it) {
                  final uom = (it.uom ?? '').trim();
                  final qtyLabel = uom.isEmpty ? '${it.qty}' : '${it.qty} ${uom.toUpperCase()}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _serviceLabel(it),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(qtyLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱ ${it.displayPrice ?? '0.00'}',
                          style: const TextStyle(color: Colors.black54),
                        ),

                        if (it.options.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          // options list (like services screen: name left, price right)
                          ...it.options.map((o) {
                            final price = o.displayPrice ?? '0.00';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _optionLabel(o),
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
                      ],
                    ),
                  );
                }),

                const Divider(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w900)),
                    Text('₱ $total', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tracking card
        _RoundedCard(
          radius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tracking', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),

                _TrackingStep(label: 'Pickup scheduled', state: _stepState(0, stepIndex)),
                const Divider(height: 18),
                _TrackingStep(label: 'Picked up', state: _stepState(1, stepIndex)),
                const Divider(height: 18),
                _TrackingStep(label: 'Washing', state: _stepState(2, stepIndex)),
                const Divider(height: 18),
                _TrackingStep(label: 'Ready', state: _stepState(3, stepIndex)),
                const Divider(height: 18),
                _TrackingStep(label: 'Delivered', state: _stepState(4, stepIndex)),

                const SizedBox(height: 10),
                if (onChatVendor != null || onCompleteOrder != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (onChatVendor != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onChatVendor,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Chat vendor'),
                          ),
                        ),
                      if (onChatVendor != null && onCompleteOrder != null)
                        const SizedBox(width: 10),
                      if (onCompleteOrder != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onCompleteOrder,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Complete order'),
                          ),
                        ),
                    ],
                  ),
                ],
                 
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _partnerSubtitle({
    required double? rating,
    required int? ratingCount,
    required double? distanceKm,
  }) {
    final parts = <String>[];

    if (rating != null) {
      final r = rating.toStringAsFixed(1);
      parts.add('Rating: $r');
    }
    if (ratingCount != null) {
      parts.add('($ratingCount)');
    }
    if (distanceKm != null) {
      parts.add('${distanceKm.toStringAsFixed(2)}km away');
    }

    if (parts.isEmpty) return 'Please wait...';
    return parts.join(' • ');
  }

  static _TrackingState _stepState(int step, int current) {
    if (step < current) return _TrackingState.done;
    if (step == current) return _TrackingState.current;
    return _TrackingState.pending;
  }
}

class _ShopAvatar extends StatelessWidget {
  const _ShopAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();
    if (u.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.storefront));
    }

    return CircleAvatar(
      backgroundImage: NetworkImage(u),
      onBackgroundImageError: (_, __) {},
      child: Container(),
    );
  }
}

class _RoundedCard extends StatelessWidget {
  const _RoundedCard({required this.child, required this.radius});

  final Widget child;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }
}

enum _TrackingState { done, current, pending }

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({required this.label, required this.state});

  final String label;
  final _TrackingState state;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color? color;

    switch (state) {
      case _TrackingState.done:
        icon = Icons.check_circle;
        color = Colors.black87;
        break;
      case _TrackingState.current:
        icon = Icons.radio_button_checked;
        color = Colors.black87;
        break;
      case _TrackingState.pending:
        icon = Icons.radio_button_unchecked;
        color = Colors.black38;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: state == _TrackingState.pending ? Colors.black54 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '-';

  final date = DateTime.tryParse(dateStr);
  if (date == null) return '-';

  return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
}


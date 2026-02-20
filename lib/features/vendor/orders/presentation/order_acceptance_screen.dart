// lib/features/vendor/orders/presentation/order_acceptance_screen.dart

import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:labaduh/features/vendor/orders/state/vendor_orders_provider.dart'; 
import '../model/vendor_order_model.dart';

const double _kBottomBarHeight = 76;

final vendorOrderAcceptanceProvider = FutureProvider.family<
    VendorOrderModel,
    ({int vendorId, int shopId, int broadcastId})>((ref, p) async {
  debugPrint('🟨 [OrderAcceptanceProvider] FETCH vendor=${p.vendorId} shop=${p.shopId} broadcast id =${p.broadcastId}');
  final repo = ref.read(vendorOrderRepositoryProvider);

  final orders = await repo.getOrderByBroadcastId(
    broadcastId: p.broadcastId,
    vendorId: p.vendorId,
    shopId: p.shopId, 
  );

  if (orders == null || orders.isEmpty) throw Exception('Order not found');
  return orders.first;
});

class OrderAcceptanceScreen extends ConsumerWidget {
  const OrderAcceptanceScreen({
    super.key,
    required this.broadcastId,
    required this.vendorId,
    required this.shopId,
  });

  final int broadcastId;
  final int vendorId;
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(
      vendorOrderAcceptanceProvider(
        (vendorId: vendorId, shopId: shopId, broadcastId: broadcastId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Broadcast Id $broadcastId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(
              vendorOrderAcceptanceProvider(
                (vendorId: vendorId, shopId: shopId, broadcastId: broadcastId),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            vendorOrderAcceptanceProvider(
              (vendorId: vendorId, shopId: shopId, broadcastId: broadcastId),
            ),
          );
          await ref.read(
            vendorOrderAcceptanceProvider(
              (vendorId: vendorId, shopId: shopId, broadcastId: broadcastId),
            ).future,
          );
        },
        child: asyncOrder.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (order) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + _kBottomBarHeight),
              children: [
                _CustomerCard(order: order),
                const SizedBox(height: 12),
                _OrderExpandableCard(order: order),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: asyncOrder.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (order) {
          if (order.status != 'published') return const SizedBox.shrink();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: () => _acceptOrder(context, ref, order),
                  child: const Text(
                    'ACCEPT ORDER',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _acceptOrder(BuildContext context, WidgetRef ref, VendorOrderModel order) async {
    try {
      final repo = ref.read(vendorOrderRepositoryProvider);

      await repo.acceptOrder(
        vendorId: vendorId,
        shopId: shopId,
        orderId: order.id,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted successfully')),
      );

      ref.invalidate(
        vendorOrderAcceptanceProvider(
          (vendorId: vendorId, shopId: shopId, broadcastId: broadcastId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});
  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    final c = order.customer;

    final photoUrl = (c?.profilePhotoUrl ?? '').trim();
    final name = order.customerName;
    final address = c?.addressLabel ?? '—';

    return _SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(raw: order.status, label: order.statusLabel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (c?.latitude != null && c?.longitude != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lat ${c!.latitude} • Lng ${c.longitude}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderExpandableCard extends StatelessWidget {
  const _OrderExpandableCard({required this.order});
  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    final currencySymbol = 'S\$ ';
    final totalLabel = _money(order.grandTotal, symbol: currencySymbol);

    return Card(
      margin: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // ✅ removes the 2 lines
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Text(totalLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          subtitle: Text(
            '${order.itemsCount} item${order.itemsCount == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.black54),
          ),
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _InfoTile(label: 'Created', value: _fmt(order.createdAt))),
                Expanded(child: _InfoTile(label: 'Updated', value: _fmt(order.updatedAt))),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),

            ...order.items.map((it) => _ItemBlock(item: it, currencySymbol: currencySymbol)),

            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _moneyRow('Subtotal', _money(order.subtotal, symbol: currencySymbol)),
                  const SizedBox(height: 6),
                  _moneyRow('Delivery fee', _money(order.deliveryFee, symbol: currencySymbol)),
                  const SizedBox(height: 6),
                  _moneyRow('Service fee', _money(order.serviceFee, symbol: currencySymbol)),
                  const SizedBox(height: 6),
                  if (order.discount > 0) ...[
                    _moneyRow('Discount', '-${_money(order.discount, symbol: currencySymbol)}'),
                    const SizedBox(height: 6),
                  ],
                  const Divider(height: 16),
                  _moneyRow(
                    'Total',
                    _money(order.grandTotal, symbol: currencySymbol),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                    valueStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}

class _ItemBlock extends StatelessWidget {
  const _ItemBlock({required this.item, required this.currencySymbol});

  final VendorOrderItemModel item;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final name = item.service?.displayName ?? 'Service';
    final base = item.computedPrice ?? item.estimatedPrice ?? item.finalPrice ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              Text(_money(base, symbol: currencySymbol),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Qty: ${item.qtyLabel}', style: const TextStyle(color: Colors.black54)),

          if (item.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Add-ons',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
            const SizedBox(height: 6),
            ...item.options.map((op) {
              final optName = op.serviceOption?.displayName ?? 'Option';
              final price = op.computedPrice ?? op.price ?? 0.0;
              final req = op.isRequired ? ' (required)' : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('$optName$req', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text(_money(price, symbol: currencySymbol),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            }),
          ],

          const Divider(height: 18),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8)],
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.raw, required this.label});
  final String raw;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bg = _statusColor(raw) ?? Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

Widget _moneyRow(
  String label,
  String value, {
  TextStyle? labelStyle,
  TextStyle? valueStyle,
}) {
  return Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: labelStyle ??
              TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
        ),
      ),
      Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

String _money(double value, {String symbol = 'S\$ '}) => '$symbol${value.toStringAsFixed(2)}';

String _fmt(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

Color? _statusColor(String raw) {
  switch (raw) {
    case 'published':
      return Colors.amber.shade200;
    case 'accepted':
      return Colors.blue.shade200;
    case 'weightReviewed':
      return Colors.orange.shade200;
    case 'ready':
      return Colors.green.shade200;
    case 'canceled':
      return Colors.red.shade200;
    default:
      return null;
  }
}
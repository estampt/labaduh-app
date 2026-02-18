import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/vendor_orders_provider.dart';
import '../model/vendor_order_model.dart';
import 'package:labaduh/core/utils/order_status_utils.dart';
import '../../../../core/auth/session_notifier.dart';


const double _kSubmitBarHeight = 76;

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.vendorId,
    required this.shopId,
  });

  final int orderId;
  final int vendorId;
  final int shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders =
        ref.watch(vendorOrdersProvider((vendorId: vendorId, shopId: shopId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      bottomNavigationBar: asyncOrders.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (orders) {
          final order = orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => throw Exception('Order not found'),
          );

          final grandTotal =
              order.subtotal + order.deliveryFee + order.serviceFee - order.discount;

          if (order.status != "completed" && order.status != "canceled" && order.status != "delivered") {
            return _SubmitBar(
              orderStatus: order.status,
              totalLabel: _money(grandTotal),
              buttonLabel: OrderStatusUtils.submitButtonLabel(
                OrderStatusUtils.statusToLabel(order.status),
              ),
              onPressed: () => _handleSubmitStatus(
                context: context,
                ref: ref,
                order: order,
              ),
            );
          }

;
        },
      ),

      body: asyncOrders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          final order = orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => throw Exception('Order not found'),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + _kSubmitBarHeight),
            children: [
              _CustomerCard(order: order),
              const SizedBox(height: 12), 

              _OrderHeaderCard(order: order),
              const SizedBox(height: 12),

//              _ItemsCard(order: order),
            ],
          );
        },
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////
/// ORDER HEADER
///////////////////////////////////////////////////////////////////////////////
class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});

  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    final itemsCount = items.length;

    // Use order-level totals (authoritative)
    final subtotal = order.subtotal;
    final deliveryFee = order.deliveryFee;
    final serviceFee = order.serviceFee;
    final discount = order.discount;

    final grandTotal = subtotal + deliveryFee + serviceFee - discount;

    final grandTotalLabel = _money(grandTotal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        initiallyExpanded: false,

        // 🔽 Collapsed: Order # + Grand Total
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Order #${order.id}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Text(
              grandTotalLabel,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),

        subtitle: Text(
          '$itemsCount item${itemsCount == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.black54),
        ),

        // 🔼 Expanded content
        children: [
          const SizedBox(height: 10),

          // Created/Updated
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Created',
                  value: _fmt(order.createdAt),
                ),
              ),
              Expanded(
                child: _InfoTile(
                  label: 'Updated',
                  value: _fmt(order.updatedAt),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),

          ...items.map((item) {
            final serviceName = item.service?.name;
            final serviceId = item.service?.id?.toString() ?? '-';

            final itemPrice = _num(item.computedPrice);
            final itemPriceLabel = _money(itemPrice);

            final qty = item.quantity; // ✅ use qty (not quantity)
            final uom = (item.uom ?? '').trim();
            final qtyLine = 'Qty: $qty${uom.isEmpty ? '' : ' ${uom.toUpperCase()}'}';

            final options = item.options;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service name + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          (serviceName != null && serviceName.trim().isNotEmpty)
                              ? serviceName
                              : 'Service #$serviceId',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        itemPriceLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text(qtyLine, style: const TextStyle(color: Colors.black54)),

                  // Add-ons
                  if (options.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Add-ons',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...options.map((o) {
                      final optName = o.serviceOption?.name;
                      final optId = (o.serviceOptionId ?? o.id).toString();

                      final optPriceNum = _num(o.computedPrice ?? o.price);
                      final optPriceLabel = _money(optPriceNum);

                      final isReq = (o.isRequired == true);
                      final requiredLabel = isReq ? ' (required)' : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${(optName != null && optName.trim().isNotEmpty) ? optName : 'Option #$optId'}$requiredLabel',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              optPriceLabel,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],

                  const Divider(height: 18),
                ],
              ),
            );
          }).toList(),

          // ✅ Summary breakdown (professional)
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
                _moneyRow('Subtotal', _money(subtotal)),
                const SizedBox(height: 6),
                _moneyRow('Delivery fee', _money(deliveryFee)),
                const SizedBox(height: 6),
                _moneyRow('Service fee', _money(serviceFee)),
                const SizedBox(height: 6),
                _moneyRow(
                  'Discount',
                  discount > 0 ? '- ${_money(discount)}' : _money(0),
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: discount > 0 ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _moneyRow(
                  'Grand total',
                  _money(grandTotal),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                  valueStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Text(
          value,
          style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _money(double value, {String symbol = 'S\$ '}) {
    return '$symbol${value.toStringAsFixed(2)}';
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}


///////////////////////////////////////////////////////////////////////////////
/// CUSTOMER
///////////////////////////////////////////////////////////////////////////////
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    final c = order.customer;

    if (c == null) {
      return const _Card(child: Text('No customer info'));
    }

    final address = [
      c.addressLine1,
      c.addressLine2,
      c.postalCode,
    ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage:
                (c.profilePhotoUrl != null && c.profilePhotoUrl!.isNotEmpty)
                    ? NetworkImage(c.profilePhotoUrl!)
                    : null,
            child: (c.profilePhotoUrl == null || c.profilePhotoUrl!.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Name (left) + Status (right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                      _StatusPill(label: OrderStatusUtils.statusToLabel(order.status), raw: order.status), 
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  address.isEmpty ? '—' : address,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (c.latitude != null && c.longitude != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lat ${c.latitude} • Lng ${c.longitude}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
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

  

///////////////////////////////////////////////////////////////////////////////
/// UI HELPERS
///////////////////////////////////////////////////////////////////////////////
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.raw});
  final String label;
  final String raw;

  @override
  Widget build(BuildContext context) {
    // Subtle styling that still reads well
    final bg = Colors.grey.shade100;
    final border = Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        //color: bg,
        color:  OrderStatusUtils.statusColor(raw),

        borderRadius: BorderRadius.circular(999),
        //border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
// =======================================================
// Submit Bar (fixed bottom)
// =======================================================
 

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.totalLabel,
    required this.orderStatus,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String totalLabel;
  final String orderStatus;
  final String buttonLabel;     
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: _kSubmitBarHeight,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(.08)),
          ),
        ),
        child: SizedBox(
          width: double.infinity,   // ✅ FULL WIDTH
          height: 48,               // slightly taller for UX
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              OrderStatusUtils.submitButtonLabel(
                OrderStatusUtils.nextStatusCode(orderStatus),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),

              ),
    );
  }
}
String _money(double value, {String symbol = '₱ '}) {
  return '$symbol${value.toStringAsFixed(2)}';
}
Future<void> _handleSubmitStatus({
  required BuildContext context,
  required WidgetRef ref,
  required VendorOrderModel order,

  // 🔮 Future extensibility
  Map<String, dynamic>? fields,
  List<File>? images,
}) async {

  final nextSlug =
      OrderStatusUtils.nextStatusCode(order.status);

  if (nextSlug == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No next action available')),
    );
    return;
  }

  try {
    final repo =
        ref.read(vendorOrderRepositoryProvider);

    // =====================================================
    // Build request body
    // =====================================================
    Map<String, dynamic>? body;

    if (fields != null && fields.isNotEmpty) {
      body = {...fields};
    }

    // Future: attach images
    if (images != null && images.isNotEmpty) {
      body ??= {};
      body['images'] = images;
    }

    // =====================================================
    // Call API
    // =====================================================
    final session = ref.watch(sessionNotifierProvider);
    final vendorId = session.vendorId;
    final shopId = session.activeShopId;
    await repo.postStatusAction(
      vendorId: vendorId,
      shopId: shopId,
      orderId: order.id,
      actionSlug: nextSlug,
      body: body,
    );

    if (!context.mounted) return;

    /*
    //TODO: TO display message or not, since the status is already disabled by default
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order moved from '
          '${OrderStatusUtils.statusLabel(nextSlug)}',
        ),
      ),
    );
    */
    // 🔄 Refresh providers
    ref.invalidate(vendorOrdersProvider);

  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $e')),
    );
  }
}

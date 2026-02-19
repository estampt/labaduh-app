import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labaduh/core/utils/submit_loading_provider.dart';

import '../state/vendor_orders_provider.dart';
import '../model/vendor_order_model.dart';
import 'package:labaduh/core/utils/order_status_utils.dart';
import '../../../../core/auth/session_notifier.dart';


const double _kSubmitBarHeight = 76;

// Stores edited quantities per order (keyed by orderId -> {orderItemId: qty})
final editedQtyProvider = StateProvider.family<Map<int, double>, int>((ref, orderId) => {});

// Used to force-refresh local draft UI (qty inputs, weight review controllers, etc.)
final orderDetailsRefreshNonceProvider = StateProvider.family<int, int>((ref, orderId) => 0);



class PricingUtils {
  /// Computes final price based on business rules:
  /// - qty cannot be less than minimum
  /// - minPrice is always included
  /// - extra units are charged only when qty > minimum
  ///
  /// final = minPrice + (max(0, qty - minimum) * pricePerUom)
  static double computeFinalPrice({
    required double qty,
    required double minimum,
    required double minPrice,
    required double pricePerUom,
  }) {
    final safeQty = qty < minimum ? minimum : qty;
    final extraUnits = (safeQty - minimum);
    final extra = (extraUnits > 0 ? extraUnits : 0) * pricePerUom;
    return minPrice + extra;
  }

  /// Clamps qty so it can't be below minimum (and never below 1 as a last resort).
  static double clampQty({
    required double qty,
    double? minimum,
  }) {
    final minQty = (minimum != null && minimum > 0) ? minimum : 1.0;
    if (qty.isNaN || qty.isInfinite) return minQty;
    return qty < minQty ? minQty : qty;
  }
}

class _PricingFieldReader {
  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _tryNum(dynamic Function() getter) {
    try {
      return _num(getter());
    } catch (_) {
      return null;
    }
  }

  static double computeItemBasePrice(VendorOrderItemModel item, double qty) {
    final pricePerUom =
        _tryNum(() => (item as dynamic).pricePerUom) ??
        _tryNum(() => (item as dynamic).price_per_uom);

    final minimum = _tryNum(() => (item as dynamic).minimum);

    final minPrice =
        _tryNum(() => (item as dynamic).minPrice) ??
        _tryNum(() => (item as dynamic).min_price);

    // If we don't have enough fields to recompute, fall back to backend computedPrice.
    if (pricePerUom == null || minimum == null || minPrice == null) {
      return _num(item.computedPrice);
    }

    final safeQty = PricingUtils.clampQty(qty: qty, minimum: minimum);
    return PricingUtils.computeFinalPrice(
      qty: safeQty,
      minimum: minimum,
      minPrice: minPrice,
      pricePerUom: pricePerUom,
    );
  }

  static double computeOptionsTotal(VendorOrderItemModel item) {
    double sum = 0;
    for (final o in item.options) {
      // Prefer computedPrice, fall back to price
      final v = o.computedPrice ?? o.price;
      sum += _num(v);
    }
    return sum;
  }
}

class _OrderTotals {
  const _OrderTotals({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.grandTotal,
  });

  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double grandTotal;
}

class _OrderTotalsCalculator {
  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double _clampQty(double v, {required double minimum}) {
    if (v.isNaN || v.isInfinite) return minimum;
    return v < minimum ? minimum : v;
  }

  /// Recomputes subtotal + grand total live when vendor edits quantities.
  ///
  /// - Uses order-level fees (delivery/service/discount) as-is.
  /// - Subtotal is computed as: sum(itemBasePrice(qty) + sum(optionPrices)).
  /// - If pricing fields are missing, falls back to backend item.computedPrice.
  static _OrderTotals compute({
    required VendorOrderModel order,
    required Map<int, double> editedQty,
  }) {
    final deliveryFee = order.deliveryFee;
    final serviceFee = order.serviceFee;
    final discount = order.discount;

    double subtotal = 0;

    for (final item in order.items) {
      final baseQty = _num(item.quantity);
      // Determine minimum (default 1 if missing)
      final minimum = (() {
        try {
          final v = (item as dynamic).minimum;
          final n = _num(v);
          return n > 0 ? n : 1.0;
        } catch (_) {
          return 1.0;
        }
      })();

      final desiredQty = editedQty[item.id] ?? baseQty;
      final effectiveQty = _clampQty(desiredQty, minimum: minimum);

      final basePrice = _PricingFieldReader.computeItemBasePrice(item, effectiveQty);
      final optionsTotal = _PricingFieldReader.computeOptionsTotal(item);
      subtotal += (basePrice + optionsTotal);
    }

    // If there are no edits, prefer backend subtotal (authoritative).
    // This avoids drift if backend subtotal includes other components.
    if (editedQty.isEmpty) {
      subtotal = order.subtotal;
    }

    final grandTotal = subtotal + deliveryFee + serviceFee - discount;

    return _OrderTotals(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      grandTotal: grandTotal,
    );
  }
}

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

    void clearLocalEdits() {
      ref.read(editedQtyProvider(orderId).notifier).state = {};
      ref.read(orderDetailsRefreshNonceProvider(orderId).notifier).state++;
    }
    
    return Scaffold(
      appBar: AppBar(
      title: const Text('Order Details'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // ✅ Clear local edits so UI reflects server values
            clearLocalEdits();

            // 🔁 Force refresh vendor orders
            ref.invalidate(
              vendorOrdersProvider(
                (vendorId: vendorId, shopId: shopId),
              ),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refreshing order...'),
                duration: Duration(milliseconds: 700),
              ),
            );
          },
        ),
      ],
    ),

      bottomNavigationBar: asyncOrders.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (orders) {
          final order = orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => throw Exception('Order not found'),
          );

          // If vendor edited qtys (Picked Up), recompute subtotal + grand total live.
          final edited = ref.watch(editedQtyProvider(order.id));
          final totals = _OrderTotalsCalculator.compute(
            order: order,
            editedQty: edited,
          );
          final grandTotal = totals.grandTotal;

          if (order.status != "completed" && order.status != "canceled" && order.status != "delivered") {
            return _SubmitBar(
              orderStatus: order.status,
              totalLabel: _money(grandTotal),
              buttonLabel: OrderStatusUtils.submitButtonLabel(
                OrderStatusUtils.statusToLabel(order.status),
              ),
              loadingKey: 'vendor_order_submit_${order.id}',
              onPressed: () {
                final edited = ref.read(editedQtyProvider(order.id));
                final qtyFields = (edited.isEmpty)
                    ? null
                    : {
                        'items': edited.entries
                            .map((e) => {
                                  'id': e.key,
                                  'qty_actual': e.value,
                                })
                            .toList(),
                      };

                return _handleSubmitStatus(
                  context: context,
                  ref: ref,
                  order: order,
                  fields: qtyFields,
                );
              },
            );
          }

          // No submit action for closed/terminal statuses.
          return const SizedBox.shrink();
        },
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          // ✅ Clear local edits so UI reflects server values
          clearLocalEdits();

          // 🔁 Invalidate provider
          ref.invalidate(
            vendorOrdersProvider((vendorId: vendorId, shopId: shopId)),
          );

          // ⏳ Wait until new data loads
          await ref.read(
            vendorOrdersProvider((vendorId: vendorId, shopId: shopId)).future,
          );
        },
        child: asyncOrders.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 200),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text('Error: $e'),
              const SizedBox(height: 12),
              const Text('Pull down to retry.'),
            ],
          ),
          data: (orders) {
            final order = orders.firstWhere(
              (o) => o.id == orderId,
              orElse: () => throw Exception('Order not found'),
            );

            final nonce = ref.watch(orderDetailsRefreshNonceProvider(orderId));

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(), // required
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + _kSubmitBarHeight,
              ),
              children: [
                _CustomerCard(order: order),
                const SizedBox(height: 12),
                _OrderHeaderCard(order: order),
                const SizedBox(height: 12),

                // ✅ Weight Review (only when picked up)
                if (_isPickedUp(order.status)) ...[
                  // key forces controllers to reset when we clear local edits
                  _WeightReviewSection(key: ValueKey('wr_${order.id}_$nonce'), order: order),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),

      );
  }
}

///////////////////////////////////////////////////////////////////////////////
/// ORDER HEADER
///////////////////////////////////////////////////////////////////////////////
class _OrderHeaderCard extends ConsumerWidget {
  const _OrderHeaderCard({required this.order});

  final VendorOrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = order.items;
    final itemsCount = items.length;

    // Edited quantities (only used when status is Picked Up)
    final editedQty = ref.watch(editedQtyProvider(order.id));

    final totals = _OrderTotalsCalculator.compute(order: order, editedQty: editedQty);
    final subtotal = totals.subtotal;
    final deliveryFee = totals.deliveryFee;
    final serviceFee = totals.serviceFee;
    final discount = totals.discount;
    final grandTotal = totals.grandTotal;

    final grandTotalLabel = _money(grandTotal);

    return Card(
       margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // ✅ removes the 2 lines
        ),
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

            final baseQty = _numAny(item.quantity);
            final effectiveQtyRaw = editedQty[item.id] ?? baseQty;
            final effectiveQty = _clampQty(effectiveQtyRaw);

            final itemPrice = _computeItemPrice(item, effectiveQty);
            final itemPriceLabel = _money(itemPrice);

            final qty = baseQty; // original qty
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
                  if (_isPickedUp(order.status))
                    _EditableQtyLine(
                      orderId: order.id,
                      orderItemId: item.id,
                      initialQty: effectiveQty,
                      uom: uom,
                      minimum: _num((item as dynamic).minimum),
                    )
                  else
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


  double _numAny(dynamic v) => _num(v);

  double _clampQty(double v) {
    if (v.isNaN || v.isInfinite) return 1;
    return v < 1 ? 1 : v;
  }

  double? _tryNum(dynamic Function() getter) {
    try {
      return _num(getter());
    } catch (_) {
      return null;
    }
  }

  double _computeItemPrice(VendorOrderItemModel item, double qty) {
    // Pull pricing fields from item (supports both camelCase and snake_case).
    final pricePerUom =
        _tryNum(() => (item as dynamic).pricePerUom) ??
        _tryNum(() => (item as dynamic).price_per_uom);

    final minimum =
        _tryNum(() => (item as dynamic).minimum);

    final minPrice =
        _tryNum(() => (item as dynamic).minPrice) ??
        _tryNum(() => (item as dynamic).min_price);

    // If we don't have enough fields to recompute, fall back to backend computedPrice.
    if (pricePerUom == null || minimum == null || minPrice == null) {
      return _num(item.computedPrice);
    }

    final safeQty = PricingUtils.clampQty(qty: qty, minimum: minimum);
    return PricingUtils.computeFinalPrice(
      qty: safeQty,
      minimum: minimum,
      minPrice: minPrice,
      pricePerUom: pricePerUom,
    );
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
 
class _SubmitBar extends ConsumerWidget {
  const _SubmitBar({
    required this.totalLabel,
    required this.orderStatus,
    required this.buttonLabel,
    required this.onPressed,
    required this.loadingKey,
    this.disabled = false,
  });

  final String totalLabel;
  final String orderStatus;
  final String buttonLabel;
  final Future<void> Function() onPressed;
  final String loadingKey;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(submitLoadingProvider(loadingKey));
    final isDisabled = disabled || isSubmitting;

    const lift = 10.0; // 👈 how high you want it raised

    return SafeArea(
      top: false,
      child: SizedBox(
        // ✅ make the whole bar taller, so it has "air" below the button
        height: 48 + lift,
        child: Align(
          alignment: Alignment.topCenter, // ✅ button sits higher
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isDisabled
                    ? null
                    : () async {
                        await ref
                            .read(submitLoadingProvider(loadingKey).notifier)
                            .run(() async {
                          await onPressed();
                          return true;
                        });
                      },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
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
          ),
        ),
      ),
    );
  }

 
 }

String _money(double value, {String symbol = '₱ '}) {
  return '$symbol${value.toStringAsFixed(2)}';
}


bool _isPickedUp(String status) {
  final s = status.trim().toLowerCase();
  return s == 'pickedup' ||
      s == 'picked_up' ||
      s == 'picked up' ||
      s == 'picked-up';
}


class _EditableQtyLine extends ConsumerStatefulWidget {
  const _EditableQtyLine({
    required this.orderId,
    required this.orderItemId,
    required this.initialQty,
    required this.uom,
    required this.minimum,
  });

  final int orderId;
  final int orderItemId;
  final num initialQty;
  final String uom;
  final num minimum;

  @override
  ConsumerState<_EditableQtyLine> createState() => _EditableQtyLineState();
}

class _EditableQtyLineState extends ConsumerState<_EditableQtyLine> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: PricingUtils.clampQty(qty: widget.initialQty.toDouble(), minimum: widget.minimum.toDouble()).toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pushToState(String raw) {
    final parsed = double.tryParse(raw.trim());
    final minQty = widget.minimum.toDouble() > 0 ? widget.minimum.toDouble() : 1.0;

    // Disallow null/zero/negative and disallow less than minimum.
    final qty = PricingUtils.clampQty(qty: parsed ?? minQty, minimum: minQty);

    // If user typed less than min, snap the field back to min.
    if (parsed != null && parsed < minQty) {
      final prevSel = _ctrl.selection;
      _ctrl.text = minQty.toString();
      _ctrl.selection = prevSel.copyWith(
        baseOffset: _ctrl.text.length,
        extentOffset: _ctrl.text.length,
      );
    }

    final current = ref.read(editedQtyProvider(widget.orderId));
    final next = {...current, widget.orderItemId: qty};

    // use read so this widget doesn't rebuild on each keystroke
    ref.read(editedQtyProvider(widget.orderId).notifier).state = next;
  }

  @override
  Widget build(BuildContext context) {
    final uom = widget.uom.trim();
    final uomLabel = uom.isEmpty ? '' : ' ${uom.toUpperCase()}';

    return Row(
      children: [
        const Text('Qty:', style: TextStyle(color: Colors.black54)),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _pushToState,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Text(uomLabel, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}


///////////////////////////////////////////////////////////////////////////////
/// WEIGHT REVIEW (only shown when status is Picked Up)
///////////////////////////////////////////////////////////////////////////////
class _WeightReviewSection extends ConsumerStatefulWidget {
  const _WeightReviewSection({super.key, required this.order});

  final VendorOrderModel order;

  @override
  ConsumerState<_WeightReviewSection> createState() => _WeightReviewSectionState();
}

class _WeightReviewSectionState extends ConsumerState<_WeightReviewSection> {
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _picker = ImagePicker();

  final List<File> _images = [];
  bool _submitting = false;
  double? _uploadProgress; // optional; only set if you wire onSendProgress

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_submitting) return;

    final remaining = 10 - _images.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 photos reached')),
      );
      return;
    }

    final picks = await _picker.pickMultiImage(imageQuality: 85);
    if (picks.isEmpty) return;

    setState(() {
      for (final x in picks.take(remaining)) {
        _images.add(File(x.path));
      }
    });
  }

  Future<void> _pickFromCamera() async {
    if (_submitting) return;

    if (_images.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 photos reached')),
      );
      return;
    }

    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null) return;

    setState(() => _images.add(File(x.path)));
  }

  Widget _buildReorderableThumbs() {
    // Horizontal reorderable thumbnails
    return SizedBox(
      height: 92,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: _images.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _images.removeAt(oldIndex);
            _images.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final file = _images[index];
          return Container(
            key: ValueKey(file.path),
            width: 92,
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                ),

                // Drag handle
                Positioned(
                  right: 14,
                  top: 6,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.drag_indicator, size: 16, color: Colors.white),
                    ),
                  ),
                ),

                // Remove
                Positioned(
                  left: 6,
                  top: 6,
                  child: InkWell(
                    onTap: _submitting
                        ? null
                        : () {
                            setState(() => _images.removeAt(index));
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final weightText = _weightCtrl.text.trim();
    final weight = double.tryParse(weightText);

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight (kg).')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = null;
    });

    try {
      final edited = ref.read(editedQtyProvider(widget.order.id));

      await _handleSubmitStatus(
        context: context,
        ref: ref,
        order: widget.order,
        fields: {
          // adjust these keys to match your backend
          'weight_kg': weight,
          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          'items': edited.isEmpty
              ? null
              : edited.entries
                  .map((e) => {
                        // ✅ required by weight review API
                        'order_item_id': e.key,
                        'item_qty': e.value,
                        'uploaded': 0, // backend should flip to 1/true after storing image(s)
                        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                      }..removeWhere((k, v) => v == null))
                  .toList(),
        }..removeWhere((k, v) => v == null),
        images: _images,
      );

      if (!mounted) return;

      // Reset form after success
      setState(() {
        _weightCtrl.clear();
        _notesCtrl.clear();
        _images.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight review submitted')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.scale, size: 18),
                SizedBox(width: 8),
                Text(
                  'Weight Review',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Add the actual weight and photos (optional). This will move the order to the next step.',
              style: TextStyle(color: Colors.black54),
            ), 

            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_images.isEmpty)
              const Text('Add up to 10 photos (optional).')
            else ...[
              const Text('Drag to reorder photos (optional).'),
              const SizedBox(height: 8),
              _buildReorderableThumbs(),
            ],

            if (_uploadProgress != null) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 6),
              Text(
                'Uploading: ${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.black54),
              ),
            ],

             
          ],
        ),
      ),
    );
  }
}

Future<void> _handleSubmitStatus({
  required BuildContext context,
  required WidgetRef ref,
  required VendorOrderModel order,
  Map<String, dynamic>? fields,
  List<File>? images,
}) async {
  final nextSlug = OrderStatusUtils.nextStatusCode(order.status);

  if (nextSlug == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No next action available')),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Confirm Action',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Move order to\n${OrderStatusUtils.statusLabel(nextSlug)}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final repo = ref.read(vendorOrderRepositoryProvider);

    // =====================================================
    // Build body
    // =====================================================
    Map<String, dynamic>? body;

    if (fields != null && fields.isNotEmpty) {
      body = {...fields};
    }

    if (images != null && images.isNotEmpty) {
      body ??= {};
      // ✅ keep existing multi-image support
      body['images'] = images;
      // ✅ also send a single 'image' key for backends expecting one file
      body['image'] = images.first;
    }

    // =====================================================
    // Session
    // =====================================================
    final session = ref.read(sessionNotifierProvider);
    final vendorId = session.vendorId;
    final shopId = session.activeShopId;

    // =====================================================
    // API Call
    // =====================================================
    
    if(nextSlug== 'weight_review')
    {
          await repo.postWeightReview(
          vendorId: vendorId,
          shopId: shopId,
          orderId: order.id,
          body: body, // includes order_item_id, item_qty, uploaded, notes, image/images
        );
    }
    else
    {
      await repo.postStatusAction(
        vendorId: vendorId,
        shopId: shopId,
        orderId: order.id,
        actionSlug: nextSlug,
        body: body,
        );
    }
    

    if (!context.mounted) return;

    // =====================================================
    // Refresh & WAIT for completion
    // =====================================================
    final params = (
      vendorId: int.parse(vendorId!), // <-- convert
      shopId: shopId,
    );

    ref.invalidate(vendorOrdersProvider(params as VendorShopParams));
    await ref.read(vendorOrdersProvider(params).future);

  } catch (e) {
    if (!context.mounted) return;

    String message = 'Something went wrong';

    // ✅ If Dio error → extract API response
    if (e is DioException) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        message = data;
      } else {
        message = e.message ?? message;
      }
    } else {
      message = e.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message')),
    );
  }
}



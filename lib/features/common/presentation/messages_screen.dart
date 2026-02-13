import 'package:flutter/material.dart';

import '../../../features/customer/order/models/latest_orders_models.dart';
class OrderMessagesScreen extends StatefulWidget {
  final LatestOrder? order;

  const OrderMessagesScreen({super.key, this.order});

  @override
  State<OrderMessagesScreen> createState() => _OrderMessagesScreenState();
}


class _OrderMessagesScreenState extends State<OrderMessagesScreen> {
  final _controller = TextEditingController();

  // ---- helpers to safely read fields from `order` without tight coupling ----
  T? _get<T>(String key) {
    final o = widget.order;
    if (o == null) return null;
    try {
      final dyn = o as dynamic;
      return dyn[key] as T?; // if it's a map-like model
    } catch (_) {
      try {
        final dyn = o as dynamic;
        return dyn
            .toJson()[key] as T?; // if your model has toJson()
      } catch (_) {
        return null;
      }
    }
  }

  dynamic _getDyn(String key) {
    final o = widget.order;
    if (o == null) return null;
    try {
      final dyn = o as dynamic;
      // try property access (model)
      return dyn
          .toJson()[key]; // safest if your model has toJson()
    } catch (_) {
      try {
        final dyn = o as dynamic;
        return dyn[key];
      } catch (_) {
        return null;
      }
    }
  }

  num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'SGD':
        return 'S\$';
      case 'PHP':
        return '₱';
      case 'USD':
        return '\$';
      default:
        return '$code ';
    }
  }

  String _fmtMoney(String currency, num amount) =>
      '${_currencySymbol(currency)} ${amount.toStringAsFixed(2)}';

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'published':
        return Colors.blue;
      case 'matching':
        return Colors.indigo;
      case 'accepted':
      case 'pickup':
      case 'picked_up':
        return Colors.orange;
      case 'washing':
        return Colors.deepPurple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) =>
      s.isEmpty ? 'Unknown' : s.replaceAll('_', ' ').toUpperCase();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // These keys match your API payload; if your model is not toJson-based yet,
    // it will still render with fallbacks.
    final order = widget.order;

    // ---------- ORDER CORE ----------
    final orderId = order?.id;
    final status = order?.status ?? '';

    // ---------- SHOP ----------
    final shop = order?.partner;

    final shopName = shop?.name ?? 'Shop';
    final shopPhoto = shop?.profilePhotoUrl;
    final avgRating = shop?.avgRating ?? 0;
    final ratingsCount = shop?.ratingsCount ?? 0;

    // ---------- MONEY ----------
    final currency = order?.currencyCode ?? 'SGD';

    final subtotal = order?.subtotalAmount ?? 0;
    final deliveryFee = order?.deliveryFeeAmount ?? 0;
    final serviceFee = order?.serviceFeeAmount ?? 0;
    final discount = order?.discountAmount ?? 0;
    final total = order?.totalAmount ?? 0;


    // vendor_shop block (from your latest endpoint)
    final vendorShop = _getDyn('vendor_shop');
  
     // Dummy chat messages (UI-only for now)
    final demoMessages = <_ChatMsg>[
      _ChatMsg(fromMe: false, text: 'Hi! We’re preparing your laundry now.', time: '2:14 PM'),
      _ChatMsg(fromMe: true, text: 'Thanks! About what time is delivery?', time: '2:16 PM'),
      _ChatMsg(fromMe: false, text: 'Estimated 5:30 PM today 😊', time: '2:18 PM'),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(orderId != null ? 'Order #$orderId' : 'Order Messages'),
            const SizedBox(height: 2),
            Text(
              shopName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ---------- TOP INFO STRIP ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                _HeaderCard(
                  shopName: shopName,
                  photoUrl: shopPhoto,
                  rating: avgRating,
                  ratingsCount: ratingsCount.toInt(),
                  status: status,
                  statusColor: _statusColor(status),
                  statusLabel: _statusLabel(status),
                ),

                const SizedBox(height: 10),
                _OrderSummaryCard(
                  currency: currency,
                  fmtMoney: _fmtMoney,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  serviceFee: serviceFee,
                  discount: discount,
                  total: total,
                ),
               
                _OrderProgressBar(status: status),

                const SizedBox(height: 10),
                _QuickActionsRow(
                  onCall: () {
                    // UI-only for now
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Call action (hook later)')),
                    );
                  },
                  onDirections: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Directions action (hook later)')),
                    );
                  },
                  onTrack: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Track action (hook later)')),
                    );
                  },
                ),
              ],
            ),
          ),
        
          // ---------- CHAT LIST ----------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              itemCount: demoMessages.length,
              itemBuilder: (context, index) {
                final m = demoMessages[index];
                return _ChatBubble(msg: m);
              },
            ),
          ),
          // ✅ NEW: nicer composer with attach
          _ChatComposer(
            hint: 'Message $shopName…',
            controller: _controller,
            onSend: _send,
            onAttach: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attach (hook later)')),
              );
            },
          ),
          // ---------- COMPOSER ----------
          /* Old version without attach button
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black.withOpacity(0.06),
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message $shopName…',
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ),
          */
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    // UI-only now:
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent: $text')),
    );
  }
}

// ------------------ UI widgets ------------------

class _HeaderCard extends StatelessWidget {
  final String shopName;
  final String? photoUrl;
  final num rating;
  final int ratingsCount;
  final String status;
  final Color statusColor;
  final String statusLabel;

  const _HeaderCard({
    required this.shopName,
    required this.photoUrl,
    required this.rating,
    required this.ratingsCount,
    required this.status,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? const Icon(Icons.storefront, color: Colors.black54)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating == 0 ? 'No ratings yet' : '${rating.toStringAsFixed(1)} ($ratingsCount)',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final String currency;
  final String Function(String, num) fmtMoney;
  final num subtotal;
  final num deliveryFee;
  final num serviceFee;
  final num discount;
  final num total;

  const _OrderSummaryCard({
    required this.currency,
    required this.fmtMoney,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
  });

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _row('Subtotal', fmtMoney(currency, subtotal)),
          _row('Delivery Fee', fmtMoney(currency, deliveryFee)),
          _row('Service Fee', fmtMoney(currency, serviceFee)),
          _row('Discount', discount == 0 ? fmtMoney(currency, 0) : '- ${fmtMoney(currency, discount)}'),
          Divider(color: Colors.grey.withOpacity(0.25)),
          _row('Total', fmtMoney(currency, total), bold: true),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onCall;
  final VoidCallback onDirections;
  final VoidCallback onTrack;

  const _QuickActionsRow({
    required this.onCall,
    required this.onDirections,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(Icons.call, 'Call', onCall),
        const SizedBox(width: 10),
        chip(Icons.directions, 'Directions', onDirections),
        const SizedBox(width: 10),
        chip(Icons.local_shipping, 'Track', onTrack),
      ],
    );
  }
}

class _ChatMsg {
  final bool fromMe;
  final String text;
  final String time;

  _ChatMsg({
    required this.fromMe,
    required this.text,
    required this.time,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final align = msg.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = msg.fromMe ? Colors.black : Colors.white;
    final textColor = msg.fromMe ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              msg.text,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            msg.time,
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }
}
class _OrderProgressBar extends StatelessWidget {
  final String status;
  const _OrderProgressBar({required this.status});

  int _stepIndex(String s) {
    final v = s.toLowerCase();
    if (v == 'published') return 0;
    if (v == 'matching') return 1;
    if (v == 'accepted' || v == 'pickup' || v == 'picked_up') return 2;
    if (v == 'washing') return 3;
    if (v == 'delivered' || v == 'completed') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _stepIndex(status);
    final steps = const ['Placed', 'Matching', 'Pickup', 'Washing', 'Delivered'];

    Widget dot(bool active) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.black : Colors.grey[300],
          ),
        );

    Widget line(bool active) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: active ? Colors.black : Colors.grey[300],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                dot(i <= idx),
                if (i != steps.length - 1) line(i < idx),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++)
                Expanded(
                  child: Text(
                    steps[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == idx ? FontWeight.w800 : FontWeight.w500,
                      color: i <= idx ? Colors.black : Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


class _ChatComposer extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _ChatComposer({
    required this.hint,
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onAttach,
              icon: const Icon(Icons.attach_file),
              splashRadius: 22,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onSend,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/customer/order/models/latest_orders_models.dart';

// ✅ Change this import to wherever your apiClientProvider lives in your project.
import '../../../core/network/api_client.dart';

class OrderMessagesScreen extends ConsumerStatefulWidget {
  final LatestOrder? order;

  /// Optional: if you later add route /messages/orders/:orderId
  final String? orderId;
  

  const OrderMessagesScreen({super.key, this.order, this.orderId});

  @override
  ConsumerState<OrderMessagesScreen> createState() => _OrderMessagesScreenState();
}

class _OrderMessagesScreenState extends ConsumerState<OrderMessagesScreen> {
  final _controller = TextEditingController();

  Timer? _pollTimer;

  bool _loading = true;
  bool _locked = false;
  bool _sending = false; // ✅ NEW
  String? _threadId;

  int? _myUserId;
  List<_ChatMsg> _messages = [];

  // ---- helpers to safely read fields from `order` without tight coupling ----
  T? _get<T>(String key) {
    final o = widget.order;
    if (o == null) return null;
    try {
      final dyn = o as dynamic;
      return dyn[key] as T?;
    } catch (_) {
      try {
        final dyn = o as dynamic;
        return dyn.toJson()[key] as T?;
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
      return dyn.toJson()[key];
    } catch (_) {
      try {
        final dyn = o as dynamic;
        return dyn[key];
      } catch (_) {
        return null;
      }
    }
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
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

      /// ---------------- ORDER CREATED ----------------
      case 'created':
        return Colors.grey; // Order draft / just placed

      case 'published':
        return Colors.blue; // Broadcast to vendors


      /// ---------------- ACCEPTANCE ----------------
      case 'accepted':
        return Colors.teal; // Vendor accepted


      /// ---------------- PICKUP ----------------
      case 'pickup_scheduled':
        return Colors.orangeAccent;

      case 'picked_up':
        return Colors.orange;


      /// ---------------- WEIGHT REVIEW ----------------
      case 'weight_reviewed':
        return Colors.amber;

      case 'weight_accepted':
        return Colors.amber.shade700;


      /// ---------------- WASHING ----------------
      case 'washing':
        return Colors.deepPurple;


      /// ---------------- READY ----------------
      case 'ready':
        return Colors.indigo;


      /// ---------------- DELIVERY ----------------
      case 'delivery_scheduled':
        return Colors.lightBlue;

      case 'delivering':
        return Colors.blueAccent;

      case 'delivered':
        return Colors.green;


      /// ---------------- COMPLETED ----------------
      case 'completed':
        return Colors.green.shade800;


      /// ---------------- CANCELED ----------------
      case 'canceled':
      case 'cancelled':
        return Colors.red;


      /// ---------------- DEFAULT ----------------
      default:
        return Colors.grey;
    }
  }


  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'created':
        return 'Order Created';

      case 'published':
        return 'Searching for Vendor';

      case 'accepted':
        return 'Vendor Accepted';

      case 'pickup_scheduled':
        return 'Pickup Scheduled';

      case 'picked_up':
        return 'Laundry Picked Up';

      case 'weight_reviewed':
        return 'Weight Reviewed';

      case 'weight_accepted':
        return 'Weight Confirmed';

      case 'washing':
        return 'Washing in Progress';

      case 'ready':
        return 'Ready for Delivery';

      case 'delivery_scheduled':
        return 'Delivery Scheduled';

      case 'delivering':
        return 'Out for Delivery';

      case 'delivered':
        return 'Delivered';

      case 'completed':
        return 'Order Completed';

      case 'canceled':
      case 'cancelled':
        return 'Order Canceled';

      default:
        return s;
    }
  }


  String? get _effectiveOrderId {
    if (widget.orderId != null && widget.orderId!.trim().isNotEmpty) {
      return widget.orderId!.trim();
    }
    final id = widget.order?.id;
    return id?.toString();
  }

  Dio get _dio {
    final api = ref.read(apiClientProvider);
    // Your ApiClient in this project exposes `dio`.
    return (api as dynamic).dio as Dio;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final orderIdStr = _effectiveOrderId;
    if (orderIdStr == null) {
      setState(() => _loading = false);
      _toast('Missing order id.');
      return;
    }

    final orderId = int.tryParse(orderIdStr);
    if (orderId == null) {
      setState(() => _loading = false);
      _toast('Invalid order id.');
      return;
    }

    try {
      await _ensureThread(orderId);
      await _tryLoadMe(); // for correct bubble alignment
      await _loadMessages();
    } catch (e) {
      // ✅ Don't let init fail silently
      if (!mounted) return;
      _toast('Messenger setup failed. Please try again.');
      setState(() => _loading = false);
      return;
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _threadId == null) return;
      await _loadMessages(silent: true);
    });
  }

  Future<void> _ensureThread(int orderId) async {
    setState(() => _loading = true);

    try {
      final res = await _dio.post(
        '/api/v1/chat/threads',
        data: {'scope': 'order', 'order_id': orderId},
      );

      final data = (res.data as Map).cast<String, dynamic>();

      // ✅ Safer parsing (won’t crash if API shape differs)
      final threadRaw = data['thread'];
      if (threadRaw is! Map) {
        _threadId = null;
        _locked = false;
        if (mounted) {
          setState(() => _loading = false);
          _toast('Chat thread not returned by server.');
        }
        return;
      }

      final thread = threadRaw.cast<String, dynamic>();
      _threadId = thread['id']?.toString();
      _locked = thread['locked_at'] != null;

      if (mounted) setState(() => _loading = false);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      final code = e.response?.statusCode;
      final serverMsg = e.response?.data?.toString();

      if (code == 409) _toast('Chat is closed for this order.');
      else if (code == 403) _toast('Not allowed.');
      else _toast('Network / server error creating chat.');

      // ✅ Helpful debug info
      debugPrint('ensureThread error: $code $serverMsg');
      _threadId = null;
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('ensureThread unexpected error: $e');
      _threadId = null;
    }
  }

  Future<void> _tryLoadMe() async {
    // Optional endpoint. If you don't have /api/v1/me yet, it will just fail silently.
    try {
      final res = await _dio.get('/api/v1/me');
      final id = _asInt((res.data as Map)['id']);
      if (!mounted) return;
      if (id != null) setState(() => _myUserId = id);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final threadId = _threadId;
    if (threadId == null) return;

    if (!silent) setState(() => _loading = true);

    try {
      final res = await _dio.get('/api/v1/chat/threads/$threadId/messages');
      final list = (res.data['messages'] as List).cast<Map<String, dynamic>>();

      // Your backend currently returns messages in DESC order (newest first).
      // Your UI works fine either way. If you want oldest first, reverse it.
      final msgs = list.map((j) {
        final senderId = _asInt(j['sender_id']) ?? 0;
        final body = (j['body'] ?? '').toString();
        final sentAt = (j['sent_at'] ?? j['created_at'] ?? '').toString();

        final fromMe = _myUserId != null ? senderId == _myUserId : false;

        return _ChatMsg(
          fromMe: fromMe,
          text: body,
          time: _prettyTime(sentAt),
        );
      }).toList();

      setState(() {
        _messages = msgs;
        _loading = false;
      });
    } catch (_) {
      if (!silent) setState(() => _loading = false);
    }
  }

  String _prettyTime(String iso) {
    if (iso.isEmpty) return '';
    if (iso.length >= 16 && iso.contains(':')) {
      return iso.substring(11, 16);
    }
    return iso;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _send() async {
    if (_sending) return;

    final threadId = _threadId;
    if (threadId == null) {
      _toast('Chat is not ready yet. Please wait 1–2 seconds.');
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) {
      _toast('Type a message first.');
      return;
    }

    if (_locked) {
      _toast('Chat is closed for this order.');
      return;
    }

    setState(() => _sending = true);

    try {
      await _dio.post(
        '/api/v1/chat/threads/$threadId/messages',
        data: {'body': text},
      );

      _controller.clear();
      await _loadMessages(silent: true);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final serverMsg = e.response?.data?.toString();
      debugPrint('send message error: $code $serverMsg');

      if (code == 409) {
        setState(() => _locked = true);
        _toast('Chat is closed for this order.');
      } else {
        _toast(serverMsg != null ? 'Failed: $serverMsg' : 'Failed to send message.');
      }
    } catch (e) {
      debugPrint('send message unexpected error: $e');
      _toast('Failed to send message.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ✅ Call button triggers an FCM invite (no phone dialer)
  Future<void> _startCallInvite() async {
    final orderIdStr = _effectiveOrderId;
    final orderId = orderIdStr == null ? null : int.tryParse(orderIdStr);
    if (orderId == null) {
      _toast('Missing order id.');
      return;
    }

    try {
      final res = await _dio.post('/api/v1/calls/invite', data: {
        'scope': 'order',
        'order_id': orderId,
      });

      final callId = (res.data['call_id'] ?? '').toString();
      if (callId.isNotEmpty) {
        _toast('Calling…');
      } else {
        _toast('Call invite sent.');
      }
    } catch (_) {
      _toast('Failed to start call.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    // ---------- ORDER CORE ----------
    final orderId = _effectiveOrderId ?? (order?.id?.toString() ?? '');
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

    // vendor_shop block (from your latest endpoint) (kept, optional)
    final vendorShop = _getDyn('vendor_shop');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(orderId.isNotEmpty ? 'Order #$orderId' : 'Order Messages'),
            
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Call',
            icon: const Icon(Icons.call),
            onPressed: _startCallInvite, // ✅ FCM invite
          ),
        ],
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

                // ✅ Collapsible order summary + Total on right
                _OrderSummaryCollapsibleCard(
                  currency: currency,
                  fmtMoney: _fmtMoney,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  serviceFee: serviceFee,
                  discount: discount,
                  total: total,
                  locked: _locked,
                  vendorShopDebug: vendorShop,
                ),

              ],
            ),
          ),

          // ---------- CHAT LIST ----------
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadMessages(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        return _ChatBubble(msg: m);
                      },
                    ),
                  ),
          ),

          _ChatComposer(
            hint: _locked ? 'Chat closed' : 'Message $shopName…',
            controller: _controller,
            onSend: _locked ? () => _toast('Chat is closed for this order.') : _send,
            onAttach: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attach (hook later)')),
              );
            },
          ),
        ],
      ),
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
            child: ClipOval(
              child: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? Image.network(
                      photoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.storefront, color: Colors.black54),
                    )
                  : const Icon(Icons.storefront, color: Colors.black54),
            ),
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
                      rating == 0
                          ? 'No ratings yet'
                          : '${rating.toStringAsFixed(1)} ($ratingsCount)',
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

class _OrderSummaryCollapsibleCard extends StatelessWidget {
  final String currency;
  final String Function(String, num) fmtMoney;
  final num subtotal;
  final num deliveryFee;
  final num serviceFee;
  final num discount;
  final num total;

  final bool locked;
  final dynamic vendorShopDebug;

  const _OrderSummaryCollapsibleCard({
    required this.currency,
    required this.fmtMoney,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
    required this.locked,
    required this.vendorShopDebug,
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
    final totalStr = fmtMoney(currency, total);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Order Summary',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                totalStr,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    locked ? 'Chat closed for this order' : 'Tap to view breakdown',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Closed',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          children: [
            const SizedBox(height: 8),
            _row('Subtotal', fmtMoney(currency, subtotal)),
            _row('Delivery Fee', fmtMoney(currency, deliveryFee)),
            _row('Service Fee', fmtMoney(currency, serviceFee)),
            _row(
              'Discount',
              discount == 0 ? fmtMoney(currency, 0) : '- ${fmtMoney(currency, discount)}',
            ),
            Divider(color: Colors.grey.withOpacity(0.25)),
            _row('Total', totalStr, bold: true),

            // Optional debug section (remove anytime)
            if (vendorShopDebug != null) ...[
              const SizedBox(height: 8),
              Text(
                'vendor_shop: $vendorShopDebug',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
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

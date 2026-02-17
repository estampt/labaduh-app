import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import 'package:labaduh/core/domain/order_status.dart';
import 'package:labaduh/core/utils/order_status_utils.dart';
import '../model/vendor_order_model.dart';
import '../state/vendor_orders_provider.dart';

class VendorOrdersTab extends ConsumerStatefulWidget {
  const VendorOrdersTab({
    super.key,
    this.vendorId = 2,
    this.shopId = 2,
  });

  final int vendorId;
  final int shopId;

  @override
  ConsumerState<VendorOrdersTab> createState() => _VendorOrdersTabState();
}

class _VendorOrdersTabState extends ConsumerState<VendorOrdersTab> {
  String? statusFilter; // raw API status string e.g. "completed"
  String q = '';

  @override
  Widget build(BuildContext context) {
    final params = (vendorId: widget.vendorId, shopId: widget.shopId);

    // ✅ This is the key change:
    final asyncOrders = ref.watch(vendorOrdersProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(vendorOrdersProvider(params)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(vendorOrdersProvider(params).future);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search order/customer/service/status',
                ),
                onChanged: (v) => setState(() => q = v.trim()),
              ),
              const SizedBox(height: 10),

              // ✅ Filter chips (built from API data)
              asyncOrders.when(
                loading: () => _buildChips(
                  statuses: const [],
                  selected: statusFilter,
                  onSelect: (v) => setState(() => statusFilter = v),
                ),
                error: (_, __) => _buildChips(
                  statuses: const [],
                  selected: statusFilter,
                  onSelect: (v) => setState(() => statusFilter = v),
                ),
                data: (orders) {
                  final statuses = orders
                      .map((o) => o.status.trim())
                      .where((s) => s.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
                  return _buildChips(
                    statuses: statuses,
                    selected: statusFilter,
                    onSelect: (v) => setState(() => statusFilter = v),
                  );
                },
              ),

              const SizedBox(height: 12),

              Expanded(
                child: asyncOrders.when(
                  loading: () => const _LoadingList(),
                  error: (err, st) => _ErrorState(
                    message: err.toString(),
                    onRetry: () => ref.refresh(vendorOrdersProvider(params)),
                  ),
                  data: (orders) {
                    final filtered = _applyFilters(
                      orders: orders,
                      q: q,
                      statusFilter: statusFilter,
                    );

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No orders', style: TextStyle(color: Colors.black54)),
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final o = filtered[i];

                        final created = o.createdAt == null ? '-' : _formatDateTime(o.createdAt!.toLocal());
                        final updated = o.updatedAt == null ? '-' : _formatDateTime(o.updatedAt!.toLocal());

                        return _OrderCardModern(
                          id: o.id,
                          customerName: o.customerName,
                          statusLabel: o.statusLabel,
                          statusRaw: o.status,
                          itemsCount: o.itemsCount,
                          servicesLabel: o.servicesLabel,
                          createdLabel: created,
                          updatedLabel: updated,
                          onOpen: () => context.push('/v/orders/${o.id}'),
                        );
                      },

                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
  }

  List<VendorOrderModel> _applyFilters({
    required List<VendorOrderModel> orders,
    required String q,
    required String? statusFilter,
  }) {
    final query = q.trim().toLowerCase();

    return orders.where((o) {
      final idStr = o.id.toString();
      final status = o.status.trim();
      final statusLabel = o.statusLabel.toLowerCase();
      final customer = o.customerName.toLowerCase();
      final services = o.servicesLabel.toLowerCase();

      final matchQ = query.isEmpty ||
          idStr.contains(query) ||
          customer.contains(query) ||
          services.contains(query) ||
          status.toLowerCase().contains(query) ||
          statusLabel.contains(query);

      final matchF = statusFilter == null || status == statusFilter;

      return matchQ && matchF;
    }).toList();
  }
}

Widget _buildChips({
  required List<String> statuses,
  required String? selected,
  required ValueChanged<String?> onSelect,
}) {
  // Convert API statuses -> enums
  final enumStatuses = statuses
      .map((s) => OrderStatusParsing.fromApi(s))
      .where((e) => e != OrderStatus.unknown)
      .toList();

  final selectedEnum = selected == null
      ? OrderStatus.unknown
      : OrderStatusParsing.fromApi(selected);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<OrderStatus>(
        value: selectedEnum,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),

        items: [
          // ALL OPTION
          const DropdownMenuItem(
            value: OrderStatus.unknown,
            child: Text('All Orders'),
          ),

          // Dynamic statuses from API
          ...enumStatuses.map((status) {
            return DropdownMenuItem<OrderStatus>(
              value: status,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: OrderStatusUtils.color(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(OrderStatusUtils.label(status)),
                ],
              ),
            );
          }),
        ],

        onChanged: (status) {
          if (status == null) return;

          if (status == OrderStatus.unknown) {
            onSelect(null); // ALL
          } else {
            onSelect(status.toApi()); // back to API string
          }
        },
      ),
    ),
  );
}
class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const SizedBox(height: 92),
        ),
      ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
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

String _formatDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

String _statusToLabel(String status) {
  final s = status.trim();
  if (s.isEmpty) return 'Unknown';
  return s
      .split('_')
      .where((p) => p.trim().isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');
}

class _OrderCardModern extends StatelessWidget {
  const _OrderCardModern({
    required this.id,
    required this.customerName,
    required this.statusLabel,
    required this.statusRaw,
    required this.itemsCount,
    required this.servicesLabel,
    required this.createdLabel,
    required this.updatedLabel,
    required this.onOpen,
  });

  final int id;
  final String customerName;
  final String statusLabel;
  final String statusRaw;
  final int itemsCount;
  final String servicesLabel;
  final String createdLabel;
  final String updatedLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final border = Colors.grey.shade200;

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Stack(
            children: [
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: ID + customer, status on the right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '#$id • $customerName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      _StatusPill(label: statusLabel, raw: statusRaw),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Secondary line
                  Text(
                    'Items: $itemsCount',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Services: $servicesLabel',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Divider(height: 1, color: border),
                  const SizedBox(height: 10),

                  // Aligned Created/Updated
                  Row(
                    children: [
                      Expanded(
                        child: _MetaAligned(label: 'Created', value: createdLabel),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetaAligned(label: 'Updated', value: updatedLabel),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                ],
              ),

              // Modern open button (not a chevron on the edge)
              Positioned(
                right: 0,
                bottom: 0,
                child: _OpenButton(onPressed: onOpen),
              ),
            ],
          ),
        ),
      ),
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

class _MetaAligned extends StatelessWidget {
  const _MetaAligned({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54, // ✅ fixed label width so Created/Updated align nicely
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Modern: small circular button with subtle background + arrow_forward_ios
    return Material(
      color: Colors.grey.shade100,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ),
      ),
    );
  }
}


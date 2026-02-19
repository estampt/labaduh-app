// lib/features/vendor/orders/presentation/order_acceptance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:labaduh/features/vendor/orders/model/vendor_order_model.dart';
import 'package:labaduh/features/vendor/orders/state/vendor_orders_provider.dart';

// ✅ Adjust these imports to your project structure if needed
import '../data/vendor_orders_repository.dart';
import '../model/vendor_order_model.dart';

/// =============================================================
/// SINGLE ORDER PROVIDER (Query by Order ID)
/// =============================================================

final vendorOrderAcceptanceProvider = FutureProvider.family<
    VendorOrderModel,
    ({int vendorId, int shopId, int orderId})>((ref, p) async {
  final repo = ref.read(vendorOrderRepositoryProvider);

  final orders = await repo.getOrderBroadCast(
    vendorId: p.vendorId,
    shopId: p.shopId,
    orderId: p.orderId,
  );
  
  return orders?.isNotEmpty == true ? orders!.first : throw Exception('Order not found');
});

/// =============================================================
/// SCREEN
/// =============================================================

class OrderAcceptanceScreen extends ConsumerWidget {
  const OrderAcceptanceScreen({
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
    final asyncOrder = ref.watch(
      vendorOrderAcceptanceProvider(
        (vendorId: vendorId, shopId: shopId, orderId: orderId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(
                vendorOrderAcceptanceProvider(
                  (vendorId: vendorId, shopId: shopId, orderId: orderId),
                ),
              );
            },
          ),
        ],
      ),

      /// =========================================================
      /// BODY
      /// =========================================================

      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            vendorOrderAcceptanceProvider(
              (vendorId: vendorId, shopId: shopId, orderId: orderId),
            ),
          );

          await ref.read(
            vendorOrderAcceptanceProvider(
              (vendorId: vendorId, shopId: shopId, orderId: orderId),
            ).future,
          );
        },
        child: asyncOrder.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e'),
          ),
          data: (order) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CustomerCard(order: order),
                const SizedBox(height: 12),
                _OrderHeaderCard(order: order),
                const SizedBox(height: 12),
                _ItemsCard(order: order),
              ],
            );
          },
        ),
      ),

      /// =========================================================
      /// ACCEPT BUTTON
      /// =========================================================

      bottomNavigationBar: asyncOrder.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (order) {
          if (order.status != 'published') {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _acceptOrder(context, ref, order);
                  },
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

  /// ===========================================================
  /// ACCEPT ACTION
  /// ===========================================================

  Future<void> _acceptOrder(
    BuildContext context,
    WidgetRef ref,
    VendorOrderModel order,
  ) async {
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
          (vendorId: vendorId, shopId: shopId, orderId: orderId),
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

/// =============================================================
/// UI CARDS (SAFE GENERIC COPIES)
/// Replace with your original widgets if you prefer
/// =============================================================

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(order.customerName ?? 'Customer'),
        subtitle: Text("TO Set"?? '-'),//Text(order.customerAddress ?? '-'),
      ),
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});

  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Order #${order.id}'),
        subtitle: Text(order.statusLabel),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final VendorOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: order.items.map((e) {
          return ListTile(
            title: Text('To set'), //Text(e.serviceName),
            trailing: Text('To set'),
//Text('x${e.qty}'),
          );
        }).toList(),
      ),
    );
  }
}

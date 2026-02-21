import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/push/push_providers.dart';
import '../../../../core/auth/session_notifier.dart';
import '../domain/vendor_shop_model.dart';
import '../state/vendor_shops_providers.dart';
import 'dart:async';

class ShopSelectionPage extends ConsumerStatefulWidget {
  const ShopSelectionPage({super.key});

  @override
  ConsumerState<ShopSelectionPage> createState() => _ShopSelectionPageState();
}

class _ShopSelectionPageState extends ConsumerState<ShopSelectionPage> {
  bool _handledAuto = false;

  String _shopName(VendorShop shop) {
    final d = shop as dynamic;

    // Try common fields
    final name = d.name ?? d.shopName ?? d.title ?? d.shop_name;
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }

    // Fallback to ID
    final id = d.id;
    return id == null ? 'Shop' : 'Shop #$id';
  }

  int _shopId(VendorShop shop) {
    final d = shop as dynamic;
    final id = d.id;
    if (id is int) return id;
    return int.parse(id.toString());
  }

  void _selectAndGoHome(VendorShop shop) {
    final session = ref.read(sessionNotifierProvider) as dynamic;
    final id = _shopId(shop);
    final name = _shopName(shop);

    debugPrint('🟡 [ShopSelect] Selected shop → ID: $id | Name: $name');

    try {
      session.setActiveShop(shopId: id, shopName: name);
      debugPrint('🟢 [Session] setActiveShop() success');
    } catch (_) {
      try {
        session.setActiveShopId(id);
        session.setActiveShopName(name);
        debugPrint('🟢 [Session] setActiveShopId/Name() fallback success');
      } catch (e) {
        debugPrint('🔴 [Session] Failed saving shop: $e');
      }
    }

    // STEP #6 trigger
    debugPrint('🟡 [TokenUpdate] Trigger updateActiveShop()');

    unawaited(
      ref.read(pushTokenServiceProvider).updateActiveShop(id),
    );
  }

  

  void _logout() async {
    // If you have a real logout method somewhere else, call it.
    // At minimum clear ephemeral shop selection.
    ref.read(sessionNotifierProvider).clearEphemeral();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionNotifierProvider);

    // ✅ REQUIRED by you:
    final state = ref.watch(vendorShopsProvider);

    // If vendor already selected a shop, skip this page
    if (session.activeShopId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/v/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Shop'),
        automaticallyImplyLeading: false, // vendor must logout to switch
        actions: [
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Failed to load shops',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text('$e'),
              const Spacer(),
              FilledButton(
                onPressed: _logout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
        data: (shops) {
          // ✅ Auto-select if only 1 shop
          if (shops.length == 1 && !_handledAuto) {
            _handledAuto = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _selectAndGoHome(shops.first);
            });
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ No shops
          if (shops.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'No shops found yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You don’t have any shops linked to this vendor account yet.',
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      // ⚠️ NOTE:
                      // If your session redirect forces /v/select-shop when activeShopId == null,
                      // this "Continue" will bounce back.
                      context.go('/v/home');
                    },
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
          }

          // ✅ Multiple shops: list them
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final shop = shops[i];
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(
                  _shopName(shop),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Tap to use this shop'),
                onTap: () => _selectAndGoHome(shop),
              );
            },
          );
        },
      ),
    );
  }
}

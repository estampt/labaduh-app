import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Adjust this import if your project path differs.
// This file should provide `apiClientProvider` with an authenticated Dio.
import '../../../../core/network/api_client.dart';
import '../../../../core/ui/service_icons.dart';

/// ✅ Admin: Manage SYSTEM services + default pricing
///
/// Backed by your API:
/// - GET    /api/v1/admin/services
/// - POST   /api/v1/admin/services
/// - PUT    /api/v1/admin/services/{id}
/// - DELETE /api/v1/admin/services/{id}
/// - PATCH  /api/v1/admin/services/{id}/active
class AdminPricingScreen extends ConsumerWidget {
  const AdminPricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminServicesProvider);
    final ctrl = ref.read(adminServicesProvider.notifier);

    // Note: This screen is designed to be used inside an existing Scaffold
    // (e.g., as a tab). So we don't create a nested Scaffold here.
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Services & Default Pricing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => ctrl.refresh(),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/a/pricing/addons'),
                icon: const Icon(Icons.extension_outlined),
                label: const Text('Add-ons'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/a/pricing/service-options'),
                icon: const Icon(Icons.extension_outlined),
                label: const Text('Service Options'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openUpsertDialog(context, ref, initial: null),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(
                message: _humanError(e),
                onRetry: () => ctrl.refresh(),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(
                    onAdd: () => _openUpsertDialog(context, ref, initial: null),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ctrl.refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = items[i];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          leading: CircleAvatar(
                            child: Icon(ServiceIcons.resolve(s.iconKey), size: 20),
                          ),

                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_pricingSummary(s)),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Switch(
                                value: s.isActive,
                                onChanged: (v) => ctrl.setActive(s.id, v),
                              ),
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openUpsertDialog(context, ref, initial: s),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(context, ref, s),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _humanError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message']?.toString();
        if (msg != null && msg.trim().isNotEmpty) return msg;
        final errors = data['errors'];
        if (errors is Map) {
          for (final v in errors.values) {
            if (v is List && v.isNotEmpty) return v.first.toString();
          }
        }
      }
      return e.message ?? 'Request failed';
    }
    return e.toString();
  }

  static String _pricingSummary(AdminService s) {
    final model = s.defaultPricingModel;
    if (model == 'per_kg_min') {
      final minKg = s.defaultMinKg?.toStringAsFixed(2) ?? '-';
      final rateKg = s.defaultRatePerKg?.toStringAsFixed(2) ?? '-';
      return 'Per KG (min) • Min KG: $minKg • Rate/KG: $rateKg';
    }
    if (model == 'per_piece') {
      final ratePiece = s.defaultRatePerPiece?.toStringAsFixed(2) ?? '-';
      return 'Per Piece • Rate/Piece: $ratePiece';
    }
    return 'Pricing model: ${model ?? '-'}';
  }

  static Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AdminService s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text('Delete "${s.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await ref.read(adminServicesProvider.notifier).deleteService(s.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service deleted')),
      );
    }
  }


  static Future<void> _openUpsertDialog(
    BuildContext context,
    WidgetRef ref, {
    required AdminService? initial,
  }) async {
    final res = await showDialog<_UpsertPayload>(
      context: context,
      builder: (_) => _ServiceUpsertDialog(initial: initial),
    );
    if (res == null) return;

    final ctrl = ref.read(adminServicesProvider.notifier);
    if (initial == null) {
      await ctrl.createService(res);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service created')));
      }
    } else {
      await ctrl.updateService(initial.id, res);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service updated')));
      }
    }
  }
}

// ---------------------------
// State + API
// ---------------------------

final adminServicesProvider = AsyncNotifierProvider<AdminServicesNotifier, List<AdminService>>(
  AdminServicesNotifier.new,
);

class AdminServicesNotifier extends AsyncNotifier<List<AdminService>> {
  static const _path = '/api/v1/admin/services';

  Dio get _dio => ref.read(apiClientProvider).dio;

  @override
  Future<List<AdminService>> build() async {
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<AdminService>> _fetch() async {
    final res = await _dio.get(_path);
    final data = res.data;

    final list = (data is Map && data['data'] is List)
        ? (data['data'] as List)
        : (data is List ? data : <dynamic>[]);

    return list
        .whereType<Map>()
        .map((m) => AdminService.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<void> createService(_UpsertPayload payload) async {
    state = await AsyncValue.guard(() async {
      await _dio.post(_path, data: payload.toJson());
      return _fetch();
    });
  }

  Future<void> updateService(int id, _UpsertPayload payload) async {
    state = await AsyncValue.guard(() async {
      await _dio.put('$_path/$id', data: payload.toJson());
      return _fetch();
    });
  }

  Future<void> deleteService(int id) async {
    state = await AsyncValue.guard(() async {
      await _dio.delete('$_path/$id');
      return _fetch();
    });
  }

  Future<void> setActive(int id, bool isActive) async {
    // Optimistic UI update
    final prev = state.value ?? const <AdminService>[];
    state = AsyncData([
      for (final s in prev) if (s.id == id) s.copyWith(isActive: isActive) else s,
    ]);

    try {
      await _dio.patch('$_path/$id/active', data: {'is_active': isActive});
    } catch (e, st) {
      // Revert + surface error
      state = AsyncError(e, st);
      // Then re-fetch to restore canonical state
      await refresh();
    }
  }
}

// ---------------------------
// Models
// ---------------------------

class AdminService {
  AdminService({
    required this.id,
    required this.name,
    required this.isActive,
    required this.baseUnit,
    required this.defaultPricingModel,
    required this.allowVendorOverridePrice,
    required this.iconKey,
    this.defaultMinKg,
    this.defaultRatePerKg,
    this.defaultRatePerPiece,
  });

  final int id;
  final String name;
  final bool isActive;
  final String? baseUnit;
  final String? defaultPricingModel;
  final bool allowVendorOverridePrice;

  /// Optional icon key stored by API (e.g. "local_laundry_service").
  /// If null/empty, UI will use a sensible fallback.
  final String? iconKey;

  /// Optional icon key (Material icon name) stored by backend (recommended) or
  /// used locally for display.
  ///
  /// Backend field name suggestion: `icon` (string)

  final double? defaultMinKg;
  final double? defaultRatePerKg;
  final double? defaultRatePerPiece;

  AdminService copyWith({
    bool? isActive,
    String? iconKey,
  }) {
    return AdminService(
      id: id,
      name: name,
      isActive: isActive ?? this.isActive,
      baseUnit: baseUnit,
      defaultPricingModel: defaultPricingModel,
      allowVendorOverridePrice: allowVendorOverridePrice,
      iconKey: iconKey ?? this.iconKey,
      defaultMinKg: defaultMinKg,
      defaultRatePerKg: defaultRatePerKg,
      defaultRatePerPiece: defaultRatePerPiece,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory AdminService.fromJson(Map<String, dynamic> json) {
    return AdminService(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      baseUnit: (json['base_unit'] ?? '').toString().isEmpty ? null : (json['base_unit'] ?? '').toString(),
      isActive: json['is_active'] is bool
          ? (json['is_active'] as bool)
          : (json['is_active']?.toString() == '1' || json['is_active']?.toString() == 'true'),
      defaultPricingModel: (json['default_pricing_model'] ?? '').toString().isEmpty
          ? null
          : (json['default_pricing_model'] ?? '').toString(),
      defaultMinKg: _toDouble(json['default_min_kg']),
      defaultRatePerKg: _toDouble(json['default_rate_per_kg']),
      defaultRatePerPiece: _toDouble(json['default_rate_per_piece']),
      allowVendorOverridePrice: json['allow_vendor_override_price'] is bool
          ? (json['allow_vendor_override_price'] as bool)
          : (json['allow_vendor_override_price']?.toString() == '1' ||
              json['allow_vendor_override_price']?.toString() == 'true'),

      // Support either `icon` or `icon_key` if you choose either naming server-side.
      iconKey: (() {
        final v = json['icon'] ?? json['icon_key'];
        final s = v?.toString().trim();
        if (s == null || s.isEmpty) return null;
        return s;
      })(),
    );
  }
}

class _UpsertPayload {
  _UpsertPayload({
    required this.name,
    required this.baseUnit,
    required this.isActive,
    required this.defaultPricingModel,
    required this.allowVendorOverridePrice,
    this.iconKey,
    this.defaultMinKg,
    this.defaultRatePerKg,
    this.defaultRatePerPiece,
  });

  final String name;
  final String baseUnit; // kg | item
  final bool isActive;
  final String defaultPricingModel; // per_kg_min | per_piece
  final bool allowVendorOverridePrice;

  /// Material icon key (stored server-side). Example: "local_laundry_service".
  final String? iconKey;

  final double? defaultMinKg;
  final double? defaultRatePerKg;
  final double? defaultRatePerPiece;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'name': name,
      'base_unit': baseUnit,
      'is_active': isActive,
      'default_pricing_model': defaultPricingModel,
      'default_min_kg': defaultMinKg,
      'default_rate_per_kg': defaultRatePerKg,
      'default_rate_per_piece': defaultRatePerPiece,
      'allow_vendor_override_price': allowVendorOverridePrice,
    };

    // Only send icon if set.
    if (iconKey != null && iconKey!.trim().isNotEmpty) {
      // Server can accept either `icon` or `icon_key` depending on your naming.
      // Use `icon` as the primary.
      m['icon'] = iconKey;
    }
    return m;
  }
}

// ---------------------------
// UI: Dialog + states
// ---------------------------

class _ServiceUpsertDialog extends StatefulWidget {
  const _ServiceUpsertDialog({required this.initial});
  final AdminService? initial;

  @override
  State<_ServiceUpsertDialog> createState() => _ServiceUpsertDialogState();
}

class _ServiceUpsertDialogState extends State<_ServiceUpsertDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController minKgCtrl;
  late final TextEditingController rateKgCtrl;
  late final TextEditingController ratePieceCtrl;

  String baseUnit = 'kg';
  String pricingModel = 'per_kg_min';
  bool isActive = true;
  bool allowOverride = true;
  String? iconKey;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    nameCtrl = TextEditingController(text: s?.name ?? '');
    minKgCtrl = TextEditingController(text: s?.defaultMinKg?.toStringAsFixed(2) ?? '');
    rateKgCtrl = TextEditingController(text: s?.defaultRatePerKg?.toStringAsFixed(2) ?? '');
    ratePieceCtrl = TextEditingController(text: s?.defaultRatePerPiece?.toStringAsFixed(2) ?? '');

    baseUnit = s?.baseUnit ?? 'kg';
    pricingModel = s?.defaultPricingModel ?? (baseUnit == 'kg' ? 'per_kg_min' : 'per_piece');
    isActive = s?.isActive ?? true;
    allowOverride = s?.allowVendorOverridePrice ?? true;
    iconKey = (s?.iconKey?.trim().isNotEmpty == true) ? s!.iconKey : _ServiceIcons.defaultIconKeyForBaseUnit(baseUnit);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    minKgCtrl.dispose();
    rateKgCtrl.dispose();
    ratePieceCtrl.dispose();
    super.dispose();
  }

  double? _d(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _save() {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service name is required')));
      return;
    }

    if (pricingModel == 'per_kg_min') {
      if (_d(rateKgCtrl) == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Default rate per KG is required')));
        return;
      }
    }
    if (pricingModel == 'per_piece') {
      if (_d(ratePieceCtrl) == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Default rate per piece is required')));
        return;
      }
    }

    Navigator.pop(
      context,
      _UpsertPayload(
        name: name,
        baseUnit: baseUnit,
        isActive: isActive,
        defaultPricingModel: pricingModel,
        iconKey: iconKey,
        defaultMinKg: pricingModel == 'per_kg_min' ? _d(minKgCtrl) : null,
        defaultRatePerKg: pricingModel == 'per_kg_min' ? _d(rateKgCtrl) : null,
        defaultRatePerPiece: pricingModel == 'per_piece' ? _d(ratePieceCtrl) : null,
        allowVendorOverridePrice: allowOverride,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Service' : 'Edit Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Service name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: baseUnit,
              decoration: const InputDecoration(labelText: 'Base unit'),
              items: const [
                DropdownMenuItem(value: 'kg', child: Text('KG')),
                DropdownMenuItem(value: 'item', child: Text('Piece / Item')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  baseUnit = v;
                  pricingModel = baseUnit == 'kg' ? 'per_kg_min' : 'per_piece';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: pricingModel,
              decoration: const InputDecoration(labelText: 'Default pricing model'),
              items: [
                if (baseUnit == 'kg')
                  const DropdownMenuItem(value: 'per_kg_min', child: Text('Per KG (min)')),
                if (baseUnit != 'kg')
                  const DropdownMenuItem(value: 'per_piece', child: Text('Per Piece')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => pricingModel = v);
              },
            ),
            const SizedBox(height: 12),
            _IconPickerTile(
              iconKey: iconKey,
              onPick: (k) => setState(() => iconKey = k),
            ),
            const SizedBox(height: 12),
            if (pricingModel == 'per_kg_min') ...[
              TextField(
                controller: minKgCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Default Min KG (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rateKgCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Default Rate per KG'),
              ),
            ],
            if (pricingModel == 'per_piece') ...[
              TextField(
                controller: ratePieceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Default Rate per piece'),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              value: allowOverride,
              onChanged: (v) => setState(() => allowOverride = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Vendors can override'),
            ),
            SwitchListTile(
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

// ---------------------------
// Icon picker
// ---------------------------

class _ServiceIcons {
  static const String laundry = 'local_laundry_service';
  static const String dryClean = 'dry_cleaning';
  static const String iron = 'iron';
  static const String delivery = 'local_shipping';
  static const String express = 'bolt';
  static const String blanket = 'bed';
  static const String shirt = 'checkroom';
  static const String pants = 'hiking';
  static const String shoes = 'hiking_shoes';
  static const String basket = 'shopping_basket';
  static const String price = 'price_change';

  static String defaultIconKeyForBaseUnit(String baseUnit) {
    return baseUnit == 'kg' ? laundry : blanket;
  }

  static IconData iconForKey(String? key) {
    switch ((key ?? '').trim()) {
      case laundry:
        return Icons.local_laundry_service;
      case dryClean:
        return Icons.dry_cleaning;
      case iron:
        return Icons.iron;
      case delivery:
        return Icons.local_shipping;
      case express:
        return Icons.bolt;
      case blanket:
        return Icons.bed;
      case shirt:
        return Icons.checkroom;
      case pants:
        return Icons.hiking;
      case shoes:
        // `hiking_shoes` doesn't exist in material; fallback.
        return Icons.hiking;
      case basket:
        return Icons.shopping_basket;
      case price:
        return Icons.price_change;
      default:
        return Icons.local_laundry_service;
    }
  }

  static const List<_IconOption> options = [
    _IconOption(key: laundry, label: 'Laundry', icon: Icons.local_laundry_service),
    _IconOption(key: dryClean, label: 'Dry Clean', icon: Icons.dry_cleaning),
    _IconOption(key: iron, label: 'Iron', icon: Icons.iron),
    _IconOption(key: blanket, label: 'Blanket', icon: Icons.bed),
    _IconOption(key: shirt, label: 'Clothes', icon: Icons.checkroom),
    _IconOption(key: delivery, label: 'Delivery', icon: Icons.local_shipping),
    _IconOption(key: express, label: 'Express', icon: Icons.bolt),
    _IconOption(key: basket, label: 'Basket', icon: Icons.shopping_basket),
    _IconOption(key: price, label: 'Price', icon: Icons.price_change),
  ];
}

class _IconOption {
  const _IconOption({required this.key, required this.label, required this.icon});
  final String key;
  final String label;
  final IconData icon;
}

class _IconPickerTile extends StatelessWidget {
  const _IconPickerTile({required this.iconKey, required this.onPick});
  final String? iconKey;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final currentKey = (iconKey ?? _ServiceIcons.laundry).trim();
    final currentIcon = _ServiceIcons.iconForKey(currentKey);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (_) => _IconPickerSheet(selectedKey: currentKey),
        );
        if (picked != null && picked.trim().isNotEmpty) {
          onPick(picked.trim());
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Icon',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            CircleAvatar(child: Icon(currentIcon, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _IconPickerSheet extends StatelessWidget {
  const _IconPickerSheet({required this.selectedKey});
  final String selectedKey;

  @override
  Widget build(BuildContext context) {
    final opts = _ServiceIcons.options;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select an icon',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                ),
                itemCount: ServiceIcons.items.length,
                itemBuilder: (context, i) {
                  final o = ServiceIcons.items[i];
                  final isSel = o.key == selectedKey;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).pop(o.key),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          width: isSel ? 2 : 1,
                          color: isSel
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(o.icon, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            o.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.price_change_outlined, size: 40),
            const SizedBox(height: 10),
            const Text('No services yet.'),
            const SizedBox(height: 14),
            FilledButton(onPressed: onAdd, child: const Text('Add Service')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

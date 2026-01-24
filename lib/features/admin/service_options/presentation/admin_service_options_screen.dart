import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/service_option.dart';
import 'providers/service_options_providers.dart';
import 'admin_service_option_form_screen.dart';

class AdminServiceOptionsScreen extends ConsumerStatefulWidget {
  const AdminServiceOptionsScreen({super.key});

  @override
  ConsumerState<AdminServiceOptionsScreen> createState() => _AdminServiceOptionsScreenState();
}

class _AdminServiceOptionsScreenState extends ConsumerState<AdminServiceOptionsScreen> {
  String? _kindFilter; // 'option' | 'addon'
  bool? _activeFilter = true;

  @override
  Widget build(BuildContext context) {
    final filter = (kind: _kindFilter, active: _activeFilter);
    final asyncList = ref.watch(adminServiceOptionsListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Options'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminServiceOptionsListProvider(filter)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AdminServiceOptionFormScreen()),
          );
          if (changed == true) ref.invalidate(adminServiceOptionsListProvider(filter));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _Filters(
            kind: _kindFilter,
            active: _activeFilter,
            onChanged: (kind, active) {
              setState(() {
                _kindFilter = kind;
                _activeFilter = active;
              });
            },
          ),
          Expanded(
            child: asyncList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) return const Center(child: Text('No service options.'));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _OptionCard(
                    option: items[i],
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminServiceOptionFormScreen(existing: items[i]),
                        ),
                      );
                      if (changed == true) ref.invalidate(adminServiceOptionsListProvider(filter));
                    },
                    onToggle: () async {
                      try {
                        final api = ref.read(adminServiceOptionsApiProvider);
                        await api.toggle(items[i].id);
                        ref.invalidate(adminServiceOptionsListProvider(filter));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toggle failed: $e')));
                        }
                      }
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
}

class _Filters extends StatelessWidget {
  final String? kind;
  final bool? active;
  final void Function(String? kind, bool? active) onChanged;

  const _Filters({required this.kind, required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: kind,
              isDense: true,
              decoration: const InputDecoration(labelText: 'Kind', isDense: true),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'option', child: Text('Option')),
                DropdownMenuItem(value: 'addon', child: Text('Add-on')),
              ],
              onChanged: (v) => onChanged(v, active),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<bool?>(
              value: active,
              isDense: true,
              decoration: const InputDecoration(labelText: 'Active', isDense: true),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: true, child: Text('Active')),
                DropdownMenuItem(value: false, child: Text('Inactive')),
              ],
              onChanged: (v) => onChanged(kind, v),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final ServiceOption option;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _OptionCard({required this.option, required this.onTap, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final kindLabel = option.kind == ServiceOptionKind.addon ? 'ADD-ON' : 'OPTION';
    final pt = switch (option.priceType) {
      ServiceOptionPriceType.fixed => 'fixed',
      ServiceOptionPriceType.perKg => 'per_kg',
      ServiceOptionPriceType.perItem => 'per_item',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Expanded(child: Text(option.name, style: Theme.of(context).textTheme.titleMedium)),
                    const SizedBox(width: 8),
                    _Pill(text: 'ID ${option.id}'),
                    const SizedBox(width: 8),
                    _Pill(text: kindLabel),
                    const SizedBox(width: 8),
                    _Pill(text: option.isActive ? 'ACTIVE' : 'INACTIVE'),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Price: ${option.price} • $pt', style: Theme.of(context).textTheme.bodySmall),
                if ((option.groupKey ?? '').isNotEmpty || (option.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if ((option.groupKey ?? '').isNotEmpty) 'Group: ${option.groupKey}',
                      if ((option.description ?? '').isNotEmpty) option.description!,
                    ].join(' • '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ]),
            ),
            IconButton(
              onPressed: onToggle,
              icon: Icon(option.isActive ? Icons.toggle_on : Icons.toggle_off),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/service_icons.dart';

import '../models/discovery_service_models.dart';
import '../state/discovery_services_provider.dart';
import '../state/order_draft_controller.dart';

import 'widgets/kg_stepper.dart';
import 'widgets/section_title.dart';
import 'widgets/sticky_bottom_bar.dart';

class OrderServicesScreen extends ConsumerWidget {
  const OrderServicesScreen({super.key});

  String _unitLabelFromBaseUnit(String baseUnit) {
    final u = baseUnit.toLowerCase().trim();
    return (u == 'kg' || u == 'kilo' || u == 'kilogram') ? 'KG' : 'pc';
  }

  num _estimatePriceForRow(DiscoveryServiceRow row, num qty) {
    // same logic as DraftSelectedService.computedPrice (using MIN values)
    final minQ = row.baseQty;
    final minPrice = row.basePriceMin;
    final per = row.excessPriceMin;

    if (qty <= minQ) return minPrice;
    return minPrice + ((qty - minQ) * per);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftControllerProvider);
    final ctrl = ref.read(orderDraftControllerProvider.notifier);

    final discoveryAsync = ref.watch(discoveryServicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Services')),
      body: discoveryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading services: $e')),
        data: (rows) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  const SectionTitle('What should we wash?'),
                  const Text(
                    'You can choose multiple services. Each service has its own KG/pieces.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),

                  ...rows.map((row) {
                    final isSelected = ctrl.isSelected(row.serviceId);

                    // find selected qty + selected options from draft (if selected)
                    final selected = draft.services
                        .where((e) => e.row.serviceId == row.serviceId)
                        .toList();

                    final int qty = isSelected
                        ? selected.first.qty.toInt()
                        : row.baseQty.toInt();

                    final unit = _unitLabelFromBaseUnit(row.service.baseUnit);

                    // computedPrice now includes selected options
                    final price = isSelected
                        ? selected.first.computedPrice
                        : _estimatePriceForRow(row, qty);

                    final selectedOptionIds = isSelected
                        ? selected.first.selectedOptionIds
                        : const <int>{};

                    final hasOptions =
                        row.addons.isNotEmpty || row.optionGroups.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    ServiceIcons.resolve(row.service.icon),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          row.service.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Base: ${row.baseQty} $unit',
                                          style: const TextStyle(
                                              color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isSelected,
                                    onChanged: (_) => ctrl.toggleService(row),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₱ $price',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  KgStepper(
                                    value: qty,
                                    min: row.baseQty,
                                    suffix: unit,
                                    onChanged: (newQty) =>
                                        ctrl.setQty(row.serviceId, newQty),
                                  ),
                                ],
                              ),
                              if (row.excessPriceMin > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Excess: ₱ ${row.excessPriceMin} per extra $unit',
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                ),

                              // ✅ NEW: Options UI directly under service (keeps style simple)
                              if (hasOptions) ...[
                                const SizedBox(height: 12),
                                _ServiceOptionsBlock(
                                  row: row,
                                  enabled: isSelected,
                                  selectedOptionIds: selectedOptionIds,
                                  onToggleAddon: (opt) => ctrl.toggleAddonOption(
                                    serviceId: row.serviceId,
                                    option: opt,
                                  ),
                                  onToggleGrouped: (group, opt) =>
                                      ctrl.toggleGroupedOption(
                                    serviceId: row.serviceId,
                                    group: group,
                                    option: opt,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: StickyBottomBar(
                  title: '${draft.services.length} service(s) selected',
                  subtitle: draft.services.isEmpty
                      ? 'Select at least 1 service'
                      : 'Estimated: ₱ ${draft.subtotal}',
                  buttonText: 'Continue',
                  enabled: draft.services.isNotEmpty,
                  onPressed: () => context.push('/c/order/schedule'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceOptionsBlock extends StatelessWidget {
  const _ServiceOptionsBlock({
    required this.row,
    required this.enabled,
    required this.selectedOptionIds,
    required this.onToggleAddon,
    required this.onToggleGrouped,
  });

  final DiscoveryServiceRow row;
  final bool enabled;
  final Set<int> selectedOptionIds;

  final void Function(ServiceOptionItem opt) onToggleAddon;
  final void Function(DiscoveryOptionGroup group, ServiceOptionItem opt)
      onToggleGrouped;

  String _priceLabel(ServiceOptionItem o) {
    final p = o.priceMin;
    return p == 0 ? '' : ' • ₱ $p';
  }

  @override
  Widget build(BuildContext context) {
    final disabledColor = Colors.black38;

    Widget title(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            t,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: enabled ? Colors.black87 : disabledColor,
            ),
          ),
        );

    List<ServiceOptionItem> sorted(List<ServiceOptionItem> xs) {
      final copy = [...xs];
      copy.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return copy;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (row.addons.isNotEmpty) ...[
          title('Add-ons'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sorted(row.addons).map((opt) {
              final isOn = selectedOptionIds.contains(opt.id);
              return FilterChip(
                label: Text('${opt.name}${_priceLabel(opt)}'),
                selected: isOn,
                onSelected: enabled ? (_) => onToggleAddon(opt) : null,
              );
            }).toList(),
          ),
        ],
        if (row.optionGroups.isNotEmpty) ...[
          if (row.addons.isNotEmpty) const SizedBox(height: 12),
          ...row.optionGroups.map((g) {
            final header = '${g.groupKey ?? 'Options'}'
                '${g.isRequired ? ' (required)' : ''}'
                '${g.isMultiSelect ? ' (multi)' : ''}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title(header),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sorted(g.items).map((opt) {
                      final isOn = selectedOptionIds.contains(opt.id);
                      return FilterChip(
                        label: Text('${opt.name}${_priceLabel(opt)}'),
                        selected: isOn,
                        onSelected: enabled ? (_) => onToggleGrouped(g, opt) : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

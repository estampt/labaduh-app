import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
//import '../../pricing/presentation/service_options/admin_service_options_screen.dart';


final adminServicesProvider = FutureProvider.autoDispose<List<AdminServiceRow>>((ref) async {
  final dio = ref.read(apiClientProvider).dio as Dio; // <-- adjust if needed

  final res = await dio.get('/api/v1/admin/services', queryParameters: {'per_page': 100});
  final body = res.data;

  // support both {data:{data:[...]}} or {data:[...]}
  List list;
  if (body is Map && body['data'] is Map && (body['data']['data'] is List)) {
    list = body['data']['data'] as List;
  } else if (body is Map && body['data'] is List) {
    list = body['data'] as List;
  } else if (body is List) {
    list = body;
  } else {
    throw Exception('Unexpected services response');
  }

  return list
      .whereType<Map>()
      .map((m) => AdminServiceRow.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

class AdminServiceRow {
  AdminServiceRow({
    required this.id,
    required this.name,
    required this.baseUnit,
    required this.isActive,
    this.icon,
  });

  final String id;
  final String name;
  final String baseUnit; // kg | item
  final bool isActive;
  final String? icon;

  factory AdminServiceRow.fromJson(Map<String, dynamic> json) {
    return AdminServiceRow(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      baseUnit: (json['base_unit'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active']?.toString() == '1',
      icon: json['icon']?.toString(),
    );
  }
}

class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  ConsumerState<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends ConsumerState<AdminServicesScreen> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminServicesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search services',
            ),
            onChanged: (v) => setState(() => q = v.trim()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load services\n$e', textAlign: TextAlign.center)),
              data: (rows) {
                final filtered = rows.where((s) {
                  if (q.isEmpty) return true;
                  final n = q.toLowerCase();
                  return s.name.toLowerCase().contains(n) || s.baseUnit.toLowerCase().contains(n);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No services found', style: TextStyle(color: Colors.black54)));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.local_laundry_service)),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text('Unit: ${s.baseUnit} • ${s.isActive ? 'Active' : 'Inactive'}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push(
                            '/a/services/${s.id}',
                            extra: s.name, // optional
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

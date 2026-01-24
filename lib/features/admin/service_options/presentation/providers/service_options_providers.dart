import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/service_options_api.dart';
import '../../domain/service_option.dart';
import '../../../../../core/network/dio_provider.dart'; // your existing dio provider

final adminServiceOptionsApiProvider = Provider<AdminServiceOptionsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminServiceOptionsApi(dio);
});

typedef AdminServiceOptionsFilter = ({String? kind, bool? active});

final adminServiceOptionsListProvider =
    FutureProvider.autoDispose.family<List<ServiceOption>, AdminServiceOptionsFilter>((ref, filter) async {
  final api = ref.watch(adminServiceOptionsApiProvider);
  return api.list(kind: filter.kind, active: filter.active);
});

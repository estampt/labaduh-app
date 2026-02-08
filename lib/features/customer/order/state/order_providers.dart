import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/customer_orders_api.dart';

final customerOrdersApiProvider = Provider<CustomerOrdersApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerOrdersApi(apiClient.dio);
});

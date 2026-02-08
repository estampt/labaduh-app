import 'package:dio/dio.dart';

import '../models/discovery_service_models.dart';
import '../models/order_models.dart';
import '../models/order_payloads.dart';

class CustomerOrdersApi {
  final Dio dio;
  CustomerOrdersApi(this.dio);

  Future<List<DiscoveryServiceRow>> discoveryServices({
    required double lat,
    required double lng,
    required int radiusKm,
  }) async {
    final res = await dio.get(
      '/api/v1/customer/discovery/services',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius_km': radiusKm,
      },
    );

    final data = (res.data as Map?)?['data'] as List?;
    return (data ?? [])
        .map((e) => DiscoveryServiceRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Order> createOrder(CreateOrderPayload payload) async {
    final res = await dio.post('/api/v1/customer/orders', data: payload.toJson());
    final data = (res.data as Map?)?['data'];
    if (data == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        error: 'Invalid response: missing data',
      );
    }
    return Order.fromJson(Map<String, dynamic>.from(data));
  }
}

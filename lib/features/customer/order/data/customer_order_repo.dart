import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/dtos/customer_order_show_dto.dart';

final customerOrderRepoProvider =
    Provider<CustomerOrderRepo>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return CustomerOrderRepo(dio);
});

class CustomerOrderRepo {
  CustomerOrderRepo(this._dio);
  final Dio _dio;

  String _p(String path) {
    final base = _dio.options.baseUrl.toLowerCase();
    if (base.contains('/api/v1')) return path;
    return '/api/v1$path';
  }

  /// -----------------------------
  /// GET ORDER (used by tracking + matching)
  /// -----------------------------
  Future<CustomerOrderShowDto> getOrder(int orderId) async {
    final res =
        await _dio.get(_p('/customer/orders/$orderId'));

    final data =
        (res.data['data'] as Map).cast<String, dynamic>();

    return CustomerOrderShowDto.fromJson(data);
  }

  /// -----------------------------
  /// QUOTE
  /// -----------------------------
  Future<Map<String, dynamic>> createQuote(
      Map<String, dynamic> payload) async {
    final res =
        await _dio.post(_p('/customer/quotes'), data: payload);

    return (res.data['data'] as Map)
        .cast<String, dynamic>();
  }

  /// -----------------------------
  /// CREATE ORDER
  /// -----------------------------
  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> payload) async {
    final res =
        await _dio.post(_p('/customer/orders'), data: payload);

    return (res.data['data'] as Map)
        .cast<String, dynamic>();
  }

  /// -----------------------------
  /// APPROVE FINAL PRICE
  /// -----------------------------
  Future<void> approveFinal(int orderId) async {
    await _dio.post(
      _p('/customer/orders/$orderId/approve-final'),
    );
  }

  /// -----------------------------
  /// REJECT FINAL PRICE
  /// -----------------------------
  Future<void> rejectFinal(int orderId) async {
    await _dio.post(
      _p('/customer/orders/$orderId/reject-final'),
    );
  }

}

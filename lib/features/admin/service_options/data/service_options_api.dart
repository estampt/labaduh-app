import 'package:dio/dio.dart';
import '../domain/service_option.dart';

class AdminServiceOptionsApi {
  final Dio dio;
  AdminServiceOptionsApi(this.dio);

  // ✅ choose ONE depending on Env.baseUrl:
  // If Env.baseUrl ends with /api/v1 -> use this:
  static const _base = '/admin/service-options';
  // If Env.baseUrl is only host -> use this instead:
  // static const _base = '/api/v1/admin/service-options';

  Future<List<ServiceOption>> list({String? kind, bool? active}) async {
    final res = await dio.get(
      _base,
      queryParameters: {
        if (kind != null) 'kind': kind,
        if (active != null) 'active': active,
      },
    );

    // Your response: { "data": { "data": [ ... ] } }
    final pageObj = res.data['data'] as Map<String, dynamic>;
    final items = (pageObj['data'] as List).cast<Map<String, dynamic>>();

    return items.map(ServiceOption.fromJson).toList();
  }

  Future<ServiceOption> create(ServiceOption option) async {
    final res = await dio.post(_base, data: option.toPayload());
    return ServiceOption.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ServiceOption> update(int id, Map<String, dynamic> payload) async {
    final res = await dio.put('$_base/$id', data: payload);
    return ServiceOption.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await dio.delete('$_base/$id');
  }

  Future<ServiceOption> toggle(int id) async {
    final res = await dio.patch('$_base/$id/toggle');
    return ServiceOption.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

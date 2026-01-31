import '../../../../core/network/api_client.dart';
import 'shop_service_options_dtos.dart';

class MasterServiceOptionsRepository {
  MasterServiceOptionsRepository(this._api);
  final ApiClient _api;

  /// Reads ALL pages (because your admin endpoint is paginated)
  Future<List<ServiceOptionDto>> listAll({int perPage = 50}) async {
       final out = <ServiceOptionDto>[];

    final res = await _api.dio.get('/api/v1/service-options');

    final data = res.data['data'];

    // if your response is: { data: { data: [...] } }
    final list = (data['data'] as List).cast<Map<String, dynamic>>();

    out
      ..clear()
      ..addAll(list.map(ServiceOptionDto.fromJson));


    // sort stable
    out.sort((a, b) {
      final so = a.sortOrder.compareTo(b.sortOrder);
      if (so != 0) return so;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return out.where((x) => x.isActive).toList();
  }
}

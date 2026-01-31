import '../../../../core/network/api_client.dart';
import 'shop_services_dtos.dart';

class MasterServicesRepository {
  MasterServicesRepository(this._api);
  final ApiClient _api;

  Future<List<ServiceDto>> listServices() async {
    final res = await _api.dio.get('/api/v1/services');
    final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
    final rows = list.map(ServiceDto.fromJson).toList();
    rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return rows;
  }
}

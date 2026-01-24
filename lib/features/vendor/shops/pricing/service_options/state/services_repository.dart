class ServicesRepository {
  ServicesRepository(this.api);
  final dynamic api;
  dynamic get _dio => api.dio;

  // ✅ Change this endpoint to your real one
  // Common: GET /api/v1/services
  Future<List<Map<String, dynamic>>> listServices() async {
    final res = await _dio.get('/api/v1/services');
    final body = res.data;

    // supports: {data:[...]} or raw [...]
    final items = body is List ? body : (body['data'] as List);
    return items.cast<Map<String, dynamic>>();
  }
}

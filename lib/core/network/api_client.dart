import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {Object? body}) {
    return _dio.post<T>(path, data: body);
  }

  Future<Response<T>> put<T>(String path, {Object? body}) {
    return _dio.put<T>(path, data: body);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}

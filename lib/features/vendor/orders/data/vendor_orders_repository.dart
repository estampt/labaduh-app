// vendor_order_repository.dart
//
// Repository for vendor orders (clean separation from UI).
// Uses ApiClient (Dio) and provides:
// - getActiveOrders(vendorId, shopId)
// - fetchShopOrders(vendorId, shopId, cursor)
// - postStatusAction(...) for normal status movements (JSON only)
// - postWeightReview(...) dedicated endpoint for weight updates (supports multipart + files)
//
// Endpoints (as used here):
// GET  /api/v1/vendors/{vendorId}/shops/{shopId}/orders
// POST /api/v1/vendors/{vendorId}/shops/{shopId}/orders/{orderId}/{actionSlug}
// POST /api/v1/vendors/{vendorId}/shops/{shopId}/orders/{orderId}/weight-review

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../model/vendor_order_model.dart';

class VendorOrderRepository {
  VendorOrderRepository(this._api);

  final vendorOrderSubmitLoadingProvider = StateProvider<bool>((ref) => false);

  final ApiClient _api;

  Future<List<VendorOrderModel>?> getActiveOrders({
    required int vendorId,
    required int shopId,
  }) async {
    final page = await fetchShopOrders(
      vendorId: vendorId,
      shopId: shopId,
      cursor: null,
    );
    return page.orders;
  }

  Future<VendorOrdersPage> fetchShopOrders({
    required int vendorId,
    required int shopId,
    String? cursor,
  }) async {
    try {
      final res = await _api.dio.get(
        '/api/v1/vendors/$vendorId/shops/$shopId/orders',
        queryParameters: cursor == null ? null : {'cursor': cursor},
      );

      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw StateError('Unexpected response shape: ${data.runtimeType}');
      }

      return VendorOrdersPage.fromJson(data);
    } on DioException catch (e) {
      throw VendorOrderRepositoryException(_dioMessage(e));
    } catch (e) {
      throw VendorOrderRepositoryException(e.toString());
    }
  }

  /// Generic action endpoint (status movement):
  /// POST /api/v1/vendors/{vendorId}/shops/{shopId}/orders/{orderId}/{actionSlug}
  ///
  /// IMPORTANT: This method is JSON-only.
  /// If you need to upload images / weight details, use [postWeightReview] instead.
  Future<VendorOrderModel?> postStatusAction({
    required final vendorId,
    required final shopId,
    required int orderId,
    required String actionSlug,
    Map<String, dynamic>? body,
  }) async {
    try {
      // 🔒 Guard: if payload contains files, force devs to use the dedicated endpoint.
      // This prevents weight submissions from being accidentally executed alongside
      // normal status movements.
      if (_hasFile(body)) {
        throw VendorOrderRepositoryException(
          'Payload contains file(s). Use postWeightReview(...) instead of postStatusAction(...).',
        );
      }

      final res = await _api.dio.post(
        '/api/v1/vendors/$vendorId/shops/$shopId/orders/$orderId/$actionSlug',
        data: body,
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final maybe = data['data'];
        if (maybe is Map<String, dynamic>) {
          return VendorOrderModel.fromJson(maybe);
        }
      }
      return null;
    } on DioException catch (e) {
      throw VendorOrderRepositoryException(_dioMessage(e));
    } catch (e) {
      throw VendorOrderRepositoryException(e.toString());
    }
  }

  /// Weight review endpoint (separate from status actions)
  /// POST /api/v1/vendors/{vendorId}/shops/{shopId}/orders/{orderId}/weight-review
  ///
  /// Use this for sending:
  /// - order_item_id
  /// - item_qty
  /// - uploaded
  /// - notes
  /// - image (File)
  /// - images (List<File>)
  ///
  /// Body example:
  /// {
  ///   "weight_kg": 12.5,
  ///   "notes": "optional",
  ///   "items": [
  ///     {"order_item_id": 344, "item_qty": 3, "uploaded": 0, "notes": "bedsheets"}
  ///   ],
  ///   "image": File(...),
  ///   "images": [File(...), ...]
  /// }
  Future<VendorOrderModel?> postWeightReview({
    required final vendorId,
    required final shopId,
    required int orderId,
    Map<String, dynamic>? body,
    String slug = 'weight-review',
  }) async {
    try {
      final url = '/api/v1/vendors/$vendorId/shops/$shopId/orders/$orderId/$slug';
      final payload = await _prepareRequestBody(body);

      final res = await _api.dio.post(url, data: payload);

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final maybe = data['data'];
        if (maybe is Map<String, dynamic>) {
          return VendorOrderModel.fromJson(maybe);
        }
      }
      return null;
    } on DioException catch (e) {
      throw VendorOrderRepositoryException(_dioMessage(e));
    } catch (e) {
      throw VendorOrderRepositoryException(e.toString());
    }
  }

  /// Converts body to FormData automatically if it contains File(s).
  /// Otherwise sends JSON as-is.
  Future<dynamic> _prepareRequestBody(Map<String, dynamic>? body) async {
    if (body == null || body.isEmpty) return body;

    final containsFiles = _hasFile(body);
    if (!containsFiles) return body;

    final form = FormData();

    for (final entry in body.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;

      // Single file: image
      if (value is File) {
        form.files.add(
          MapEntry(
            key,
            await MultipartFile.fromFile(
              value.path,
              filename: value.uri.pathSegments.isNotEmpty
                  ? value.uri.pathSegments.last
                  : 'upload.jpg',
            ),
          ),
        );
        continue;
      }

      // Multiple files: images
      if (value is List<File>) {
        for (final f in value) {
          form.files.add(
            MapEntry(
              '$key[]',
              await MultipartFile.fromFile(
                f.path,
                filename:
                    f.uri.pathSegments.isNotEmpty ? f.uri.pathSegments.last : 'upload.jpg',
              ),
            ),
          );
        }
        continue;
      }

      // Lists
      if (value is List) {
        // List of maps -> key[0][field]
        if (value.isNotEmpty && value.first is Map) {
          for (int i = 0; i < value.length; i++) {
            final item = value[i];
            if (item is Map) {
              for (final e in item.entries) {
                final k = e.key.toString();
                final v = e.value;
                if (v == null) continue;
                form.fields.add(MapEntry('$key[$i][$k]', v.toString()));
              }
            }
          }
        } else {
          // Simple list -> key[]
          for (final v in value) {
            if (v == null) continue;
            form.fields.add(MapEntry('$key[]', v.toString()));
          }
        }
        continue;
      }

      // Map -> key[sub]
      if (value is Map) {
        for (final e in value.entries) {
          final k = e.key.toString();
          final v = e.value;
          if (v == null) continue;
          form.fields.add(MapEntry('$key[$k]', v.toString()));
        }
        continue;
      }

      // Scalar
      form.fields.add(MapEntry(key, value.toString()));
    }

    return form;
  }

  /// Detect File anywhere (including nested lists/maps)
  static bool _hasFile(dynamic value) {
    if (value == null) return false;
    if (value is File) return true;
    if (value is List) return value.any(_hasFile);
    if (value is Map) return value.values.any(_hasFile);
    return false;
  }
}

// ----------------------------
// Repository Exception
// ----------------------------

class VendorOrderRepositoryException implements Exception {
  VendorOrderRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ----------------------------
// Dio-friendly error message
// ----------------------------

String _dioMessage(DioException e) {
  final status = e.response?.statusCode;
  final data = e.response?.data;

  if (data is Map && data['message'] is String) {
    return 'HTTP $status: ${data['message']}';
  }
  if (status != null) {
    return 'HTTP $status: ${e.message ?? 'Request failed'}';
  }
  return e.message ?? 'Network error';
}

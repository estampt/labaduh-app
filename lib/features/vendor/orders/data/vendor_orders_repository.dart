// vendor_order_repository.dart
//
// Repository for vendor orders (clean separation from UI).
// Uses ApiClient (Dio) and provides:
// - getActiveOrders(vendorId, shopId)
// - fetchShopOrders(vendorId, shopId, cursor)
// - placeholders for ALL your POST status actions
//
// Endpoints (as you listed):
// GET  /api/v1/vendors/{vendorId}/shops/{shopId}/orders
// POST /api/v1/orders/{order}/{actionSlug}
// POST /api/v1/orders/{order}/propose-final

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../model/vendor_order_model.dart';

class VendorOrderRepository {
  VendorOrderRepository(this._api);

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

  /// Generic action endpoint:
  /// POST /api/v1/orders/{orderId}/{actionSlug}
  Future<VendorOrderModel?> postStatusAction({
    required int orderId,
    required String actionSlug,
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _api.dio.post(
        '/api/v1/orders/$orderId/$actionSlug',
        data: body,
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final maybe = data['data'];
        if (maybe is Map<String, dynamic>) {
          return VendorOrderModel.fromJson(maybe);
        }
      }
      // If backend returns no order object, just return null.
      return null;
    } on DioException catch (e) {
      throw VendorOrderRepositoryException(_dioMessage(e));
    } catch (e) {
      throw VendorOrderRepositoryException(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ API placeholders for your routes (action slugs match Laravel routes)
  // ---------------------------------------------------------------------------

  Future<VendorOrderModel?> pickupScheduled({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'pickup-scheduled');

  Future<VendorOrderModel?> pickedUp({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'picked-up');

  Future<VendorOrderModel?> weightReviewed({
    required int orderId,
    Map<String, dynamic>? payload, // e.g. { "actual_weight": 7.5, ... }
  }) =>
      postStatusAction(orderId: orderId, actionSlug: 'weight-reviewed', body: payload);

  Future<VendorOrderModel?> weightAccepted({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'weight-accepted');

  Future<VendorOrderModel?> startWashing({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'start-washing');

  Future<VendorOrderModel?> ready({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'ready');

  Future<VendorOrderModel?> deliveryScheduled({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'delivery-scheduled');

  Future<VendorOrderModel?> outForDelivery({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'out-for-delivery');

  Future<VendorOrderModel?> delivered({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'delivered');

  Future<VendorOrderModel?> completed({required int orderId}) =>
      postStatusAction(orderId: orderId, actionSlug: 'completed');

  /// Repricing proposal
  /// POST /api/v1/orders/{order}/propose-final
  Future<VendorOrderModel?> proposeFinal({
    required int orderId,
    required Map<String, dynamic> payload, // placeholder
  }) =>
      postStatusAction(orderId: orderId, actionSlug: 'propose-final', body: payload);
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

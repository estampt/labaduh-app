import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'push_token_api.dart';
import 'push_token_service.dart';
import 'push_notification_service.dart';
import '../router/app_router.dart';

final pushTokenApiProvider = Provider<PushTokenApi>((ref) {
  final client = ref.read(apiClientProvider);
  return PushTokenApi(client);
});

final pushTokenServiceProvider = Provider<PushTokenService>((ref) {
  final api = ref.read(pushTokenApiProvider);
  return PushTokenService(api);
});

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final router = ref.read(appRouterProvider);
  return PushNotificationService(router);
});


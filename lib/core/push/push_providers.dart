import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import 'push_token_api.dart';
import 'push_token_service.dart';

final pushTokenApiProvider = Provider<PushTokenApi>((ref) {
  final client = ref.read(apiClientProvider);
  return PushTokenApi(client);
});

final pushTokenServiceProvider = Provider<PushTokenService>((ref) {
  final api = ref.read(pushTokenApiProvider);
  return PushTokenService(api);
});

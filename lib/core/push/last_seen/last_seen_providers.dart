import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/api_client.dart';
import 'last_seen_service.dart';

final lastSeenServiceProvider = Provider<LastSeenService>((ref) {
  final client = ref.read(apiClientProvider);
  return LastSeenService(client);
});

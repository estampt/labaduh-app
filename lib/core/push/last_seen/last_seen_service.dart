import 'dart:async';
import '../../network/api_client.dart';

class LastSeenService {
  LastSeenService(this._client);

  final ApiClient _client;
  Timer? _timer;

  void start() {
    _timer?.cancel();

    // every 2 minutes (adjust if you want)
    _timer = Timer.periodic(const Duration(minutes: 2), (_) async {
      try {
        // TODO: change this to your real endpoint
        await _client.dio.post('/api/v1/me/last-seen');
      } catch (_) {
        // ignore; next tick retries
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

enum EnvMode { dev, prod }

class Env {
  static late EnvMode mode;

  static void init(EnvMode m) {
    mode = m;
  }

  static String get baseUrl {
    // ✅ Android emulator uses 10.0.2.2 to reach host localhost
    // ✅ Other platforms use 127.0.0.1
    final isAndroidEmulator = defaultTargetPlatform == TargetPlatform.android;
    //final host = isAndroidEmulator ? '10.0.2.2' : '127.0.0.1';
    final host =  '10.0.2.2';

    return switch (mode) {
      EnvMode.dev => 'http://$host:8000/api/v1',
      EnvMode.prod => 'http://sandbox.estamp.co/api/v1',
    };
  }
}

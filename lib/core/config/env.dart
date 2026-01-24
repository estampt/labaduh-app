enum EnvMode { dev, prod }

class Env {
  static late EnvMode mode;

  static void init(EnvMode m) {
    mode = m;
  }

  static String get baseUrl {
    // TODO: replace with your Laravel API base URL
    // Example: https://api.labaduh.com/api/v1
    return switch (mode) {
      EnvMode.dev => 'http://127.0.0.1:8000/api/v1',
      EnvMode.prod => 'http://127.0.0.1:8000/api/v1',
    };
  }
}

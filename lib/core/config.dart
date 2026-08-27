import 'package:shared_preferences/shared_preferences.dart';

/// App-wide configuration. The API base URL is stored in shared_preferences so
/// the user can point the app at their PC's backend (LAN IP:5151) from the
/// Server Settings screen. Defaults to the Android emulator loopback (10.0.2.2)
/// which maps to the host machine's localhost.
class AppConfig {
  static const String _baseUrlKey = 'api_base_url';
  static const String defaultBaseUrl = 'http://192.168.8.122:5151/api';

  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  /// Full URL for the given path (path should start with '/').
  static String url(String path) => '$_baseUrl$path';

  /// Public base (http://host:5151) used to build absolute asset URLs such as
  /// profile pictures served from wwwroot/Profiles/...
  static String get publicBase {
    final base = _baseUrl;
    if (base.endsWith('/api')) return base.substring(0, base.length - 4);
    return base;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_baseUrlKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _baseUrl = _normalize(saved);
    }
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = _normalize(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  static Future<void> reset() async {
    _baseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
  }

  static String _normalize(String url) {
    var trimmed = url.trim();
    // Trim trailing slashes then re-append /api if the user typed a bare host.
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    if (trimmed.endsWith('/api')) return trimmed;
    return '$trimmed/api';
  }
}

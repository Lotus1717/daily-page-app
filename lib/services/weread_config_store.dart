import 'package:shared_preferences/shared_preferences.dart';

/// 微信读书 Cookie 本地存储
class WeReadConfigStore {
  WeReadConfigStore._();

  static const _cookieKey = 'weread_cookie';

  static Future<String?> getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  static Future<void> saveCookie(String cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookie.trim());
  }

  static Future<void> clearCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }

  static Future<bool> hasCookie() async {
    final cookie = await getCookie();
    return cookie != null && cookie.isNotEmpty;
  }
}

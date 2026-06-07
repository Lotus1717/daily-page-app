import 'package:shared_preferences/shared_preferences.dart';

/// Cookie 校验结果
class WeReadCookieValidation {
  const WeReadCookieValidation.valid(this.normalized, this.savedKeys)
      : error = null,
        isValid = true;

  const WeReadCookieValidation.invalid(this.error)
      : normalized = null,
        savedKeys = const [],
        isValid = false;

  final bool isValid;
  final String? normalized;
  final List<String> savedKeys;
  final String? error;
}

/// 微信读书 Cookie 本地存储
class WeReadConfigStore {
  WeReadConfigStore._();

  static const _cookieKey = 'weread_cookie';

  /// 优先展示的 key 顺序（其余 key 按字母序追加）
  static const _preferredKeyOrder = ['wr_vid', 'wr_skey', 'wr_rt'];

  /// 解析 Cookie 字符串为 key-value（与服务端 parse_cookie_string 规则对齐）
  static Map<String, String> parseCookiePairs(String cookie) {
    var raw = cookie.trim();
    if (raw.isEmpty) return {};
    if (raw.toLowerCase().startsWith('cookie:')) {
      raw = raw.substring(7).trim();
    }
    raw = raw.replaceAll(RegExp(r'[\r\n\t]+'), '; ');
    raw = raw.replaceAll(RegExp(r';\s*;'), '; ').trim();

    final cookies = <String, String>{};
    for (final part in raw.split(RegExp(r'[;\s]+'))) {
      final segment = part.trim();
      if (segment.isEmpty || !segment.contains('=')) continue;
      final eq = segment.indexOf('=');
      final key = segment.substring(0, eq).trim();
      final value = segment
          .substring(eq + 1)
          .trim()
          .replaceAll(RegExp(r'''^["']|["']$'''), '');
      if (key.isNotEmpty) cookies[key] = value;
    }
    return cookies;
  }

  /// 规范化：保留用户粘贴的全部字段，仅整理分隔符与前缀
  static String buildNormalized(Map<String, String> cookies) {
    final ordered = <String>[];
    for (final key in _preferredKeyOrder) {
      if (cookies.containsKey(key)) ordered.add(key);
    }
    final rest = cookies.keys
        .where((k) => !_preferredKeyOrder.contains(k))
        .toList()
      ..sort();
    ordered.addAll(rest);
    return ordered.map((k) => '$k=${cookies[k]}').join('; ');
  }

  /// 解析并校验 Cookie，与服务端 parse_cookie_string 规则对齐
  static WeReadCookieValidation validate(String cookie) {
    final cookies = parseCookiePairs(cookie);
    if (cookies.isEmpty) {
      return const WeReadCookieValidation.invalid('Cookie 不能为空');
    }

    if (!cookies.containsKey('wr_vid') || cookies['wr_vid']!.isEmpty) {
      return const WeReadCookieValidation.invalid(
        '缺少 wr_vid。请从 weread.qq.com 复制完整 Cookie，'
        '格式：wr_vid=数字; wr_skey=字符串',
      );
    }
    if (!cookies.containsKey('wr_skey') || cookies['wr_skey']!.isEmpty) {
      return const WeReadCookieValidation.invalid(
        '缺少 wr_skey。请同时复制 wr_vid 和 wr_skey，用英文分号连接',
      );
    }

    final normalized = buildNormalized(cookies);
    final savedKeys = <String>[];
    for (final key in _preferredKeyOrder) {
      if (cookies.containsKey(key)) savedKeys.add(key);
    }
    final rest = cookies.keys
        .where((k) => !_preferredKeyOrder.contains(k))
        .toList()
      ..sort();
    savedKeys.addAll(rest);
    return WeReadCookieValidation.valid(normalized, savedKeys);
  }

  /// 从已保存的规范化 Cookie 中提取 key 列表（不暴露值）
  static List<String> keysFromSaved(String? cookie) {
    if (cookie == null || cookie.isEmpty) return [];
    final validation = validate(cookie);
    if (validation.isValid) {
      return List<String>.from(validation.savedKeys);
    }
    return parseCookiePairs(cookie).keys.toList();
  }

  static Future<String?> getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  static Future<void> saveCookie(String cookie) async {
    final validation = validate(cookie);
    final toSave = validation.isValid ? validation.normalized! : cookie.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, toSave);
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

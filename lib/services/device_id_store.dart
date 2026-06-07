import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// 设备 ID 持久化，服务端配额按 device_id 计数
class DeviceIdStore {
  DeviceIdStore._();

  static const _key = 'daily_page_device_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.length >= 8) return existing;

    final id = _generate();
    await prefs.setString(_key, id);
    return id;
  }

  static String _generate() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'daily-$ts-$rand';
  }
}

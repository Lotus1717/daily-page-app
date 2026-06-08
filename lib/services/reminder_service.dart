import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'page_entry_service.dart';

/// 每日看书本地提醒
class ReminderService extends ChangeNotifier {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _enabledKey = 'reminder_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _notificationId = 0;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _enabled = false;
  int _hour = 21;
  int _minute = 0;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  String get timeLabel =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
    } catch (e) {
      debugPrint('ReminderService plugin init skipped: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _hour = prefs.getInt(_hourKey) ?? 21;
    _minute = prefs.getInt(_minuteKey) ?? 0;
    _initialized = true;
    notifyListeners();
  }

  Future<bool> setEnabled(bool value, PageEntryService entries) async {
    if (kIsWeb) return false;

    if (value) {
      final granted = await _requestPermission();
      if (!granted) return false;
    }

    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    await syncSchedule(entries);
    notifyListeners();
    return true;
  }

  Future<void> setTime(int hour, int minute, PageEntryService entries) async {
    _hour = hour;
    _minute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
    if (_enabled) {
      await syncSchedule(entries);
    }
    notifyListeners();
  }

  Future<void> syncSchedule(PageEntryService entries) async {
    if (kIsWeb || !_initialized) return;

    try {
      await _plugin.cancel(_notificationId);
    } catch (e) {
      debugPrint('ReminderService cancel skipped: $e');
      return;
    }

    if (!_enabled) return;

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (entries.hasWrittenToday(todayKey)) {
      await _scheduleFor(_nextDayAt(DateTime.now()));
      return;
    }

    final now = DateTime.now();
    final todayAt = DateTime(now.year, now.month, now.day, _hour, _minute);
    if (todayAt.isAfter(now)) {
      await _scheduleFor(todayAt);
    } else {
      await _scheduleFor(_nextDayAt(now));
    }
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios == null) return true;
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      return await android.requestNotificationsPermission() ?? true;
    }
    return true;
  }

  Future<void> _scheduleFor(DateTime when) async {
    try {
      final scheduled = tz.TZDateTime.from(when, tz.local);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reading',
          '每日阅读提醒',
          channelDescription: '提醒你在固定时间读一页、写一句感想',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.zonedSchedule(
        _notificationId,
        '拾页',
        '今天还没拾页，读一页写一句吧 📖',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('ReminderService schedule skipped: $e');
    }
  }

  DateTime _nextDayAt(DateTime from) {
    final next = from.add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day, _hour, _minute);
  }
}

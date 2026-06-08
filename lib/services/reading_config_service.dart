import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 阅读偏好：今日指定书目（可选）
class ReadingConfigService extends ChangeNotifier {
  static const _todayBookIdKey = 'manual_today_book_id';

  String? _todayBookId;

  String? get todayBookId => _todayBookId;

  static const maxReadingBooks = 3;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _todayBookId = prefs.getString(_todayBookIdKey);
    notifyListeners();
  }

  Future<void> setTodayBookId(String? bookId) async {
    if (_todayBookId == bookId) return;
    _todayBookId = bookId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (bookId == null) {
      await prefs.remove(_todayBookIdKey);
    } else {
      await prefs.setString(_todayBookIdKey, bookId);
    }
  }
}

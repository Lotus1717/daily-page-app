import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_pick_strategy.dart';

/// 阅读偏好：选书策略、手动指定今日书目
class ReadingConfigService extends ChangeNotifier {
  static const _strategyKey = 'book_pick_strategy';
  static const _manualBookIdKey = 'manual_today_book_id';
  static const _roundRobinIndexKey = 'round_robin_index';

  BookPickStrategy _strategy = BookPickStrategy.roundRobin;
  String? _manualBookId;
  int _roundRobinIndex = 0;

  BookPickStrategy get strategy => _strategy;
  String? get manualBookId => _manualBookId;
  int get roundRobinIndex => _roundRobinIndex;

  static const maxReadingBooks = 3;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _strategy = BookPickStrategy.fromName(prefs.getString(_strategyKey));
    _manualBookId = prefs.getString(_manualBookIdKey);
    _roundRobinIndex = prefs.getInt(_roundRobinIndexKey) ?? 0;
    notifyListeners();
  }

  Future<void> setStrategy(BookPickStrategy strategy) async {
    if (_strategy == strategy) return;
    _strategy = strategy;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_strategyKey, strategy.name);
  }

  Future<void> setManualBookId(String? bookId) async {
    if (_manualBookId == bookId) return;
    _manualBookId = bookId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (bookId == null) {
      await prefs.remove(_manualBookIdKey);
    } else {
      await prefs.setString(_manualBookIdKey, bookId);
    }
  }

  Future<void> saveRoundRobinIndex(int index) async {
    _roundRobinIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_roundRobinIndexKey, index);
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/page_entry.dart';

/// 感想持久化
class PageEntryService extends ChangeNotifier {
  static const _key = 'daily_page_entries';

  Map<String, PageEntry> _entries = {};

  bool hasWrittenToday(String dateKey) => _entries.containsKey(dateKey);

  PageEntry? entryFor(String dateKey) => _entries[dateKey];

  List<PageEntry> get allSorted {
    final list = _entries.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int get count => _entries.length;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _entries = map.map((k, v) =>
          MapEntry(k, PageEntry.fromJson(v as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      debugPrint('Load entries failed: $e');
    }
  }

  Future<void> save(
    String dateKey,
    String reflection, {
    String? bookTitle,
    String? author,
  }) async {
    _entries[dateKey] = PageEntry(
      dateKey: dateKey,
      reflection: reflection,
      createdAt: DateTime.now(),
      bookTitle: bookTitle,
      author: author,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String dateKey) async {
    _entries.remove(dateKey);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_entries.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (e) {
      debugPrint('Save entries failed: $e');
    }
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/page_entry.dart';

/// 感想持久化
class PageEntryService extends ChangeNotifier {
  static const _key = 'daily_page_entries';

  Map<String, PageEntry> _entries = {};

  /// Storage key: one entry per date + book title.
  static String storageKey(String dateKey, {String? bookTitle}) {
    if (bookTitle != null && bookTitle.isNotEmpty) {
      return '$dateKey|$bookTitle';
    }
    return dateKey;
  }

  bool hasWrittenToday(String dateKey) =>
      _entries.keys.any((k) => k == dateKey || k.startsWith('$dateKey|'));

  bool hasWrittenFor(String dateKey, {String? bookTitle}) =>
      entryFor(dateKey, bookTitle: bookTitle) != null;

  PageEntry? entryFor(String dateKey, {String? bookTitle}) {
    if (bookTitle != null && bookTitle.isNotEmpty) {
      final composite = storageKey(dateKey, bookTitle: bookTitle);
      if (_entries.containsKey(composite)) return _entries[composite];

      // Legacy: single entry stored under dateKey only.
      final legacy = _entries[dateKey];
      if (legacy != null &&
          (legacy.bookTitle == null ||
              legacy.bookTitle!.isEmpty ||
              legacy.bookTitle == bookTitle)) {
        return legacy;
      }
      return null;
    }
    return _entries[dateKey];
  }

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
      _entries = map.map((k, v) => MapEntry(
            k,
            PageEntry.fromJson(v as Map<String, dynamic>, storageKey: k),
          ));
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
    String? sourceNote,
  }) async {
    final id = storageKey(dateKey, bookTitle: bookTitle);
    _entries[id] = PageEntry(
      id: id,
      dateKey: dateKey,
      reflection: reflection,
      createdAt: DateTime.now(),
      bookTitle: bookTitle,
      author: author,
      sourceNote: sourceNote,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _entries.remove(id);
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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_reflection_group.dart';
import '../models/page_entry.dart';
import '../utils/passage_key.dart';

/// 感想持久化
class PageEntryService extends ChangeNotifier {
  static const _key = 'daily_page_entries';

  Map<String, PageEntry> _entries = {};

  static String storageKey(
    String dateKey, {
    String? bookTitle,
    String? passageKey,
  }) {
    if (bookTitle != null && bookTitle.isNotEmpty) {
      if (passageKey != null && passageKey.isNotEmpty) {
        return '$dateKey|$bookTitle|$passageKey';
      }
      return '$dateKey|$bookTitle';
    }
    return dateKey;
  }

  bool hasWrittenToday(String dateKey) =>
      _entries.keys.any((k) => k == dateKey || k.startsWith('$dateKey|'));

  bool hasWrittenFor(
    String dateKey, {
    String? bookTitle,
    String? passageKey,
  }) =>
      entryFor(
        dateKey,
        bookTitle: bookTitle,
        passageKey: passageKey,
      ) !=
      null;

  PageEntry? entryFor(
    String dateKey, {
    String? bookTitle,
    String? passageKey,
  }) {
    if (bookTitle != null && bookTitle.isNotEmpty) {
      if (passageKey != null && passageKey.isNotEmpty) {
        final exact = storageKey(
          dateKey,
          bookTitle: bookTitle,
          passageKey: passageKey,
        );
        if (_entries.containsKey(exact)) return _entries[exact];

        final composite = storageKey(dateKey, bookTitle: bookTitle);
        if (_entries.containsKey(composite)) return _entries[composite];

        return null;
      }

      final composite = storageKey(dateKey, bookTitle: bookTitle);
      if (_entries.containsKey(composite)) return _entries[composite];

      final prefix = '$dateKey|$bookTitle|';
      final passageMatches = _entries.entries
          .where((e) => e.key.startsWith(prefix))
          .map((e) => e.value)
          .toList();
      if (passageMatches.length == 1) return passageMatches.first;
      if (passageMatches.length > 1) {
        passageMatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return passageMatches.first;
      }

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

  PageEntry? getById(String id) => _entries[id];

  List<PageEntry> get allSorted {
    final list = _entries.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<PageEntry> entriesForBook(String groupKey) {
    return allSorted
        .where(
          (e) =>
              bookGroupKey(bookTitle: e.bookTitle, author: e.author) ==
              groupKey,
        )
        .toList();
  }

  List<BookReflectionGroup> groupByBook() {
    final map = <String, List<PageEntry>>{};
    for (final entry in allSorted) {
      final key = bookGroupKey(bookTitle: entry.bookTitle, author: entry.author);
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map.entries.map((e) {
      final first = e.value.first;
      final lastAt = e.value
          .map((entry) => entry.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return BookReflectionGroup(
        groupKey: e.key,
        bookTitle: first.bookTitle ?? '未知书名',
        author: first.author ?? '',
        entries: e.value,
        lastWrittenAt: lastAt,
      );
    }).toList()
      ..sort((a, b) => b.lastWrittenAt.compareTo(a.lastWrittenAt));
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

  Future<PageEntry> save(
    String dateKey,
    String reflection, {
    String? bookTitle,
    String? author,
    String? sourceNote,
    String? pageContent,
    String? passageKey,
  }) async {
    final id = storageKey(
      dateKey,
      bookTitle: bookTitle,
      passageKey: passageKey,
    );
    final entry = PageEntry(
      id: id,
      dateKey: dateKey,
      reflection: reflection,
      createdAt: DateTime.now(),
      bookTitle: bookTitle,
      author: author,
      sourceNote: sourceNote,
      pageContent: pageContent,
      passageKey: passageKey,
    );
    _entries[id] = entry;
    await _persist();
    notifyListeners();
    return entry;
  }

  Future<void> updateReflection(String id, String reflection) async {
    final existing = _entries[id];
    if (existing == null) return;
    _entries[id] = PageEntry(
      id: existing.id,
      dateKey: existing.dateKey,
      reflection: reflection,
      createdAt: existing.createdAt,
      bookTitle: existing.bookTitle,
      author: existing.author,
      sourceNote: existing.sourceNote,
      pageContent: existing.pageContent,
      passageKey: existing.passageKey,
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

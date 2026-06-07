import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_pick_strategy.dart';
import '../models/shelf_book.dart';
import 'reading_config_service.dart';

/// 书架与在读书队列管理
class BookshelfService extends ChangeNotifier {
  BookshelfService({ReadingConfigService? config})
      : _config = config ?? ReadingConfigService() {
    _config.addListener(notifyListeners);
  }

  static const _key = 'daily_page_bookshelf';

  final ReadingConfigService _config;
  List<ShelfBook> _books = [];
  bool _loaded = false;

  ReadingConfigService get config => _config;
  List<ShelfBook> get books => List.unmodifiable(_books);
  List<ShelfBook> get readingBooks =>
      _books.where((b) => b.inReading).toList(growable: false);
  bool get loaded => _loaded;
  bool get hasReadingBooks => readingBooks.isNotEmpty;
  bool get canAddToReading =>
      readingBooks.length < ReadingConfigService.maxReadingBooks;

  Future<void> load() async {
    await _config.load();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _books = list
            .map((e) => ShelfBook.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Load bookshelf failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  /// 按策略从在读书队列中选今日书目
  Future<ShelfBook?> pickForToday(String dateKey) async {
    final queue = readingBooks;
    if (queue.isEmpty) return null;

    final strategy = _config.strategy;
    ShelfBook? picked;

    switch (strategy) {
      case BookPickStrategy.manual:
        final manualId = _config.manualBookId;
        picked = _findInQueue(queue, manualId) ?? queue.first;
      case BookPickStrategy.roundRobin:
        final idx = _config.roundRobinIndex % queue.length;
        picked = queue[idx];
        await _config.saveRoundRobinIndex((idx + 1) % queue.length);
      case BookPickStrategy.longestUnread:
        queue.sort((a, b) {
          final ak = a.lastReadDateKey ?? '';
          final bk = b.lastReadDateKey ?? '';
          if (ak.isEmpty && bk.isEmpty) return a.title.compareTo(b.title);
          if (ak.isEmpty) return -1;
          if (bk.isEmpty) return 1;
          return ak.compareTo(bk);
        });
        picked = queue.first;
      case BookPickStrategy.random:
        final hash = dateKey.hashCode.abs();
        picked = queue[hash % queue.length];
    }

    await _markRead(picked.id, dateKey);
    return picked;
  }

  ShelfBook? _findInQueue(List<ShelfBook> queue, String? id) {
    if (id == null) return null;
    for (final b in queue) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<void> _markRead(String id, String dateKey) async {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    _books[idx] = _books[idx].copyWith(lastReadDateKey: dateKey);
    await _persist();
    notifyListeners();
  }

  Future<bool> addToReading(String id) async {
    if (!canAddToReading) return false;
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx < 0) return false;
    if (_books[idx].inReading) return true;
    _books[idx] = _books[idx].copyWith(inReading: true);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> removeFromReading(String id) async {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    _books[idx] = _books[idx].copyWith(inReading: false);
    if (_config.manualBookId == id) {
      await _config.setManualBookId(null);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> mergeWeReadBooks(List<ShelfBook> incoming) async {
    final byId = {for (final b in _books) b.id: b};
    for (final book in incoming) {
      final existing = byId[book.id];
      if (existing != null) {
        byId[book.id] = existing.copyWith(
          title: book.title,
          author: book.author,
          cover: book.cover,
          bookId: book.bookId,
          source: ShelfBookSource.weread,
        );
      } else {
        byId[book.id] = book;
      }
    }
    _books = byId.values.toList()..sort((a, b) => a.title.compareTo(b.title));
    await _persist();
    notifyListeners();
  }

  Future<void> addManual(String title, String author) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final id =
        'manual-${trimmed.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    final book = ShelfBook(
      id: id,
      title: trimmed,
      author: author.trim(),
      source: ShelfBookSource.manual,
      inReading: canAddToReading,
    );
    _books.add(book);
    _books.sort((a, b) => a.title.compareTo(b.title));
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _books.removeWhere((b) => b.id == id);
    if (_config.manualBookId == id) {
      await _config.setManualBookId(null);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_books.map((b) => b.toJson()).toList()),
    );
  }
}

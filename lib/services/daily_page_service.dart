import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/daily_page_reading.dart';
import '../models/shelf_book.dart';
import 'bookshelf_service.dart';
import 'daily_page_client.dart';
import 'weread_config_store.dart';

/// 今日阅读页状态管理
class DailyPageService extends ChangeNotifier {
  DailyPageService({DailyPageClient? client})
      : _client = client ?? DailyPageClient();

  final DailyPageClient _client;
  BookshelfService? _bookshelf;

  DailyPageReading? _page;
  ShelfBook? _pickedBook;
  /// 当日已选书目日期，避免「刷新」重复 pickForToday 推进轮询
  String? _pickedDateKey;
  bool _loading = false;
  String? _error;
  bool _disposed = false;
  String? _deviceId;

  DailyPageReading? get page => _page;
  ShelfBook? get pickedBook => _pickedBook;
  bool get loading => _loading;
  String? get error => _error;
  /// 实时反映书架在读书队列，避免添加书后仍显示探索模式 UI
  bool get discoveryMode => !(_bookshelf?.hasReadingBooks ?? false);
  String? get deviceId => _deviceId;

  void bindBookshelf(BookshelfService bookshelf) {
    _bookshelf?.removeListener(_onBookshelfChanged);
    _bookshelf = bookshelf;
    _bookshelf?.addListener(_onBookshelfChanged);
  }

  void _onBookshelfChanged() {
    _notifyIfActive();
  }

  void init(String deviceId) {
    _deviceId = deviceId;
    unawaited(refresh());
  }

  /// 探索模式：换一本随机书（不消耗每日首次配额）
  Future<void> switchBook() => refresh(switchBook: true);

  Future<void> refresh({ShelfBook? overrideBook, bool switchBook = false}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cookie = await WeReadConfigStore.getCookie();
      final hasWeRead = cookie != null && cookie.isNotEmpty;
      final hasReading = _bookshelf?.hasReadingBooks ?? false;
      final inDiscovery = !hasReading;

      final todayKey = _todayKey();
      ShelfBook? book = overrideBook;
      if (book == null && hasReading && !switchBook) {
        if (_canReuseTodayPick(todayKey)) {
          book = _pickedBook;
        } else {
          book = await _bookshelf!.pickForToday(todayKey);
        }
      }

      final nonce = switchBook
          ? DateTime.now().millisecondsSinceEpoch
          : 0;

      final sendBook = inDiscovery && switchBook ? null : book;
      debugPrint(
        'DailyPageService refresh: discovery=$inDiscovery switchBook=$switchBook '
        'book=${sendBook?.title ?? "(none)"} bookId=${sendBook?.bookId}',
      );

      final result = await _client.fetchWithMeta(
        deviceId: _deviceId ?? _randomId(),
        book: sendBook,
        wereadCookie: hasWeRead ? cookie : null,
        nonce: nonce,
      );

      _page = result.reading;
      _pickedBook = result.pickedBook;
      if (hasReading && !switchBook && _pickedBook != null) {
        _pickedDateKey = todayKey;
      }
      _error = null;
      _loading = false;
    } catch (e) {
      _error = _friendlyError(e);
      _page = null;
      _loading = false;
      debugPrint('DailyPageService refresh failed: $e');
    }

    _notifyIfActive();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('429')) return '今日配额已用尽，明天再来';
    if (msg.contains('503')) return '服务端未配置，请检查 DeepSeek Key';
    if (msg.contains('502')) return '生成失败，请稍后重试';
    return '加载失败，请检查网络';
  }

  bool _canReuseTodayPick(String todayKey) {
    if (_pickedBook == null || _pickedDateKey != todayKey) return false;
    final queue = _bookshelf?.readingBooks ?? const [];
    return queue.any((b) => b.id == _pickedBook!.id);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _randomId() =>
      'daily-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _bookshelf?.removeListener(_onBookshelfChanged);
    _disposed = true;
    super.dispose();
  }
}

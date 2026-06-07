import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_page/models/book_pick_strategy.dart';
import 'package:daily_page/models/daily_page_reading.dart';
import 'package:daily_page/models/shelf_book.dart';
import 'package:daily_page/services/bookshelf_service.dart';
import 'package:daily_page/services/daily_page_client.dart';
import 'package:daily_page/services/daily_page_service.dart';
import 'package:daily_page/services/reading_config_service.dart';

class _FakeDailyPageClient extends DailyPageClient {
  _FakeDailyPageClient({this.result, this.error});

  final DailyPageFetchResult? result;
  final Object? error;

  @override
  Future<DailyPageFetchResult> fetchWithMeta({
    required String deviceId,
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    if (error != null) throw error!;
    return result!;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyPageService', () {
    test('refresh sets page on success', () async {
      final reading = DailyPageReading(
        bookTitle: '测试书',
        author: '作者',
        content: '内容',
        sourceNote: '注',
        date: DateTime(2026, 6, 7),
      );
      final client = _FakeDailyPageClient(
        result: DailyPageFetchResult(reading: reading),
      );
      final service = DailyPageService(client: client);

      await service.refresh();

      expect(service.loading, isFalse);
      expect(service.error, isNull);
      expect(service.page?.bookTitle, '测试书');
      expect(service.discoveryMode, isTrue);
    });

    test('refresh maps 429 to friendly quota message', () async {
      final client = _FakeDailyPageClient(
        error: Exception('HTTP 429: quota exceeded'),
      );
      final service = DailyPageService(client: client);

      await service.refresh();

      expect(service.error, '今日配额已用尽，明天再来');
      expect(service.page, isNull);
    });

    test('refresh maps 503 to config hint', () async {
      final client = _FakeDailyPageClient(
        error: Exception('HTTP 503'),
      );
      final service = DailyPageService(client: client);

      await service.refresh();

      expect(service.error, '服务端未配置，请检查 DeepSeek Key');
    });

    test('refresh picks manual book without weread cookie', () async {
      final config = ReadingConfigService();
      await config.load();
      final shelf = BookshelfService(config: config);
      await shelf.load();
      await shelf.addManual('在读书目', '作者');

      final reading = DailyPageReading(
        bookTitle: '在读书目',
        author: '作者',
        content: '摘录',
        sourceNote: '',
        date: DateTime(2026, 6, 7),
      );
      ShelfBook? capturedBook;
      String? capturedCookie;
      final capturingClient = _CapturingClient(
        result: DailyPageFetchResult(
          reading: reading,
          pickedBook: shelf.readingBooks.first,
        ),
        onFetch: (book, cookie) {
          capturedBook = book;
          capturedCookie = cookie;
        },
      );

      final service = DailyPageService(client: capturingClient);
      service.bindBookshelf(shelf);

      await service.refresh();

      expect(capturedBook?.title, '在读书目');
      expect(capturedBook?.bookId, isNull);
      expect(capturedCookie, isNull);
      expect(service.discoveryMode, isFalse);
      expect(service.pickedBook?.title, '在读书目');
    });

    test('refresh picks book from bookshelf when weread configured', () async {
      final config = ReadingConfigService();
      await config.load();
      final shelf = BookshelfService(config: config);
      await shelf.load();
      await shelf.addManual('在读书目', '作者');

      final reading = DailyPageReading(
        bookTitle: '在读书目',
        author: '作者',
        content: '摘录',
        sourceNote: '',
        date: DateTime(2026, 6, 7),
      );
      ShelfBook? capturedBook;
      final capturingClient = _CapturingClient(
        result: DailyPageFetchResult(
          reading: reading,
          pickedBook: shelf.readingBooks.first,
        ),
        onFetch: (book, _) => capturedBook = book,
      );

      final service = DailyPageService(client: capturingClient);
      service.bindBookshelf(shelf);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weread_cookie', 'sid=test');

      await service.refresh();

      expect(capturedBook?.title, '在读书目');
      expect(service.discoveryMode, isFalse);
      expect(service.pickedBook?.title, '在读书目');
    });

    test('bookshelf add to reading auto-refreshes stale discovery page', () async {
      final config = ReadingConfigService();
      await config.load();
      final shelf = BookshelfService(config: config);
      await shelf.load();

      var fetchCount = 0;
      final client = _CountingClient(onFetch: () => fetchCount++);
      final service = DailyPageService(client: client);
      service.bindBookshelf(shelf);

      await service.refresh();
      expect(fetchCount, 1);
      expect(service.discoveryMode, isTrue);

      await shelf.addManual('在读书目', '作者');
      await Future<void>.delayed(Duration.zero);

      expect(fetchCount, 2);
      expect(service.discoveryMode, isFalse);
    });

    test('discoveryMode reflects bookshelf without waiting for refresh', () async {
      final config = ReadingConfigService();
      await config.load();
      final shelf = BookshelfService(config: config);
      await shelf.load();

      final service = DailyPageService(
        client: _FakeDailyPageClient(
          result: DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '随机书',
              author: '作者',
              content: '内容',
              sourceNote: '',
              date: DateTime(2026, 6, 7),
            ),
          ),
        ),
      );
      service.bindBookshelf(shelf);

      expect(service.discoveryMode, isTrue);
      await shelf.addManual('在读书目', '作者');
      expect(service.discoveryMode, isFalse);
    });

    test('refresh reuses today pick without advancing roundRobin', () async {
      final config = ReadingConfigService();
      await config.setStrategy(BookPickStrategy.roundRobin);
      final shelf = BookshelfService(config: config);
      await shelf.load();
      await shelf.addManual('第一本', '');
      await shelf.addManual('第二本', '');

      final reading = DailyPageReading(
        bookTitle: '第一本',
        author: '',
        content: '摘录',
        sourceNote: '',
        date: DateTime(2026, 6, 7),
      );
      final client = _FakeDailyPageClient(
        result: DailyPageFetchResult(
          reading: reading,
          pickedBook: shelf.readingBooks.first,
        ),
      );
      final service = DailyPageService(client: client);
      service.bindBookshelf(shelf);

      await service.refresh();
      expect(config.roundRobinIndex, 1);
      expect(service.pickedBook?.title, '第一本');

      await service.refresh();
      expect(config.roundRobinIndex, 1);
      expect(service.pickedBook?.title, '第一本');
    });

    test('nextReadingBook picks from queue with book title', () async {
      final config = ReadingConfigService();
      await config.setStrategy(BookPickStrategy.roundRobin);
      final shelf = BookshelfService(config: config);
      await shelf.load();
      await shelf.addManual('第一本', '');
      await shelf.addManual('第二本', '');

      ShelfBook? capturedBook;
      final client = _CapturingClient(
        result: DailyPageFetchResult(
          reading: DailyPageReading(
            bookTitle: '第二本',
            author: '',
            content: '摘录',
            sourceNote: '',
            date: DateTime(2026, 6, 7),
          ),
        ),
        onFetch: (book, _) => capturedBook = book,
      );

      final service = DailyPageService(client: client);
      service.bindBookshelf(shelf);

      await service.refresh();
      expect(capturedBook?.title, '第一本');

      await service.nextReadingBook();
      expect(capturedBook?.title, '第二本');
      expect(service.discoveryMode, isFalse);
    });

    test('pending refresh runs after in-flight discovery load when book added',
        () async {
      final config = ReadingConfigService();
      await config.load();
      final shelf = BookshelfService(config: config);
      await shelf.load();

      var fetchCount = 0;
      final client = _DelayedCountingClient(
        onFetch: () => fetchCount++,
        delay: const Duration(milliseconds: 50),
      );
      final service = DailyPageService(client: client);
      service.bindBookshelf(shelf);

      final firstRefresh = service.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await shelf.addManual('在读书目', '作者');
      await firstRefresh;
      while (service.loading || fetchCount < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(fetchCount, 2);
      expect(service.discoveryMode, isFalse);
      expect(service.pickedBook?.title, '在读书目');
    });

    test('repicks when today book removed from reading queue', () async {
      final config = ReadingConfigService();
      await config.setStrategy(BookPickStrategy.roundRobin);
      final shelf = BookshelfService(config: config);
      await shelf.load();
      await shelf.addManual('第一本', '');
      await shelf.addManual('第二本', '');

      final service = DailyPageService(client: _EchoBookClient());
      service.bindBookshelf(shelf);

      await service.refresh();
      final firstId = service.pickedBook!.id;
      await shelf.removeFromReading(firstId);
      while (service.loading) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(service.pickedBook?.title, '第二本');
      expect(config.roundRobinIndex, 0);
    });
  });
}

class _EchoBookClient extends DailyPageClient {
  @override
  Future<DailyPageFetchResult> fetchWithMeta({
    required String deviceId,
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    return DailyPageFetchResult(
      reading: DailyPageReading(
        bookTitle: book?.title ?? '探索',
        author: book?.author ?? '',
        content: '摘录',
        sourceNote: '',
        date: DateTime(2026, 6, 7),
      ),
      pickedBook: book,
    );
  }
}

class _CountingClient extends DailyPageClient {
  _CountingClient({required this.onFetch});

  final void Function() onFetch;

  @override
  Future<DailyPageFetchResult> fetchWithMeta({
    required String deviceId,
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    onFetch();
    return DailyPageFetchResult(
      reading: DailyPageReading(
        bookTitle: book?.title ?? '探索书',
        author: book?.author ?? '',
        content: '摘录',
        sourceNote: '',
        date: DateTime(2026, 6, 7),
      ),
      pickedBook: book ??
          ShelfBook(
            id: 'discovery-1',
            title: '探索书',
          ),
    );
  }
}

class _DelayedCountingClient extends DailyPageClient {
  _DelayedCountingClient({required this.onFetch, required this.delay});

  final void Function() onFetch;
  final Duration delay;

  @override
  Future<DailyPageFetchResult> fetchWithMeta({
    required String deviceId,
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    onFetch();
    await Future<void>.delayed(delay);
    return DailyPageFetchResult(
      reading: DailyPageReading(
        bookTitle: book?.title ?? '探索书',
        author: book?.author ?? '',
        content: '摘录',
        sourceNote: '',
        date: DateTime(2026, 6, 7),
      ),
      pickedBook: book ??
          ShelfBook(
            id: 'discovery-1',
            title: '探索书',
          ),
    );
  }
}

class _CapturingClient extends DailyPageClient {
  _CapturingClient({required this.result, this.onFetch});

  final DailyPageFetchResult result;
  final void Function(ShelfBook? book, String? wereadCookie)? onFetch;

  @override
  Future<DailyPageFetchResult> fetchWithMeta({
    required String deviceId,
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    onFetch?.call(book, wereadCookie);
    return result;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('refresh picks book from bookshelf when configured', () async {
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
        onFetch: (book) => capturedBook = book,
      );

      final service = DailyPageService(client: capturingClient);
      service.bindBookshelf(shelf);

      // Set cookie so hasWeRead is true
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weread_cookie', 'sid=test');

      await service.refresh();

      expect(capturedBook?.title, '在读书目');
      expect(service.discoveryMode, isFalse);
      expect(service.pickedBook?.title, '在读书目');
    });
  });
}

class _CapturingClient extends DailyPageClient {
  _CapturingClient({required this.result, this.onFetch});

  final DailyPageFetchResult result;
  final void Function(ShelfBook? book)? onFetch;

  @override
  Future<DailyPageFetchResult> fetchWithMeta({
    required String deviceId,
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    onFetch?.call(book);
    return result;
  }
}

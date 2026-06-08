import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_page/models/shelf_book.dart';
import 'package:daily_page/services/bookshelf_service.dart';
import 'package:daily_page/services/reading_config_service.dart';

void main() {
  late ReadingConfigService config;
  late BookshelfService shelf;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    config = ReadingConfigService();
    await config.load();
    shelf = BookshelfService(config: config);
    await shelf.load();
  });

  group('BookshelfService', () {
    test('load starts with empty bookshelf', () {
      expect(shelf.books, isEmpty);
      expect(shelf.readingBooks, isEmpty);
      expect(shelf.loaded, isTrue);
    });

    test('addManual adds book to reading queue and persists', () async {
      await shelf.addManual('  三体  ', '刘慈欣');

      expect(shelf.books, hasLength(1));
      expect(shelf.books.first.title, '三体');
      expect(shelf.books.first.author, '刘慈欣');
      expect(shelf.books.first.inReading, isTrue);
      expect(shelf.books.first.source, ShelfBookSource.manual);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('daily_page_bookshelf');
      expect(raw, isNotNull);
      final list = jsonDecode(raw!) as List<dynamic>;
      expect(list, hasLength(1));
      expect(list.first['title'], '三体');
    });

    test('addManual ignores empty title', () async {
      await shelf.addManual('   ', '作者');
      expect(shelf.books, isEmpty);
    });

    test('load restores persisted books', () async {
      await shelf.addManual('活着', '余华');

      final shelf2 = BookshelfService(config: config);
      await shelf2.load();

      expect(shelf2.books, hasLength(1));
      expect(shelf2.books.first.title, '活着');
      expect(shelf2.books.first.inReading, isTrue);
    });

    test('addToReading and removeFromReading', () async {
      await shelf.addManual('A书', '');
      final id = shelf.books.first.id;
      await shelf.removeFromReading(id);

      expect(shelf.readingBooks, isEmpty);
      expect(shelf.books.first.inReading, isFalse);

      final ok = await shelf.addToReading(id);
      expect(ok, isTrue);
      expect(shelf.readingBooks, hasLength(1));
    });

    test('addToReading returns false when queue is full', () async {
      await shelf.addManual('书1', '');
      await shelf.addManual('书2', '');
      await shelf.addManual('书3', '');
      expect(shelf.readingBooks, hasLength(3));

      await shelf.addManual('书4', '');
      final book4 = shelf.books.firstWhere((b) => b.title == '书4');
      expect(book4.inReading, isFalse);

      final ok = await shelf.addToReading(book4.id);
      expect(ok, isFalse);
      expect(shelf.readingBooks, hasLength(3));
    });

    test('remove deletes book from shelf', () async {
      await shelf.addManual('待删', '');
      final id = shelf.books.first.id;
      await shelf.remove(id);

      expect(shelf.books, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('daily_page_bookshelf'), '[]');
    });

    test('pickForToday prefers longest unread', () async {
      await shelf.addManual('第一本', '');
      await shelf.addManual('第二本', '');
      final firstId = shelf.books.firstWhere((b) => b.title == '第一本').id;

      await shelf.pickForToday('2026-06-06');
      final picked = await shelf.pickForToday('2026-06-07');

      expect(picked?.title, '第二本');
      expect(
        shelf.books.firstWhere((b) => b.id == firstId).lastReadDateKey,
        '2026-06-06',
      );
    });

    test('pickForToday respects today override', () async {
      await shelf.addManual('第一本', '');
      await shelf.addManual('第二本', '');
      final second = shelf.books.firstWhere((b) => b.title == '第二本');

      await shelf.setTodayBook(second.id);
      final picked = await shelf.pickForToday('2026-06-07');

      expect(picked?.title, '第二本');
    });

    test('pickForToday excludeBookId picks another book', () async {
      await shelf.addManual('第一本', '');
      await shelf.addManual('第二本', '');
      final first = shelf.books.firstWhere((b) => b.title == '第一本');

      final picked = await shelf.pickForToday(
        '2026-06-07',
        excludeBookId: first.id,
        respectTodayOverride: false,
      );

      expect(picked?.title, '第二本');
    });

    test('mergeWeReadBooks merges and updates existing', () async {
      await shelf.addManual('三体', '旧作者');
      final id = shelf.books.first.id;

      await shelf.mergeWeReadBooks([
        ShelfBook(
          id: id,
          bookId: 'wr-1',
          title: '三体',
          author: '刘慈欣',
          source: ShelfBookSource.weread,
        ),
        const ShelfBook(
          id: 'wr-2',
          bookId: 'wr-2',
          title: '球状闪电',
          author: '刘慈欣',
          source: ShelfBookSource.weread,
        ),
      ]);

      expect(shelf.books, hasLength(2));
      final updated = shelf.books.firstWhere((b) => b.id == id);
      expect(updated.author, '刘慈欣');
      expect(updated.source, ShelfBookSource.weread);
      expect(updated.bookId, 'wr-1');
    });

    test('notifies listeners when today book changes', () async {
      await shelf.addManual('书', '');
      var notifications = 0;
      shelf.addListener(() => notifications++);

      await shelf.setTodayBook(shelf.books.first.id);

      expect(notifications, greaterThanOrEqualTo(1));
      expect(shelf.config.todayBookId, shelf.books.first.id);
    });
  });
}

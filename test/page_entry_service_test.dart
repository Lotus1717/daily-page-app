import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_page/services/page_entry_service.dart';

void main() {
  late PageEntryService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = PageEntryService();
    await service.load();
  });

  group('PageEntryService', () {
    test('save and load entry', () async {
      await service.save(
        '2026-06-07',
        '今日感想',
        bookTitle: '三体',
        author: '刘慈欣',
        sourceNote: '第三章',
      );

      expect(service.hasWrittenFor('2026-06-07', bookTitle: '三体'), isTrue);
      final entry = service.entryFor('2026-06-07', bookTitle: '三体');
      expect(entry?.reflection, '今日感想');
      expect(entry?.bookTitle, '三体');
      expect(entry?.author, '刘慈欣');
      expect(entry?.sourceNote, '第三章');
      expect(service.count, 1);

      final service2 = PageEntryService();
      await service2.load();
      final loaded = service2.entryFor('2026-06-07', bookTitle: '三体');
      expect(loaded?.reflection, '今日感想');
      expect(loaded?.sourceNote, '第三章');
    });

    test('loads legacy entry without sourceNote', () async {
      await service.save('2026-06-07', '旧感想', bookTitle: '测试书');

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('daily_page_entries')!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final legacyKey = '2026-06-07';
      final entryJson = Map<String, dynamic>.from(
          map.remove('2026-06-07|测试书') as Map<String, dynamic>)
        ..remove('id')
        ..remove('sourceNote');
      map[legacyKey] = entryJson;
      await prefs.setString('daily_page_entries', jsonEncode(map));

      final service2 = PageEntryService();
      await service2.load();
      final entry = service2.entryFor('2026-06-07', bookTitle: '测试书');
      expect(entry?.reflection, '旧感想');
      expect(entry?.sourceNote, isNull);
      expect(entry?.id, legacyKey);
    });

    test('delete removes entry', () async {
      await service.save('2026-06-07', '感想');
      await service.delete('2026-06-07');

      expect(service.hasWrittenToday('2026-06-07'), isFalse);
      expect(service.count, 0);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('daily_page_entries');
      expect(raw, isNotNull);
      final map = jsonDecode(raw!) as Map<String, dynamic>;
      expect(map, isEmpty);
    });

    test('same day different books allow separate entries', () async {
      await service.save('2026-06-07', '第一本感想', bookTitle: '书A');
      await service.save('2026-06-07', '第二本感想', bookTitle: '书B');

      expect(service.count, 2);
      expect(
        service.entryFor('2026-06-07', bookTitle: '书A')?.reflection,
        '第一本感想',
      );
      expect(
        service.entryFor('2026-06-07', bookTitle: '书B')?.reflection,
        '第二本感想',
      );
      expect(service.hasWrittenToday('2026-06-07'), isTrue);
    });

    test('same day same book different passages allow separate entries',
        () async {
      await service.save(
        '2026-06-07',
        '第一段感想',
        bookTitle: '书A',
        pageContent: '第一页内容',
        passageKey: 'key1',
      );
      await service.save(
        '2026-06-07',
        '第二段感想',
        bookTitle: '书A',
        pageContent: '第二页内容',
        passageKey: 'key2',
      );

      expect(service.count, 2);
      expect(
        service.entryFor('2026-06-07', bookTitle: '书A', passageKey: 'key1')
            ?.reflection,
        '第一段感想',
      );
      expect(
        service.entryFor('2026-06-07', bookTitle: '书A', passageKey: 'key2')
            ?.reflection,
        '第二段感想',
      );
    });

    test('groupByBook aggregates entries', () async {
      await service.save('2026-06-07', 'A1', bookTitle: '书A', author: '作者A');
      await service.save('2026-06-06', 'A2', bookTitle: '书A', author: '作者A');
      await service.save('2026-06-05', 'B1', bookTitle: '书B');

      final groups = service.groupByBook();
      expect(groups.length, 2);
      final bookA = groups.firstWhere((g) => g.bookTitle == '书A');
      expect(bookA.count, 2);
    });

    test('allSorted returns newest first', () async {
      await service.save('2026-06-05', '旧');
      await service.save('2026-06-07', '新');

      final sorted = service.allSorted;
      expect(sorted.first.reflection, '新');
      expect(sorted.last.reflection, '旧');
    });
  });
}

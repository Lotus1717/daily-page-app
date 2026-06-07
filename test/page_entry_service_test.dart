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
      await service.save('2026-06-07', '今日感想', bookTitle: '三体', author: '刘慈欣');

      expect(service.hasWrittenToday('2026-06-07'), isTrue);
      final entry = service.entryFor('2026-06-07');
      expect(entry?.reflection, '今日感想');
      expect(entry?.bookTitle, '三体');
      expect(service.count, 1);

      final service2 = PageEntryService();
      await service2.load();
      expect(service2.entryFor('2026-06-07')?.reflection, '今日感想');
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

    test('allSorted returns newest first', () async {
      await service.save('2026-06-05', '旧');
      await service.save('2026-06-07', '新');

      final sorted = service.allSorted;
      expect(sorted.first.reflection, '新');
      expect(sorted.last.reflection, '旧');
    });
  });
}

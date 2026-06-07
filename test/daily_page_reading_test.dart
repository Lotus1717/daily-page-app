import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/models/daily_page_reading.dart';

void main() {
  group('sanitizeSourceNote', () {
    test('replaces cryptic codes with 节选', () {
      expect(sanitizeSourceNote('20d-30c'), '节选');
      expect(sanitizeSourceNote('ch3'), '节选');
      expect(sanitizeSourceNote('Part 2'), '节选');
    });

    test('keeps readable Chinese chapter names', () {
      expect(sanitizeSourceNote('第三章'), '第三章');
      expect(sanitizeSourceNote('第二部 · 第一节'), '第二部 · 第一节');
      expect(sanitizeSourceNote('序章'), '序章');
    });
  });

  group('DailyPageReading.fromJson', () {
    test('sanitizes source_note on parse', () {
      final reading = DailyPageReading.fromJson({
        'book_title': '三体',
        'author': '刘慈欣',
        'content': '摘录',
        'source_note': '20d-30c',
        'date': '2026-06-07',
      });

      expect(reading.sourceNote, '节选');
    });
  });
}

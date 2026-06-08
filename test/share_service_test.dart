import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/models/page_entry.dart';
import 'package:daily_page/services/share_service.dart';

void main() {
  group('ShareService', () {
    test('formatShareText includes book, excerpt and reflection', () {
      final text = ShareService.formatShareText(
        PageEntry(
          id: '1',
          dateKey: '2026-06-07',
          reflection: '读到这里很有共鸣',
          createdAt: DateTime(2026, 6, 7),
          bookTitle: '三体',
          author: '刘慈欣',
          pageContent: '这是一段书摘正文，用来测试分享格式。',
        ),
      );

      expect(text, contains('三体'));
      expect(text, contains('刘慈欣'));
      expect(text, contains('读到这里很有共鸣'));
      expect(text, contains('这是一段书摘正文'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/models/page_entry.dart';
import 'package:daily_page/widgets/share_card.dart';

void main() {
  group('ShareCard', () {
    final entry = PageEntry(
      id: '1',
      dateKey: '2026-06-07',
      reflection: '读到这里很有共鸣',
      createdAt: DateTime(2026, 6, 7),
      bookTitle: '三体',
      author: '刘慈欣',
      pageContent: '这是一段书摘正文，用来测试分享卡片。',
      sourceNote: '第一部 · 第一章',
    );

    testWidgets('renders book excerpt and reflection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: ShareCard(entry: entry)),
          ),
        ),
      );

      expect(find.text('三体'), findsOneWidget);
      expect(find.text('刘慈欣'), findsOneWidget);
      expect(find.text('这是一段书摘正文，用来测试分享卡片。'), findsOneWidget);
      expect(find.text('第一部 · 第一章'), findsOneWidget);
      expect(find.text('我的感想'), findsOneWidget);
      expect(find.text('读到这里很有共鸣'), findsOneWidget);
      expect(find.textContaining('6月7日'), findsOneWidget);
    });

    testWidgets('long excerpt is clamped to max lines', (tester) async {
      final longContent = List.filled(12, '这是一段很长的书摘正文，用来测试行数截断与渐变效果。')
          .join();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShareCard(
                entry: entry.copyWith(pageContent: longContent),
              ),
            ),
          ),
        ),
      );

      final excerptText = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.data == longContent &&
              w.maxLines == ShareCard.excerptMaxLines,
        ),
      );
      expect(excerptText.maxLines, ShareCard.excerptMaxLines);
      expect(find.byType(Stack), findsWidgets);
    });
  });
}

extension on PageEntry {
  PageEntry copyWith({String? pageContent}) => PageEntry(
        id: id,
        dateKey: dateKey,
        reflection: reflection,
        createdAt: createdAt,
        bookTitle: bookTitle,
        author: author,
        sourceNote: sourceNote,
        pageContent: pageContent ?? this.pageContent,
        passageKey: passageKey,
      );
}

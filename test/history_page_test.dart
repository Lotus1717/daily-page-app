import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/screens/history_page.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    await initTestEnvironment();
  });

  group('HistoryPage', () {
    testWidgets('shows book and chapter on history card', (tester) async {
      final services = await createTestServices();
      await services.entrySvc.save(
        '2026-06-07',
        '很有感触的一段话',
        bookTitle: '三体',
        author: '刘慈欣',
        sourceNote: '第三章',
      );

      await tester.pumpWidget(services.wrap(const HistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('三体 · 刘慈欣'), findsOneWidget);
      expect(find.text('第三章'), findsOneWidget);
      expect(find.text('很有感触的一段话'), findsOneWidget);
    });

    testWidgets('hides chapter when legacy entry has no sourceNote',
        (tester) async {
      final services = await createTestServices();
      await services.entrySvc.save(
        '2026-06-07',
        '旧数据感想',
        bookTitle: '测试书',
        author: '作者',
      );

      await tester.pumpWidget(services.wrap(const HistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('测试书 · 作者'), findsOneWidget);
      expect(find.text('旧数据感想'), findsOneWidget);
      expect(find.text('节选'), findsNothing);
    });

    testWidgets('empty state uses history icon', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const HistoryPage()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.textContaining('还没有记录'), findsOneWidget);
    });

    testWidgets('shows multiple entries from same day', (tester) async {
      final services = await createTestServices();
      await services.entrySvc.save(
        '2026-06-07',
        '第一本感想',
        bookTitle: '书A',
        author: '作者A',
      );
      await services.entrySvc.save(
        '2026-06-07',
        '第二本感想',
        bookTitle: '书B',
        author: '作者B',
        sourceNote: '第十章',
      );

      await tester.pumpWidget(services.wrap(const HistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('第一本感想'), findsOneWidget);
      expect(find.text('第二本感想'), findsOneWidget);
      expect(find.text('书A · 作者A'), findsOneWidget);
      expect(find.text('书B · 作者B'), findsOneWidget);
      expect(find.text('第十章'), findsOneWidget);
    });

    testWidgets('delete button removes entry', (tester) async {
      final services = await createTestServices();
      await services.entrySvc.save(
        '2026-06-07',
        '待删除感想',
        bookTitle: '测试书',
      );

      await tester.pumpWidget(services.wrap(const HistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('待删除感想'), findsOneWidget);

      await tester.tap(find.byTooltip('删除'));
      await tester.pumpAndSettle();

      expect(find.text('删除这条记录？'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();

      expect(find.text('待删除感想'), findsNothing);
      expect(find.text('已删除'), findsOneWidget);
    });

    testWidgets('by book tab shows grouped books', (tester) async {
      final services = await createTestServices();
      await services.entrySvc.save(
        '2026-06-07',
        '感想A',
        bookTitle: '三体',
        author: '刘慈欣',
        pageContent: '摘录正文',
      );
      await services.entrySvc.save(
        '2026-06-06',
        '感想B',
        bookTitle: '活着',
        author: '余华',
      );

      await tester.pumpWidget(services.wrap(const HistoryPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('按书'));
      await tester.pumpAndSettle();

      expect(find.text('三体'), findsOneWidget);
      expect(find.text('活着'), findsOneWidget);
      expect(find.textContaining('1 条感想'), findsNWidgets(2));
    });

    testWidgets('shows page excerpt when saved', (tester) async {
      final services = await createTestServices();
      await services.entrySvc.save(
        '2026-06-07',
        '很有感触',
        bookTitle: '三体',
        pageContent: '这是保存的书摘原文内容。',
      );

      await tester.pumpWidget(services.wrap(const HistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('这是保存的书摘原文内容。'), findsOneWidget);
    });
  });
}

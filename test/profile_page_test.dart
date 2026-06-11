import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:daily_page/screens/history_page.dart';
import 'package:daily_page/screens/profile_page.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    await initTestEnvironment();
  });

  group('ProfilePage interactions', () {
    testWidgets('reflection entry card navigates to HistoryPage', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('还没有记录，去「今日」写一句吧'), findsOneWidget);

      await tester.tap(find.text('感想记录'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryPage), findsOneWidget);
      expect(find.textContaining('还没有记录'), findsOneWidget);
    });

    testWidgets('reflection entry shows saved count', (tester) async {
      final services = await createTestServices();
      await services.entrySvc.save('2026-06-07', '一条感想', bookTitle: '测试书');

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('共 1 条，点击查看'), findsOneWidget);
    });

    testWidgets('displays reading stats from saved entries', (tester) async {
      final services = await createTestServices();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await services.entrySvc.save(today, '今日感想', bookTitle: '测试书');
      await services.entrySvc.save(
        DateFormat('yyyy-MM-dd')
            .format(DateTime.now().subtract(const Duration(days: 1))),
        '昨日感想',
        bookTitle: '另一本',
      );

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.textContaining('累计记录 2 天'), findsOneWidget);
      expect(find.textContaining('记过 2 本书'), findsOneWidget);
      expect(find.text('共 2 条，点击查看'), findsOneWidget);
    });

    testWidgets('community entry opens group sheet', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('关注拾页公众号'), findsOneWidget);

      await tester.tap(find.text('关注拾页公众号'));
      await tester.pumpAndSettle();

      expect(find.text('关闭'), findsOneWidget);
      expect(find.text('拾页 · 读书公众号'), findsOneWidget);
    });

    testWidgets('about section shows feedback and privacy links', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('隐私政策'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('关于'), findsOneWidget);
      expect(find.text('意见反馈'), findsOneWidget);
      expect(find.text('隐私政策'), findsOneWidget);
      expect(find.textContaining('独立开发'), findsOneWidget);
      expect(find.textContaining('v1.0.0'), findsOneWidget);
    });
  });
}

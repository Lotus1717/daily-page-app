import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/models/book_pick_strategy.dart';
import 'package:daily_page/screens/history_page.dart';
import 'package:daily_page/screens/profile_page.dart';

import 'test_helpers.dart';

Future<void> scrollToWeReadSection(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('保存 Cookie'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await initTestEnvironment();
  });

  group('ProfilePage interactions', () {
    testWidgets('saves valid cookie and shows connected state', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();
      await scrollToWeReadSection(tester);

      expect(find.text('未连接'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'wr_vid=123456; wr_skey=abcDEF',
      );
      await tester.tap(find.widgetWithText(FilledButton, '保存 Cookie'));
      await tester.pumpAndSettle();

      expect(find.text('已连接'), findsOneWidget);
      expect(find.text('已保存字段：wr_vid、wr_skey'), findsOneWidget);
      expect(
        find.text('Cookie 已保存（字段：wr_vid、wr_skey）'),
        findsOneWidget,
      );
    });

    testWidgets('saves cookie with wr_rt and shows all saved keys', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();
      await scrollToWeReadSection(tester);

      await tester.enterText(
        find.byType(TextField),
        'wr_vid=1; wr_skey=2; wr_rt=token',
      );
      await tester.tap(find.widgetWithText(FilledButton, '保存 Cookie'));
      await tester.pumpAndSettle();

      expect(find.text('已保存字段：wr_vid、wr_skey、wr_rt'), findsOneWidget);
    });

    testWidgets('history button navigates to HistoryPage', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('历史记录'));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryPage), findsOneWidget);
      expect(find.textContaining('还没有记录'), findsOneWidget);
    });

    testWidgets('strategy radio switches pick mode', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();

      expect(services.configSvc.strategy, BookPickStrategy.roundRobin);

      await tester.tap(find.text('随机'));
      await tester.pumpAndSettle();

      expect(services.configSvc.strategy, BookPickStrategy.random);

      await tester.scrollUntilVisible(
        find.text('手动指定'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('手动指定'));
      await tester.pumpAndSettle();

      expect(services.configSvc.strategy, BookPickStrategy.manual);
    });

    testWidgets('invalid cookie shows validation snackbar', (tester) async {
      final services = await createTestServices();

      await tester.pumpWidget(services.wrap(const ProfilePage()));
      await tester.pumpAndSettle();
      await scrollToWeReadSection(tester);

      await tester.enterText(
        find.byType(TextField),
        'wr_vid=only',
      );
      await tester.tap(find.widgetWithText(FilledButton, '保存 Cookie'));
      await tester.pumpAndSettle();

      expect(find.text('未连接'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('缺少 wr_skey'),
        ),
        findsOneWidget,
      );
    });
  });
}

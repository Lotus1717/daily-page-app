import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/screens/home_page.dart';
import 'package:daily_page/screens/profile_page.dart';
import 'package:daily_page/screens/reading_page.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    await initTestEnvironment();
  });

  group('MainShell tab navigation', () {
    testWidgets('switches between 今日 / 在读 / 我', (tester) async {
      final services = await createTestServices();
      await tester.pumpWidget(services.app());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('拾页'), findsOneWidget);

      await tester.tap(find.text('在读'));
      await tester.pumpAndSettle();

      expect(find.byType(ReadingPage), findsOneWidget);
      expect(find.text('全部藏书'), findsOneWidget);

      await tester.tap(find.text('我'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('选书策略'), findsOneWidget);

      await tester.tap(find.text('今日'));
      await tester.pumpAndSettle();

      expect(find.text('拾页'), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('preserves tab state in IndexedStack', (tester) async {
      final services = await createTestServices();
      await tester.pumpWidget(services.app());
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('在读'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, '书名'),
        '持久化测试',
      );
      await tester.tap(find.widgetWithText(FilledButton, '添加'));
      await settleDialogClose(tester);

      await tester.tap(find.text('今日'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('在读'));
      await tester.pumpAndSettle();

      expect(find.text('持久化测试'), findsOneWidget);
    });
  });
}

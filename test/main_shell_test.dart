import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/models/daily_page_reading.dart';
import 'package:daily_page/screens/home_page.dart';
import 'package:daily_page/screens/profile_page.dart';
import 'package:daily_page/screens/reading_page.dart';
import 'package:daily_page/services/daily_page_client.dart';

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

    testWidgets('returning to 今日 after addToReading shows 再读一页 not 换一本',
        (tester) async {
      final client = FakeDailyPageClient(
        results: [
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '随机探索书',
              author: '作者',
              content: '探索内容',
              sourceNote: '',
              date: DateTime.now(),
            ),
          ),
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '在读书目',
              author: '作者',
              content: '在读书摘录',
              sourceNote: '第五章',
              date: DateTime.now(),
            ),
          ),
        ],
      );
      final services = await createTestServices(
        pageClient: client,
        preloadPage: true,
      );

      await tester.pumpWidget(services.app());
      await tester.pumpAndSettle();

      expect(find.text('换一本'), findsOneWidget);
      expect(find.text('再读一页'), findsNothing);

      await tester.tap(find.text('在读'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '书名'),
        '在读书目',
      );
      await tester.tap(find.widgetWithText(FilledButton, '添加'));
      await settleDialogClose(tester);

      expect(find.text('在读书 1 / 3'), findsOneWidget);

      await tester.tap(find.text('今日'));
      await tester.pumpAndSettle();

      expect(find.text('换一本'), findsNothing);
      expect(find.text('再读一页'), findsOneWidget);
      expect(find.text('在读书目'), findsOneWidget);
      expect(find.text('在读书摘录'), findsOneWidget);
      expect(client.lastBook?.title, '在读书目');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:daily_page/models/daily_page_reading.dart';
import 'package:daily_page/screens/home_page.dart';
import 'package:daily_page/services/daily_page_client.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    await initTestEnvironment();
  });

  group('HomePage interactions', () {
    testWidgets('refresh button triggers page reload', (tester) async {
      final client = FakeDailyPageClient(
        results: [
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '第一本书',
              author: '作者',
              content: '第一页',
              sourceNote: '',
              date: DateTime.now(),
            ),
          ),
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '第二本书',
              author: '作者',
              content: '第二页',
              sourceNote: '',
              date: DateTime.now(),
            ),
          ),
        ],
      );
      final services = await createTestServices(
        pageClient: client,
        withCookie: true,
        withReadingBook: true,
        preloadPage: true,
      );

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('第一本书'), findsOneWidget);
      expect(client.fetchCount, 1);

      await tester.tap(find.byTooltip('刷新'));
      await tester.pumpAndSettle();

      expect(client.fetchCount, 2);
      expect(find.text('第二本书'), findsOneWidget);
    });

    testWidgets('换一本 triggers discovery switch', (tester) async {
      final client = FakeDailyPageClient();
      final services = await createTestServices(
        pageClient: client,
        preloadPage: true,
      );

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(services.pageSvc.discoveryMode, isTrue);
      expect(find.text('换一本'), findsOneWidget);

      await tester.tap(find.text('换一本'));
      await tester.pumpAndSettle();

      expect(client.fetchCount, 2);
      expect(client.lastNonce, greaterThan(0));
    });

    testWidgets('saves reflection via 记下来 button', (tester) async {
      final services = await createTestServices(preloadPage: true);

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('写一句感想'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        '今天读到了一句触动的话',
      );
      await tester.tap(find.widgetWithText(FilledButton, '记下来'));
      await tester.pumpAndSettle();

      expect(find.text('已记录'), findsOneWidget);
      expect(find.text('今天读到了一句触动的话'), findsOneWidget);

      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '测试书')?.reflection,
        '今天读到了一句触动的话',
      );
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '测试书')?.bookTitle,
        '测试书',
      );
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '测试书')?.sourceNote,
        '节选',
      );
    });

    testWidgets('edit icon opens sheet and updates reflection', (tester) async {
      final services = await createTestServices(preloadPage: true);
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await services.entrySvc.save(dateKey, '原始感想');

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('原始感想'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('编辑感想'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '更新后的感想');
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();

      expect(find.text('更新后的感想'), findsOneWidget);
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '测试书')?.reflection,
        '更新后的感想',
      );
    });

    testWidgets('换一本 after reflection shows new input', (tester) async {
      final client = FakeDailyPageClient(
        results: [
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '第一本书',
              author: '作者',
              content: '第一页内容',
              sourceNote: '',
              date: DateTime.now(),
            ),
          ),
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '第二本书',
              author: '作者',
              content: '第二页内容',
              sourceNote: '',
              date: DateTime.now(),
            ),
          ),
        ],
      );
      final services = await createTestServices(
        pageClient: client,
        preloadPage: true,
      );

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '第一本感想');
      await tester.tap(find.widgetWithText(FilledButton, '记下来'));
      await tester.pumpAndSettle();

      expect(find.text('已记录'), findsOneWidget);
      expect(find.text('写一句感想'), findsNothing);

      await tester.tap(find.text('换一本'));
      await tester.pumpAndSettle();

      expect(find.text('第二本书'), findsOneWidget);
      expect(find.text('写一句感想'), findsOneWidget);
      expect(find.text('已记录'), findsNothing);

      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '第一本书')?.reflection,
        '第一本感想',
      );
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '第二本书'),
        isNull,
      );
    });

    testWidgets('retry button on error card reloads page', (tester) async {
      final client = FakeDailyPageClient(error: Exception('network'));
      final services = await createTestServices(pageClient: client);
      await services.pageSvc.refresh();
      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);

      client.error = null;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      expect(find.text('测试书'), findsOneWidget);
    });
  });
}

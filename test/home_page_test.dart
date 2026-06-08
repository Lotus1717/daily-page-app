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
    testWidgets('换一页 reloads excerpt with nonce', (tester) async {
      final client = FakeDailyPageClient(
        results: [
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '在读书目',
              author: '作者',
              content: '第一页',
              sourceNote: '',
              date: DateTime.now(),
            ),
          ),
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '在读书目',
              author: '作者',
              content: '第二段',
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

      expect(find.text('第一页'), findsOneWidget);
      expect(client.fetchCount, 1);

      await tester.tap(find.text('换一页'));
      await tester.pumpAndSettle();

      expect(client.fetchCount, 2);
      expect(client.lastNonce, greaterThan(0));
      expect(client.lastBook?.title, '在读书目');
      expect(find.text('第二段'), findsOneWidget);
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

    testWidgets('discovery mode shows 随机探索 and 换一本', (tester) async {
      final services = await createTestServices(preloadPage: true);

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(services.pageSvc.discoveryMode, isTrue);
      expect(find.text('随机探索'), findsOneWidget);
      expect(find.text('换一本'), findsOneWidget);
      expect(find.text('换一页'), findsOneWidget);
    });

    testWidgets('normal mode shows 在读书 label and 换一页 link',
        (tester) async {
      final services = await createTestServices(
        withReadingBook: true,
        withCookie: true,
        preloadPage: true,
      );

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(services.pageSvc.discoveryMode, isFalse);
      expect(services.shelfSvc.readingBooks.length, 1);
      expect(find.text('在读书'), findsOneWidget);
      expect(find.text('换一页'), findsOneWidget);
      expect(find.text('换一本'), findsNothing);
    });

    testWidgets('single reading book has no AppBar switch action',
        (tester) async {
      final services = await createTestServices(
        withReadingBook: true,
        withCookie: true,
        preloadPage: true,
      );

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('换一本'), findsNothing);
      expect(find.text('换一页'), findsOneWidget);
    });

    testWidgets('manual reading book loads excerpt from that book',
        (tester) async {
      final client = FakeDailyPageClient(
        results: [
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '在读书目',
              author: '作者',
              content: '手动书的摘录内容',
              sourceNote: '第五章',
              date: DateTime.now(),
            ),
          ),
        ],
      );
      final services = await createTestServices(
        pageClient: client,
        withReadingBook: true,
        preloadPage: true,
      );

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('在读书目'), findsOneWidget);
      expect(find.text('手动书的摘录内容'), findsOneWidget);
      expect(client.lastBook?.title, '在读书目');
      expect(services.pageSvc.discoveryMode, isFalse);
    });

    testWidgets('adding reading book shows 换一页 and loads that book',
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
              content: '手动书的摘录',
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

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(services.pageSvc.discoveryMode, isTrue);
      expect(find.text('换一本'), findsOneWidget);
      expect(find.text('换一页'), findsOneWidget);

      await services.shelfSvc.addManual('在读书目', '作者');
      await tester.pumpAndSettle();

      expect(services.pageSvc.discoveryMode, isFalse);
      expect(find.text('换一页'), findsOneWidget);
      expect(find.text('换一本'), findsNothing);

      expect(client.fetchCount, 2);
      expect(client.lastBook?.title, '在读书目');
      expect(find.text('在读书目'), findsOneWidget);
      expect(find.text('手动书的摘录'), findsOneWidget);
    });

    testWidgets('multi-book in-reading shows 换一本 only in AppBar',
        (tester) async {
      final services = await createTestServices(
        withCookie: true,
        withReadingBook: true,
        preloadPage: true,
      );
      await services.shelfSvc.addManual('第二本书', '作者');

      await tester.pumpWidget(services.wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(services.shelfSvc.readingBooks.length, 2);
      expect(find.text('换一本'), findsOneWidget);
      expect(find.text('换一页'), findsOneWidget);
    });

    testWidgets('switch book and save both reflections keeps two entries',
        (tester) async {
      final client = FakeDailyPageClient(
        results: [
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '第一本书',
              author: '作者A',
              content: '第一页',
              sourceNote: '第一章',
              date: DateTime.now(),
            ),
          ),
          DailyPageFetchResult(
            reading: DailyPageReading(
              bookTitle: '第二本书',
              author: '作者B',
              content: '第二页',
              sourceNote: '第二章',
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

      await tester.tap(find.text('换一本'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '第二本感想');
      await tester.tap(find.widgetWithText(FilledButton, '记下来'));
      await tester.pumpAndSettle();

      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      expect(services.entrySvc.count, 2);
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '第一本书')?.reflection,
        '第一本感想',
      );
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '第一本书')?.sourceNote,
        '第一章',
      );
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '第二本书')?.reflection,
        '第二本感想',
      );
      expect(
        services.entrySvc.entryFor(dateKey, bookTitle: '第二本书')?.sourceNote,
        '第二章',
      );
    });
  });
}

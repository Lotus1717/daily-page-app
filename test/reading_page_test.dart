import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:daily_page/screens/reading_page.dart';
import 'package:daily_page/services/bookshelf_service.dart';
import 'package:daily_page/services/daily_page_service.dart';
import 'package:daily_page/services/reading_config_service.dart';

import 'test_helpers.dart';

void main() {
  late ReadingConfigService config;
  late BookshelfService shelf;
  late DailyPageService pageSvc;

  setUp(() async {
    await initTestEnvironment();
    config = ReadingConfigService();
    await config.load();
    shelf = BookshelfService(config: config);
    await shelf.load();
    pageSvc = DailyPageService(client: FakeDailyPageClient());
    pageSvc.bindBookshelf(shelf);
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: shelf),
          ChangeNotifierProvider.value(value: pageSvc),
        ],
        child: const ReadingPage(),
      ),
    );
  }

  group('ReadingPage add book dialog', () {
    testWidgets('opens dialog, submits book, shows in list', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.tap(find.text('添加'));
      await tester.pumpAndSettle();

      expect(find.text('手动添加'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, '书名'),
        '测试书名',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '作者（可选）'),
        '测试作者',
      );
      await tester.tap(find.widgetWithText(FilledButton, '添加'));
      await settleDialogClose(tester);

      expect(find.text('测试书名'), findsOneWidget);
      expect(find.text('测试作者'), findsOneWidget);
      expect(shelf.books.any((b) => b.title == '测试书名'), isTrue);
    });

    testWidgets('cancel does not add book', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.tap(find.text('添加'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, '书名'),
        '不应出现',
      );
      await tester.tap(find.text('取消'));
      await settleDialogClose(tester);

      expect(find.text('不应出现'), findsNothing);
      expect(shelf.books, isEmpty);
    });

    testWidgets('dialog close does not crash after submit', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.tap(find.text('添加'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, '书名'),
        '生命周期测试',
      );
      await tester.tap(find.widgetWithText(FilledButton, '添加'));

      await settleDialogClose(tester);

      expect(find.text('生命周期测试'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty title submit keeps dialog open', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.tap(find.text('添加'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '添加'));
      await tester.pump();

      expect(find.text('手动添加'), findsOneWidget);
      expect(shelf.books, isEmpty);

      await tester.tap(find.text('取消'));
      await settleDialogClose(tester);
    });
  });

  group('ReadingPage shelf interactions', () {
    testWidgets('manual add auto-joins reading queue when slots available',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('添加'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '书名'),
        '队列测试书',
      );
      await tester.tap(find.widgetWithText(FilledButton, '添加'));
      await settleDialogClose(tester);

      expect(find.text('在读书 1 / 3'), findsOneWidget);
      expect(shelf.readingBooks.length, 1);
      expect(shelf.readingBooks.first.title, '队列测试书');
    });

    testWidgets('add idle book to reading queue via card button',
        (tester) async {
      for (var i = 0; i < 3; i++) {
        await shelf.addManual('在读书$i', '作者');
      }
      await shelf.addManual('待加入', '作者');
      await shelf.removeFromReading(shelf.books.first.id);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('在读书 2 / 3'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('待加入'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final idleRow = find.ancestor(
        of: find.text('待加入'),
        matching: find.byType(Row),
      ).first;
      await tester.tap(
        find.descendant(
          of: idleRow,
          matching: find.byIcon(Icons.add_circle_outline),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('在读书 3 / 3'), findsOneWidget);
      expect(
        shelf.readingBooks.any((b) => b.title == '待加入'),
        isTrue,
      );
    });

    testWidgets('remove from reading queue via card button', (tester) async {
      await shelf.addManual('待移除', '作者');
      await shelf.addToReading(shelf.books.first.id);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('在读书 1 / 3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      expect(shelf.readingBooks, isEmpty);
      expect(find.text('在读书 0 / 3'), findsOneWidget);
    });
  });
}

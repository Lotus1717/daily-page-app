import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_page/screens/reading_page.dart';
import 'package:daily_page/services/bookshelf_service.dart';
import 'package:daily_page/services/reading_config_service.dart';

void main() {
  late ReadingConfigService config;
  late BookshelfService shelf;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    config = ReadingConfigService();
    await config.load();
    shelf = BookshelfService(config: config);
    await shelf.load();
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: ChangeNotifierProvider.value(
        value: shelf,
        child: const ReadingPage(),
      ),
    );
  }

  /// _AddBookDialog 延迟 350ms 释放 controller，测试结束前需推进时钟
  Future<void> settleDialogClose(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 350));
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
}

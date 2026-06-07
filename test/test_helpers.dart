import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_page/main.dart';
import 'package:daily_page/models/daily_page_reading.dart';
import 'package:daily_page/models/shelf_book.dart';
import 'package:daily_page/services/bookshelf_service.dart';
import 'package:daily_page/services/daily_page_client.dart';
import 'package:daily_page/services/daily_page_service.dart';
import 'package:daily_page/services/page_entry_service.dart';
import 'package:daily_page/services/reading_config_service.dart';
import 'package:daily_page/services/reflection_prompt_service.dart';

/// 可控的 DailyPageClient，避免 widget 测试走真实网络
class FakeDailyPageClient extends DailyPageClient {
  FakeDailyPageClient({
    this.results = const [],
    this.error,
  });

  final List<DailyPageFetchResult> results;
  Object? error;
  int fetchCount = 0;
  int lastNonce = -1;
  ShelfBook? lastBook;

  DailyPageFetchResult get _defaultResult => DailyPageFetchResult(
        reading: DailyPageReading(
          bookTitle: '测试书',
          author: '测试作者',
          content: '今日这一页的内容。',
          sourceNote: '节选',
          date: DateTime.now(),
        ),
      );

  @override
  Future<DailyPageFetchResult> fetchWithMeta({
    required String deviceId,
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    fetchCount++;
    lastNonce = nonce;
    lastBook = book;
    if (error != null) throw error!;
    if (results.isEmpty) return _defaultResult;
    return results[(fetchCount - 1).clamp(0, results.length - 1)];
  }
}

class TestServices {
  TestServices({
    required this.configSvc,
    required this.pageSvc,
    required this.entrySvc,
    required this.shelfSvc,
    required this.promptSvc,
    required this.pageClient,
  });

  final ReadingConfigService configSvc;
  final DailyPageService pageSvc;
  final PageEntryService entrySvc;
  final BookshelfService shelfSvc;
  final ReflectionPromptService promptSvc;
  final FakeDailyPageClient pageClient;

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pageSvc),
        ChangeNotifierProvider.value(value: entrySvc),
        ChangeNotifierProvider.value(value: shelfSvc),
        ChangeNotifierProvider.value(value: promptSvc),
      ],
      child: MaterialApp(home: child),
    );
  }

  Widget app({Widget? home}) {
    return DailyPageApp(
      pageSvc: pageSvc,
      entrySvc: entrySvc,
      shelfSvc: shelfSvc,
      promptSvc: promptSvc,
    );
  }
}

bool _dateFormattingReady = false;

Future<void> initTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  if (!_dateFormattingReady) {
    await initializeDateFormatting('zh_CN');
    _dateFormattingReady = true;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

Future<TestServices> createTestServices({
  FakeDailyPageClient? pageClient,
  bool withCookie = false,
  bool withReadingBook = false,
  bool preloadPage = false,
}) async {
  final client = pageClient ?? FakeDailyPageClient();
  final configSvc = ReadingConfigService();
  await configSvc.load();

  final entrySvc = PageEntryService();
  await entrySvc.load();

  final shelfSvc = BookshelfService(config: configSvc);
  await shelfSvc.load();

  if (withCookie) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weread_cookie', 'wr_vid=123456; wr_skey=abcDEF');
  }

  if (withReadingBook) {
    await shelfSvc.addManual('在读书目', '作者');
    await shelfSvc.addToReading(shelfSvc.books.first.id);
  }

  final pageSvc = DailyPageService(client: client);
  pageSvc.bindBookshelf(shelfSvc);

  if (preloadPage) {
    await pageSvc.refresh();
  }

  return TestServices(
    configSvc: configSvc,
    pageSvc: pageSvc,
    entrySvc: entrySvc,
    shelfSvc: shelfSvc,
    promptSvc: ReflectionPromptService(),
    pageClient: client,
  );
}

/// _AddBookDialog 延迟 350ms 释放 controller
Future<void> settleDialogClose(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 350));
}

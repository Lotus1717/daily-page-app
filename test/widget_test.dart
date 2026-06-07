import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_page/main.dart';
import 'package:daily_page/screens/main_shell.dart';
import 'package:daily_page/services/bookshelf_service.dart';
import 'package:daily_page/services/daily_page_service.dart';
import 'package:daily_page/services/page_entry_service.dart';
import 'package:daily_page/services/reading_config_service.dart';
import 'package:daily_page/services/reflection_prompt_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('zh_CN');
  });

  testWidgets('App launches with 3-tab navigation', (tester) async {
    final configSvc = ReadingConfigService();
    await configSvc.load();
    final pageSvc = DailyPageService();
    final entrySvc = PageEntryService();
    final shelfSvc = BookshelfService(config: configSvc);
    final promptSvc = ReflectionPromptService();
    pageSvc.bindBookshelf(shelfSvc);
    // 测试中不触发异步 refresh，避免 pump 挂起

    await tester.pumpWidget(
      DailyPageApp(
        pageSvc: pageSvc,
        entrySvc: entrySvc,
        shelfSvc: shelfSvc,
        configSvc: configSvc,
        promptSvc: promptSvc,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('拾页'), findsOneWidget);
    expect(find.text('在读'), findsOneWidget);
    expect(find.text('我'), findsOneWidget);
    expect(find.byType(MainShell), findsOneWidget);
  });
}

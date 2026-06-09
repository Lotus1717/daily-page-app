import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/app_branding.dart';
import 'config/theme.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_page.dart';
import 'services/bookshelf_service.dart';
import 'services/daily_page_service.dart';
import 'services/device_id_store.dart';
import 'services/page_entry_service.dart';
import 'services/reading_config_service.dart';
import 'services/reflection_prompt_service.dart';
import 'services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');

  final configSvc = ReadingConfigService();
  await configSvc.load();

  final pageSvc = DailyPageService();
  final entrySvc = PageEntryService();
  final shelfSvc = BookshelfService(config: configSvc);
  final promptSvc = ReflectionPromptService();
  final reminderSvc = ReminderService();
  final deviceId = await DeviceIdStore.getOrCreate();

  await entrySvc.load();
  await shelfSvc.load();
  await reminderSvc.init();
  await reminderSvc.syncSchedule(entrySvc);
  pageSvc.bindBookshelf(shelfSvc);
  pageSvc.init(deviceId);

  runApp(DailyPageApp(
    pageSvc: pageSvc,
    entrySvc: entrySvc,
    shelfSvc: shelfSvc,
    configSvc: configSvc,
    promptSvc: promptSvc,
    reminderSvc: reminderSvc,
    firstLaunch: await OnboardingPage.isFirstLaunch(),
  ));
}

class DailyPageApp extends StatelessWidget {
  const DailyPageApp({
    super.key,
    required this.pageSvc,
    required this.entrySvc,
    required this.shelfSvc,
    required this.configSvc,
    required this.promptSvc,
    required this.reminderSvc,
    required this.firstLaunch,
  });

  final DailyPageService pageSvc;
  final PageEntryService entrySvc;
  final BookshelfService shelfSvc;
  final ReadingConfigService configSvc;
  final ReflectionPromptService promptSvc;
  final ReminderService reminderSvc;
  final bool firstLaunch;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pageSvc),
        ChangeNotifierProvider.value(value: entrySvc),
        ChangeNotifierProvider.value(value: shelfSvc),
        ChangeNotifierProvider.value(value: configSvc),
        ChangeNotifierProvider.value(value: promptSvc),
        ChangeNotifierProvider.value(value: reminderSvc),
      ],
      child: MaterialApp(
        title: AppBranding.name,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: firstLaunch ? '/onboarding' : '/home',
        routes: {
          '/onboarding': (context) => const OnboardingPage(),
          '/home': (context) => const MainShell(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/screens/onboarding_page.dart';

import 'test_helpers.dart';

const _homeMarker = 'ONBOARDING_HOME';

Widget _onboardingApp({bool firstLaunch = true}) {
  return MaterialApp(
    initialRoute: firstLaunch ? '/onboarding' : '/home',
    routes: {
      '/onboarding': (_) => const OnboardingPage(),
      '/home': (_) => const Scaffold(body: Text(_homeMarker)),
    },
  );
}

void main() {
  setUp(() async {
    await initTestEnvironment();
  });

  group('OnboardingPage.isFirstLaunch', () {
    test('returns true when onboarding_seen is absent', () async {
      expect(await OnboardingPage.isFirstLaunch(), isTrue);
    });

    test('returns false after markSeen', () async {
      await OnboardingPage.markSeen();
      expect(await OnboardingPage.isFirstLaunch(), isFalse);
    });
  });

  group('OnboardingPage UI', () {
    testWidgets('shows first card and skip enters home', (tester) async {
      await tester.pumpWidget(_onboardingApp());
      await tester.pumpAndSettle();

      expect(find.text('每天拾一页'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);

      await tester.tap(find.text('跳过'));
      await tester.pumpAndSettle();

      expect(find.text(_homeMarker), findsOneWidget);
      expect(await OnboardingPage.isFirstLaunch(), isFalse);
    });

    testWidgets('third page says 开始使用 and finishes', (tester) async {
      await tester.pumpWidget(_onboardingApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      expect(find.text('从你的书开始'), findsOneWidget);
      expect(find.text('手动添加藏书'), findsOneWidget);
      expect(find.textContaining('导入文件'), findsNothing);
      expect(find.text('开始使用'), findsOneWidget);

      await tester.tap(find.text('开始使用'));
      await tester.pumpAndSettle();

      expect(find.text(_homeMarker), findsOneWidget);
    });

    testWidgets('does not show onboarding after markSeen', (tester) async {
      await OnboardingPage.markSeen();

      await tester.pumpWidget(_onboardingApp(firstLaunch: false));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.text(_homeMarker), findsOneWidget);
    });
  });
}

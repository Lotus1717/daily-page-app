import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/widgets/reflection_view.dart';

void main() {
  group('ReflectionView', () {
    testWidgets('displays reflection and edit affordance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReflectionView(
              reflection: '一段已保存的感想',
              onEdit: _noop,
            ),
          ),
        ),
      );

      expect(find.text('已记录'), findsOneWidget);
      expect(find.text('一段已保存的感想'), findsOneWidget);
      expect(find.byTooltip('编辑感想'), findsOneWidget);
    });

    testWidgets('edit button invokes callback', (tester) async {
      var edited = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReflectionView(
              reflection: '可编辑',
              onEdit: () => edited = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('编辑感想'));
      await tester.pumpAndSettle();

      expect(edited, isTrue);
    });

    testWidgets('hides edit when onEdit is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReflectionView(reflection: '只读感想'),
          ),
        ),
      );

      expect(find.text('只读感想'), findsOneWidget);
      expect(find.byTooltip('编辑感想'), findsNothing);
    });
  });
}

void _noop() {}

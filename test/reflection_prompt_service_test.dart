import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:daily_page/services/reflection_prompt_service.dart';

void main() {
  group('ReflectionPromptService', () {
    test('fetchQuestion returns question from server', () async {
      final service = ReflectionPromptService(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['book_title'], '三体');
          expect(body['content'], '摘录内容');
          return http.Response(jsonEncode({'question': '  What does this remind you of?  '}), 200);
        }),
      );

      final q = await service.fetchQuestion(
        deviceId: 'dev-1',
        bookTitle: '三体',
        content: '摘录内容',
      );

      expect(q, 'What does this remind you of?');
      expect(service.question, 'What does this remind you of?');
      expect(service.loading, isFalse);
    });

    test('fetchQuestion returns null on HTTP error', () async {
      final service = ReflectionPromptService(
        httpClient: MockClient((request) async {
          return http.Response('error', 500);
        }),
      );

      final q = await service.fetchQuestion(
        deviceId: 'dev-1',
        bookTitle: '三体',
        content: '内容',
      );

      expect(q, isNull);
      expect(service.question, isNull);
      expect(service.loading, isFalse);
    });

    test('reset clears state', () async {
      final service = ReflectionPromptService(
        httpClient: MockClient((request) async {
          return http.Response(jsonEncode({'question': 'A question?'}), 200);
        }),
      );

      await service.fetchQuestion(
        deviceId: 'dev-1',
        bookTitle: '书',
        content: '内容',
      );
      service.reset();

      expect(service.question, isNull);
      expect(service.loading, isFalse);
    });
  });
}

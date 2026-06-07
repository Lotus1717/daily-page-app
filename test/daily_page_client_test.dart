import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:daily_page/models/shelf_book.dart';
import 'package:daily_page/services/daily_page_client.dart';

void main() {
  const sampleJson = {
    'book_title': 'Sapiens',
    'author': 'Harari',
    'content': 'An excerpt',
    'source_note': 'ch3',
    'date': '2026-06-07',
  };

  group('DailyPageClient', () {
    test('fetchWithMeta parses successful response', () async {
      final client = DailyPageClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['device_id'], 'test-device');
          expect(body['book_title'], '三体');
          expect(body['book_author'], '刘慈欣');
          return http.Response(jsonEncode(sampleJson), 200);
        }),
      );

      final result = await client.fetchWithMeta(
        deviceId: 'test-device',
        book: const ShelfBook(id: 'b1', title: '三体', author: '刘慈欣'),
      );

      expect(result.reading.bookTitle, 'Sapiens');
      expect(result.reading.content, 'An excerpt');
      expect(result.pickedBook?.title, '三体');
    });

    test('fetchWithMeta builds discovery book when no book passed', () async {
      final client = DailyPageClient(
        httpClient: MockClient((request) async {
          return http.Response(jsonEncode(sampleJson), 200);
        }),
      );

      final result = await client.fetchWithMeta(deviceId: 'dev-1');

      expect(result.pickedBook?.title, 'Sapiens');
      expect(result.pickedBook?.author, 'Harari');
    });

    test('throws on non-200 with detail from JSON body', () async {
      final client = DailyPageClient(
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'quota exceeded'}),
            429,
          );
        }),
      );

      expect(
        () => client.fetchWithMeta(deviceId: 'dev-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('HTTP 429'),
          ),
        ),
      );
    });

    test('includes weread_cookie when provided', () async {
      final client = DailyPageClient(
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['weread_cookie'], 'sid=abc');
          return http.Response(jsonEncode(sampleJson), 200);
        }),
      );

      await client.fetchWithMeta(
        deviceId: 'dev-1',
        wereadCookie: 'sid=abc',
      );
    });
  });
}

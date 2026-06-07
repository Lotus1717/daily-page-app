import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_page/services/weread_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('syncShelf rejects cookie without wr_skey before network', () async {
    final service = WeReadService(httpClient: MockClient((_) async {
      throw StateError('should not call API');
    }));

    expect(
      () => service.syncShelf('wr_vid=123456'),
      throwsA(
        predicate(
          (e) =>
              e is Exception &&
              e.toString().contains('wr_skey'),
        ),
      ),
    );
  });

  test('syncShelf parses FastAPI detail string', () async {
    final service = WeReadService(
      httpClient: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'detail': 'Cookie 已过期'})),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    expect(
      () => service.syncShelf('wr_vid=1; wr_skey=2'),
      throwsA(
        predicate(
          (e) =>
              e is Exception &&
              e.toString().contains('Cookie 已过期'),
        ),
      ),
    );
  });

  test('syncShelf preserves extra cookie keys in request', () async {
    final service = WeReadService(
      httpClient: MockClient(
        (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(
            body['cookie'],
            'wr_vid=1; wr_skey=2; wr_rt=token',
          );
          return http.Response.bytes(
            utf8.encode(jsonEncode({'books': [], 'count': 0})),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        },
      ),
    );

    await service.syncShelf('wr_rt=token; wr_vid=1; wr_skey=2');
  });

  test('syncShelf maps connection refused to friendly message', () async {
    final service = WeReadService(
      httpClient: MockClient((_) async {
        throw http.ClientException(
          'Connection refused',
          Uri.parse('http://175.178.249.107/v1/weread/sync'),
        );
      }),
    );

    expect(
      () => service.syncShelf('wr_vid=1; wr_skey=2'),
      throwsA(
        predicate(
          (e) =>
              e is Exception &&
              e.toString().contains('无法连接服务器'),
        ),
      ),
    );
  });

  test('syncShelf returns books on success', () async {
    final service = WeReadService(
      httpClient: MockClient(
        (request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['cookie'], 'wr_vid=1; wr_skey=2');
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'books': [
                {
                  'book_id': '42',
                  'title': '测试书',
                  'author': '作者',
                },
              ],
              'count': 1,
            })),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        },
      ),
    );

    final result = await service.syncShelf('wr_vid=1; wr_skey=2');
    expect(result.count, 1);
    expect(result.books.first.title, '测试书');
  });
}

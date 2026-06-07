import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/server_config.dart';
import '../models/shelf_book.dart';
import 'weread_config_store.dart';

class WeReadSyncResult {
  const WeReadSyncResult({required this.books, required this.count});
  final List<ShelfBook> books;
  final int count;
}

/// 通过服务端代理同步微信读书书架（规避 Web CORS）
class WeReadService {
  WeReadService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<WeReadSyncResult> syncShelf(String cookie) async {
    final uri = Uri.parse('${ServerConfig.baseUrl}${ServerConfig.wereadSyncPath}');
    final response = await _http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'cookie': cookie.trim()}),
        )
        .timeout(Duration(seconds: ServerConfig.timeoutSeconds));

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        detail = json['detail']?.toString() ?? detail;
      } catch (_) {}
      throw Exception(detail);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final booksRaw = json['books'] as List<dynamic>? ?? [];
    final books = booksRaw
        .map((e) => ShelfBook.fromWeRead(e as Map<String, dynamic>))
        .toList();

    await WeReadConfigStore.saveCookie(cookie.trim());
    return WeReadSyncResult(books: books, count: json['count'] as int? ?? books.length);
  }
}

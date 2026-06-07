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
    final validation = WeReadConfigStore.validate(cookie);
    if (!validation.isValid) {
      throw Exception(validation.error);
    }
    final normalized = validation.normalized!;

    final uri = Uri.parse('${ServerConfig.baseUrl}${ServerConfig.wereadSyncPath}');
    final response = await _http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'cookie': normalized}),
        )
        .timeout(Duration(seconds: ServerConfig.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception(_parseApiError(response.statusCode, response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final booksRaw = json['books'] as List<dynamic>? ?? [];
    final books = booksRaw
        .map((e) => ShelfBook.fromWeRead(e as Map<String, dynamic>))
        .toList();

    await WeReadConfigStore.saveCookie(normalized);
    return WeReadSyncResult(books: books, count: json['count'] as int? ?? books.length);
  }

  static String _parseApiError(int statusCode, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final detail = json['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List) {
          final parts = detail
              .map((e) {
                if (e is Map && e['msg'] != null) return e['msg'].toString();
                return e.toString();
              })
              .where((s) => s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) return parts.join('；');
        }
      }
    } catch (_) {}
    if (statusCode == 404) {
      return '同步接口未部署（404），请联系管理员更新服务端';
    }
    return '同步失败（HTTP $statusCode）';
  }
}

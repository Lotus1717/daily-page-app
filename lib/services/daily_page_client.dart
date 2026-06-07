import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/server_config.dart';
import '../models/daily_page_reading.dart';
import '../models/shelf_book.dart';

/// 每日一页 — 仅走服务端真实数据
class DailyPageClient {
  DailyPageClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<DailyPageFetchResult> fetchWithMeta({
    required String deviceId,
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    final reading = await _fetchFromServer(
      deviceId,
      book: book,
      wereadCookie: wereadCookie,
      nonce: nonce,
    );
    return DailyPageFetchResult(
      reading: reading,
      pickedBook: book ?? _bookFromReading(reading),
    );
  }

  ShelfBook _bookFromReading(DailyPageReading reading) {
    return ShelfBook(
      id: 'discovery-${reading.bookTitle.hashCode}',
      title: reading.bookTitle,
      author: reading.author,
    );
  }

  Future<DailyPageReading> _fetchFromServer(
    String deviceId, {
    ShelfBook? book,
    String? wereadCookie,
    int nonce = 0,
  }) async {
    final uri = Uri.parse('${ServerConfig.baseUrl}${ServerConfig.dailyPagePath}');
    final body = <String, dynamic>{
      'device_id': deviceId,
      'nonce': nonce,
    };
    if (book != null) {
      if (book.bookId != null) body['book_id'] = book.bookId;
      body['book_title'] = book.title;
      if (book.author.isNotEmpty) body['book_author'] = book.author;
    }
    if (wereadCookie != null && wereadCookie.isNotEmpty) {
      body['weread_cookie'] = wereadCookie;
    }

    final response = await _http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(Duration(seconds: ServerConfig.timeoutSeconds));

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        detail = json['detail']?.toString() ?? detail;
      } catch (_) {}
      throw Exception('HTTP ${response.statusCode}: $detail');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DailyPageReading.fromJson(json);
  }
}

class DailyPageFetchResult {
  const DailyPageFetchResult({
    required this.reading,
    this.pickedBook,
  });

  final DailyPageReading reading;
  final ShelfBook? pickedBook;
}

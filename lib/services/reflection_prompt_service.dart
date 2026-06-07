import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/server_config.dart';

/// AI 辅助提问 — 服务端 DeepSeek 生成
class ReflectionPromptService extends ChangeNotifier {
  ReflectionPromptService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  String? _question;
  bool _loading = false;

  String? get question => _question;
  bool get loading => _loading;

  Future<String?> fetchQuestion({
    required String deviceId,
    required String bookTitle,
    required String content,
  }) async {
    _loading = true;
    _question = null;
    notifyListeners();

    try {
      _question = await _fetchFromServer(
        deviceId: deviceId,
        bookTitle: bookTitle,
        content: content,
      );
    } catch (e) {
      debugPrint('ReflectionPrompt failed: $e');
      _question = null;
    }

    _loading = false;
    notifyListeners();
    return _question;
  }

  Future<String> _fetchFromServer({
    required String deviceId,
    required String bookTitle,
    required String content,
  }) async {
    final uri =
        Uri.parse('${ServerConfig.baseUrl}${ServerConfig.reflectionPromptPath}');
    final response = await _http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'device_id': deviceId,
            'book_title': bookTitle,
            'content': content,
          }),
        )
        .timeout(Duration(seconds: ServerConfig.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final q = json['question'] as String?;
    if (q == null || q.trim().isEmpty) {
      throw Exception('empty question');
    }
    return q.trim();
  }

  void reset() {
    _question = null;
    _loading = false;
    notifyListeners();
  }
}

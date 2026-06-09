import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_branding.dart';
import '../models/community_config.dart';

/// 拉取书友会远程配置（GitHub Pages community.json）
class CommunityService {
  CommunityService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  CommunityConfig? _cached;

  CommunityConfig get fallback => CommunityConfig.fallback;

  Future<CommunityConfig> fetchConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    try {
      final response = await _client
          .get(Uri.parse(AppBranding.communityConfigUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('CommunityService: HTTP ${response.statusCode}');
        return _cacheOrFallback();
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final config = CommunityConfig.fromJson(json);
      if (!config.enabled) return _cacheOrFallback();
      _cached = config.qrImageUrl.isNotEmpty ? config : fallback;
      return _cached!;
    } catch (e) {
      debugPrint('CommunityService fetch failed: $e');
      return _cacheOrFallback();
    }
  }

  CommunityConfig _cacheOrFallback() {
    _cached ??= fallback;
    return _cached!;
  }
}

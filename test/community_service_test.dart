import 'package:flutter_test/flutter_test.dart';

import 'package:daily_page/models/community_config.dart';
import 'package:daily_page/services/community_service.dart';

void main() {
  group('CommunityConfig', () {
    test('fromJson parses full config', () {
      final config = CommunityConfig.fromJson({
        'enabled': true,
        'title': '测试书友会',
        'subtitle': '副标题',
        'qr_image_url': 'https://example.com/qr.png',
        'highlights': ['话题 A', '话题 B'],
        'hint': '扫码加入',
      });

      expect(config.enabled, isTrue);
      expect(config.title, '测试书友会');
      expect(config.qrImageUrl, 'https://example.com/qr.png');
      expect(config.highlights, ['话题 A', '话题 B']);
      expect(config.hint, '扫码加入');
    });

    test('fromJson uses defaults for missing fields', () {
      final config = CommunityConfig.fromJson({});

      expect(config.enabled, isTrue);
      expect(config.title, '拾页 · 书友会');
      expect(config.qrImageUrl, isEmpty);
    });
  });

  group('CommunityService', () {
    test('fallback has safe defaults', () {
      final service = CommunityService();
      expect(service.fallback.enabled, isTrue);
      expect(service.fallback.highlights, isNotEmpty);
    });
  });
}

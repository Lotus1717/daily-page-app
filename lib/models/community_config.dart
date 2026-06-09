/// 书友会远程配置（GitHub Pages community.json）
class CommunityConfig {
  const CommunityConfig({
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.qrImageUrl,
    this.highlights = const [],
    this.hint,
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final String qrImageUrl;
  final List<String> highlights;
  final String? hint;

  factory CommunityConfig.fromJson(Map<String, dynamic> json) {
    final highlightsRaw = json['highlights'];
    return CommunityConfig(
      enabled: json['enabled'] as bool? ?? true,
      title: json['title'] as String? ?? '拾页 · 书友会',
      subtitle: json['subtitle'] as String? ?? '和书友一起每日读一页',
      qrImageUrl: json['qr_image_url'] as String? ?? '',
      highlights: highlightsRaw is List
          ? highlightsRaw.map((e) => e.toString()).toList()
          : const [],
      hint: json['hint'] as String?,
    );
  }

  static const fallback = CommunityConfig(
    enabled: true,
    title: '拾页 · 书友会',
    subtitle: '和书友一起每日读一页、聊感想',
    qrImageUrl: '',
    highlights: ['每周阅读话题', '共读交流', '可选加入'],
    hint: '截图后打开微信扫一扫加入',
  );
}

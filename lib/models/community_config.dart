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
      title: json['title'] as String? ?? '拾页 · 读书公众号',
      subtitle: json['subtitle'] as String? ?? '安静订阅，分享好书与阅读感悟',
      qrImageUrl: json['qr_image_url'] as String? ?? '',
      highlights: highlightsRaw is List
          ? highlightsRaw.map((e) => e.toString()).toList()
          : const [],
      hint: json['hint'] as String?,
    );
  }

  static const fallback = CommunityConfig(
    enabled: true,
    title: '拾页 · 读书公众号',
    subtitle: '安静订阅，分享好书与阅读感悟',
    qrImageUrl: '',
    highlights: ['好书推荐', '阅读感悟', '书摘灵感'],
    hint: '截图后微信扫码关注公众号',
  );
}

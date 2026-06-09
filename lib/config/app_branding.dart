/// App 品牌名称、外链与版本（上架前替换占位域名/邮箱）
class AppBranding {
  AppBranding._();

  /// 显示名（主屏幕、AppBar）
  static const String name = '拾页';

  /// 副标题 / Slogan
  static const String tagline = '每天拾一页，写一句就好';

  /// 英文标识（Bundle ID 后缀等，可选）
  static const String slug = 'shiye';

  /// 与 pubspec.yaml version 保持一致
  static const String version = '1.0.0';

  /// 意见反馈邮箱
  static const String feedbackEmail = 'Lotus1717@users.noreply.github.com';

  /// 隐私政策（GitHub Pages）
  static const String privacyPolicyUrl =
      'https://lotus1717.github.io/daily-page-app/privacy.html';
}

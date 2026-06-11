/// 服务端配置 — 与废话预言家共用后端
class ServerConfig {
  ServerConfig._();

  static const String baseUrl = 'https://tanmystudio.site';

  static const String dailyPagePath = '/v1/daily-page';
  static const String reflectionPromptPath = '/v1/reflection-prompt';
  static const int timeoutSeconds = 45;
}

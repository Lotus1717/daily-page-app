/// 服务端配置 — 与废话预言家共用 175.178.249.107
class ServerConfig {
  ServerConfig._();

  static const String baseUrl = 'http://175.178.249.107';

  static const String dailyPagePath = '/v1/daily-page';
  static const String reflectionPromptPath = '/v1/reflection-prompt';
  static const int timeoutSeconds = 45;
}

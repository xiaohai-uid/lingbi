/// 灵笔集成测试配置常量
library integration_test_config;

/// 微服务端口映射：服务名 → 端口
const Map<String, int> kServicePorts = {
  'API Gateway': 8080,
  'AI Provider': 8081,
  'Project': 8082,
  'Document': 8083,
  'Codex': 8084,
  'Export': 8085,
  'Version': 8086,
  'Settings': 8087,
  'Quota': 8088,
  'Storage': 8089,
  'Sync': 8090,
  'Canvas': 8091,
};

/// 基础 URL
const String kBaseUrl = 'http://localhost';

/// 健康检查超时时间
const Duration kHealthTimeout = Duration(seconds: 5);

/// 健康检查轮询间隔
const Duration kHealthInterval = Duration(seconds: 2);

/// 最大重试次数
const int kMaxRetries = 15;

/// UI 操作超时时间
const Duration kUITimeout = Duration(seconds: 10);

/// 获取微服务健康检查 URL
String healthUrl(int port) => '$kBaseUrl:$port/health';

/// 获取微服务 API URL
String apiUrl(int port, [String path = '']) => '$kBaseUrl:$port$path';

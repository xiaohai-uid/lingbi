import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

/// Quality Review 微服务入口
/// 提供文本质量审查 API: 角色一致性/爽点密度/格式审查/综合评分
Future<HttpServer> serve(Handler handler, InternetAddress address, int port) {
  return serve(handler, address, port);
}

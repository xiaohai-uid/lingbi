import 'package:dart_frog/dart_frog.dart';

/// Novel Engine 微服务入口
/// 提供三层生成管线 API: 梗概(Layer1) → 细纲(Layer2) → 正文(Layer3)
Handler serve() {
  return (context) {
    return Response.json(
      body: {'status': 'ok', 'service': 'novel-engine', 'version': 'v1.0'},
    );
  };
}

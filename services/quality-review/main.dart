import 'package:dart_frog/dart_frog.dart';

/// Quality Review 微服务入口
/// 提供文本质量审查 API: 角色一致性/爽点密度/格式审查/综合评分
Handler serve() {
  return (context) {
    return Response.json(
      body: {'status': 'ok', 'service': 'quality-review', 'version': 'v1.0'},
    );
  };
}

import 'package:dart_frog/dart_frog.dart';

/// GET /health — 健康检查
Response onRequest(RequestContext context) {
  return Response.json(body: {
    'status': 'ok',
    'service': 'novel-engine',
    'version': '1.0.0',
  });
}

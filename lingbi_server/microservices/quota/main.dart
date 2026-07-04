import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'lib/quota_service.dart';
import 'routes/status.dart';
import 'routes/consume.dart';
import 'routes/reset.dart';

Future<void> main() async {
  final quotaService = QuotaService(
    dailyLimit: 100,
    storagePath: 'quota_data.json',
  );

  final app = Router()
    ..get('/status', statusHandler(quotaService))
    ..post('/consume', consumeHandler(quotaService))
    ..put('/reset', resetHandler(quotaService));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(contentTypeJson())
      .addHandler(app);

  final server = await shelf_io.serve(handler, '0.0.0.0', 8088);
  print('Quota Service running on http://${server.address.host}:${server.port}');
}

Middleware contentTypeJson() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      return response.change(headers: {'Content-Type': 'application/json'});
    };
  };
}
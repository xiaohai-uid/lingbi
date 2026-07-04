import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../lib/quota_service.dart';

import 'router.g.dart';

class StatusHandler {
  final QuotaService quotaService;

  StatusHandler(this.quotaService);

  Future<Response> get(RouterContext context) async {
    final status = quotaService.getStatus();
    return Response(200, body: jsonEncode(status));
  }
}

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/quota_service.dart';

import 'status.dart';
import 'consume.dart';
import 'reset.dart';
import 'health.dart';

export 'status.dart';
export 'consume.dart';
export 'reset.dart';
export 'health.dart';

/// Build a shelf Router with all quota routes registered.
Router buildRouter(QuotaService quotaService) {
  return Router()
    ..get('/health', healthHandler())
    ..get('/status', statusHandler(quotaService))
    ..post('/consume', consumeHandler(quotaService))
    ..post('/reset', resetHandler(quotaService));
}
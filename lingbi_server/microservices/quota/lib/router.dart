import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/quota_service.dart';
import '../routes/status.dart';
import '../routes/consume.dart';
import '../routes/reset.dart';
import '../routes/health.dart';

export '../lib/quota_service.dart';
export '../routes/status.dart';
export '../routes/consume.dart';
export '../routes/reset.dart';
export '../routes/health.dart';

/// Build a shelf Router with all quota routes registered.
Router buildRouter(QuotaService quotaService) {
  return Router()
    ..get('/health', healthHandler())
    ..get('/status', statusHandler(quotaService))
    ..post('/consume', consumeHandler(quotaService))
    ..post('/reset', resetHandler(quotaService));
}
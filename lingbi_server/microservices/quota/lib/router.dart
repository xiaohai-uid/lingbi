import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/quota_service.dart';
import '../routes/status.dart';
import '../routes/consume.dart';
import '../routes/reset.dart';

export '../lib/quota_service.dart';
export '../routes/status.dart';
export '../routes/consume.dart';
export '../routes/reset.dart';

// Re-export the app
export '../main.dart';

// Handler constructors for dependency injection
StatusHandler statusHandler(QuotaService service) => StatusHandler(service);
ConsumeHandler consumeHandler(QuotaService service) => ConsumeHandler(service);
ResetHandler resetHandler(QuotaService service) => ResetHandler(service);

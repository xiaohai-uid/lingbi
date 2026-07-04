import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:json_annotation/json_annotations.dart';

import '../lib/quota_service.dart';

import 'status.dart';
import 'consume.dart';
import 'reset.dart';

export 'status.dart';
export 'consume.dart';
export 'reset.dart';

// Handler constructors for dependency injection
StatusHandler statusHandler(QuotaService service) => StatusHandler(service);
ConsumeHandler consumeHandler(QuotaService service) => ConsumeHandler(service);
ResetHandler resetHandler(QuotaService service) => ResetHandler(service);

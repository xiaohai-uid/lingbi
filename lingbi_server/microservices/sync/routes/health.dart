import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'lib/sync_service.dart';
import 'main.dart';

/// Health check endpoint for Sync Service
Response onRequest(RequestContext context) async {
  return Response(
    body: jsonEncode({
      'status': 'healthy',
      'service': 'sync',
      'version': '1.0.0',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

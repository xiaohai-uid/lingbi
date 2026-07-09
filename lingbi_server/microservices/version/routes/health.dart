import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

/// Health check endpoint for Version Service
Response onRequest(RequestContext context) async {
  return Response(
    body: jsonEncode({
      'status': 'healthy',
      'service': 'version-history',
      'version': '1.0.0',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

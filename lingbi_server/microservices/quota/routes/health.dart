import 'dart:convert';
import 'package:shelf/shelf.dart';

/// GET /health — Health check endpoint
Handler healthHandler() {
  return (Request request) async {
    return Response.ok(
      jsonEncode({
        'status': 'healthy',
        'service': 'quota',
        'version': '1.0.0',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  };
}

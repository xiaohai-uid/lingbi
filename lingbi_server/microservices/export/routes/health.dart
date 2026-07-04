import 'package:dart_frog/dart_frog.dart';

/// GET /health — Health check endpoint
RequestHandler health(Request request) async {
  return Response(
    body: jsonEncode({
      'status': 'healthy',
      'service': 'export',
      'version': '1.0.0',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
import 'package:dart_frog/dart_frog.dart';

RequestHandler health(Request request) async {
  return Response(
    body: jsonEncode({
      'status': 'healthy',
      'service': 'sync',
      'version': '1.0.0',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
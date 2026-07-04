import 'package:dart_frog/dart_frog.dart';

/// API Gateway entrypoint - responds with a welcome message at root.
Response onRequest(RequestContext context) {
  return Response(
    body: 'Welcome to Lingbi API Gateway!',
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods':
          'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    },
  );
}

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/main.dart';

/// Middleware that initializes shared services and provides CORS support.
Handler middleware(Handler handler) {
  return (context) {
    // Add CORS headers
    final headers = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods':
          'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    };

    // Handle preflight requests
    if (context.request.method.value == 'OPTIONS') {
      return Response(statusCode: 204, headers: headers);
    }

    return handler(context).then((response) => response.copyWith(headers: headers));
  };
}
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:storage/lib/vector_store.dart';
import 'package:storage/main.dart';

/// Health check endpoint for Storage Service
Response onRequest(RequestContext context) async {
  return Response(
    body: jsonEncode({
      'status': 'healthy',
      'service': 'storage',
      'version': '1.0.0',
    }),
    headers: {'Content-Type': 'application/json'},
  );
}

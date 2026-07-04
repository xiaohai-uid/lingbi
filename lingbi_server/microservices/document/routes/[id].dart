import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:document/lib/database_service.dart';
import 'package:document/lib/document.dart';
import 'package:document/main.dart';

/// Handles GET /:id - Gets a single document by ID.
Response onRequest(RequestContext context) async {
  try {
    final id = context.params['id']!;
    final document = databaseService.getById(id);

    if (document == null) {
      return Response(
        statusCode: 404,
        body: jsonEncode({'error': 'Document not found'}),
      );
    }

    return Response(
      body: jsonEncode(document.toJson()),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}

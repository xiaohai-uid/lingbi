import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:version/lib/version_service.dart';
import 'package:version/main.dart';

/// Handles GET /diff/:docId/:v1/:v2 - Get diff between two versions
Response onRequest(RequestContext context, String docId, String v1, String v2) async {
  try {
    if (docId.isEmpty || v1.isEmpty || v2.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Document ID and both version IDs are required'}),
      );
    }

    final diff = versionService.getDiff(docId, v1, v2);

    return Response(
      body: jsonEncode(diff.toJson()),
    );
  } on Exception catch (e) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': e.message}),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'Unexpected error: $e'}),
    );
  }
}

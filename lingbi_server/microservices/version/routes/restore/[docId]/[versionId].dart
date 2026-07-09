import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:version/lib/version_service.dart';
import 'package:version/main.dart';

/// Handles POST /restore/:docId/:versionId — Restore document to a version
Response onRequest(
    RequestContext context, String docId, String versionId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    if (docId.isEmpty || versionId.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Document ID and version ID are required'}),
      );
    }

    final snapshot = versionService.restoreVersion(docId, versionId);

    return Response(
      body: jsonEncode({
        'data': snapshot.toJson(),
        'message': 'Document restored to version ${snapshot.id}',
      }),
    );
  } on Exception catch (e) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': e.toString()}),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'Unexpected error: $e'}),
    );
  }
}

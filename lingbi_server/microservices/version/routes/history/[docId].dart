import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:version/lib/version_service.dart';
import 'package:version/main.dart';

/// Handles GET /history/:docId - Get version history for a document
Response onRequest(RequestContext context, String docId) async {
  try {
    if (docId.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Document ID is required'}),
      );
    }

    final snapshots = versionService.getVersionHistory(docId);

    return Response(
      body: jsonEncode({
        'docId': docId,
        'versions': snapshots.map((s) => s.toJson()).toList(),
        'count': snapshots.length,
      }),
    );
  } on Exception catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.message}),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'Unexpected error: $e'}),
    );
  }
}

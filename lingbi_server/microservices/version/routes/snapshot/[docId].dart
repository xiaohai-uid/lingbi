import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:version/lib/version_service.dart';
import 'package:version/main.dart';

/// Handles POST /snapshot/:docId — Create a new version snapshot
Response onRequest(RequestContext context, String docId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    if (docId.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Document ID is required'}),
      );
    }

    final body = await context.request.jsonDecode() as Map<String, dynamic>;

    if (!body.containsKey('content') || !body.containsKey('author')) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Missing required fields: content, author'}),
      );
    }

    final content = body['content'] as String;
    final author = body['author'] as String;
    final comment = body['comment'] as String?;

    final snapshot = versionService.createSnapshot(
      docId: docId,
      content: content,
      comment: comment,
      author: author,
    );

    return Response(
      statusCode: 201,
      body: jsonEncode({'data': snapshot.toJson()}),
    );
  } on Exception catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': 'Unexpected error: $e'}),
    );
  }
}

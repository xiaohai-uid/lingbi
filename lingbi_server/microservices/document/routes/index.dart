import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:document/lib/database_service.dart';
import 'package:document/lib/document.dart';
import 'package:document/main.dart';

/// Handles POST / - Creates a new document.
Response onRequest(RequestContext context) async {
  try {
    final body = await context.request.json as Map<String, dynamic>;
    final title = body['title'] as String;
    final filePath = body['file_path'] as String;
    final wordCount = body['word_count'] as int? ?? 0;

    if (title.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Title is required'}),
      );
    }

    if (filePath.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'File path is required'}),
      );
    }

    final now = DateTime.now();
    final document = Document(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      filePath: filePath,
      wordCount: wordCount,
      createdAt: now,
      updatedAt: now,
    );

    final created = databaseService.create(document);

    return Response(
      statusCode: 201,
      body: jsonEncode(created.toJson()),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}

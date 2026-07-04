import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/litellm_client.dart';
import 'package:ai_provider/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles POST /embedding - gets embeddings for input text.
Response onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final body = await context.request.json as Map<String, dynamic>;
    final input = body['input'] as String? ?? '';
    final modelId = body['model'] as String? ?? '';

    if (input.isEmpty) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'input is required'}),
      );
    }

    final embeddings = await chatService.getEmbedding(
      text: input,
      modelId: modelId.isNotEmpty ? modelId : null,
    );

    return Response(
      body: jsonEncode({
        'object': 'list',
        'data': [
          {
            'object': 'embedding',
            'index': 0,
            'embedding': embeddings,
          }
        ],
        'model': modelId,
        'usage': {
          'prompt_tokens': -1,
          'total_tokens': -1,
        },
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
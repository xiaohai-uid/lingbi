import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/lib/litellm_client.dart';
import 'package:ai_provider/lib/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles POST /embedding - gets embeddings for input text.
Response onRequest(RequestContext context) async {
  try {
    final body = await context.request.json as Map<String, dynamic>;
    final input = body['input'] as String? ?? '';
    final modelId = body['model'] as String? ?? '';

    final modelConfig = modelId.isNotEmpty
        ? modelConfigService.getModel(modelId)
        : modelConfigService.listModels().firstOrNull;

    if (modelConfig == null) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'No model configured'}),
      );
    }

    final embeddings = await litellmClient.embed(
      model: modelConfig.model,
      input: input,
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
        'model': modelConfig.model,
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
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/litellm_client.dart';
import 'package:ai_provider/model_config.dart';
import 'package:ai_provider/main.dart';

/// Handles GET /health - health check endpoint.
///
/// Returns the service status including model registry state.
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: 405,
      body: jsonEncode({'error': 'Method not allowed'}),
    );
  }

  try {
    final modelCount = modelConfigService.count;
    final activeModel = modelConfigService.activeModelId;
    final enabledModels = modelConfigService.listModels().length;

    return Response(
      body: jsonEncode({
        'status': 'ok',
        'service': 'ai_provider',
        'version': '1.0.0',
        'models': {
          'total': modelCount,
          'enabled': enabledModels,
          'active': activeModel,
        },
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  } catch (e) {
    return Response(
      statusCode: 500,
      body: jsonEncode({
        'status': 'error',
        'error': e.toString(),
      }),
    );
  }
}

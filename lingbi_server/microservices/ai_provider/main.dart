import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/lib/litellm_client.dart';
import 'package:ai_provider/lib/model_config.dart';

/// Global model configuration service, initialized on startup.
late ModelConfigService modelConfigService;

/// Global LiteLLM client, reused across requests.
late LiteLLMClient litellmClient;

void main() async {
  // Load model configurations
  modelConfigService = ModelConfigService();
  await modelConfigService.loadConfigs('config/models.json');

  // Initialize LiteLLM client with the first configured model's base URL
  final firstModel = modelConfigService.listModels().firstOrNull ??
      ModelConfig(
        id: 'default',
        name: 'Default',
        type: 'openai_compatible',
        baseUrl: 'http://localhost:11434',
        apiKey: '',
        model: '',
      );
  litellmClient = LiteLLMClient(
    baseUrl: firstModel.baseUrl,
    headers: firstModel.headers,
  );

  // Start the server
  DartFrog.debugMode = true;
  await serve(serve);
}
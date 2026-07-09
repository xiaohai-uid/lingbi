import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_provider/litellm_client.dart';
import 'package:ai_provider/model_config.dart';
import 'package:ai_provider/services/chat_service.dart';

/// Global model configuration service, initialized on startup.
late ModelConfigService modelConfigService;

/// Global LiteLLM client, reused across requests.
late LiteLLMClient litellmClient;

/// Global chat service with dialog management and context window.
late ChatService chatService;

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

  // Initialize ChatService
  chatService = ChatService(
    client: litellmClient,
    modelConfigService: modelConfigService,
  );

  // Start the server
  DartFrog.debugMode = true;
  await serve(serve);
}

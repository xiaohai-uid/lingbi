import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:lingbi_novel_engine/llm_client.dart';
import 'package:lingbi_novel_engine/prompt_service.dart';
import 'package:lingbi_novel_engine/generation_cache.dart';
import 'package:lingbi_novel_engine/fallback_chain.dart';
import '../models/novel_models.dart';

/// POST /generate-layer2 — 细纲展开
///
/// Body: { synopsis, setting?, themes?, numVolumes?, numChaptersPerVolume? }
/// Returns: { volumes: [...] }
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final llmClient = LLMClient();
  final fallback = FallbackChain(client: llmClient, models: fallbackModelList());
  final promptService = PromptService();
  final cache = GenerationCache();

  try {
    final body =
        jsonDecode(await context.request.body()) as Map<String, dynamic>;
    final request = Layer2Request.fromJson(body);

    if (request.synopsis.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'synopsis is required'},
      );
    }

    // 检查缓存
    final cacheKey = {
      'synopsis': request.synopsis,
      'setting': request.setting,
      'themes': request.themes.join(','),
      'numVolumes': request.numVolumes.toString(),
      'numChaptersPerVolume': request.numChaptersPerVolume.toString(),
    };
    final cached = cache.get<Layer2Response>('layer2', cacheKey);
    if (cached != null) {
      return Response.json(body: cached.toJson());
    }

    // 渲染 Prompt
    final prompt = promptService.renderPrompt('generate_outline', {
      'synopsis': request.synopsis,
      'setting': request.setting,
      'themes': request.themes.join('、'),
      'numVolumes': request.numVolumes.toString(),
      'numChaptersPerVolume': request.numChaptersPerVolume.toString(),
    });

    // 调用 LLM
    final content = (await fallback.chatWithFallback(
      messages: [
        {'role': 'system', 'content': prompt},
      ],
      temperature: 0.7,
      maxTokens: 4096,
    ))
        .content;

    // 解析 LLM 返回的 JSON
    Map<String, dynamic> resultJson;
    try {
      resultJson = jsonDecode(content) as Map<String, dynamic>;
    } on FormatException {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        return Response.json(
          statusCode: 500,
          body: {'error': 'LLM 返回了无效的 JSON 格式'},
        );
      }
      resultJson = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    }

    final response = Layer2Response.fromJson(resultJson);

    // 缓存结果（30 分钟 TTL）
    cache.set('layer2', cacheKey, response);

    return Response.json(body: response.toJson());
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Layer2 生成失败: ${e.toString()}'},
    );
  }
}

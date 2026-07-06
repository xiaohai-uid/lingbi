import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:lingbi_novel_engine/llm_client.dart';
import 'package:lingbi_novel_engine/prompt_service.dart';
import 'package:lingbi_novel_engine/generation_cache.dart';
import '../models/novel_models.dart';

/// POST /generate-layer1 — 梗概生成
///
/// Body: { idea: string, genre?: string, style?: string }
/// Returns: { synopsis, setting, themes, characters }
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final llmClient = LLMClient();
  final promptService = PromptService();
  final cache = GenerationCache();

  try {
    final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
    final request = Layer1Request.fromJson(body);

    if (request.idea.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'idea is required'},
      );
    }

    // 检查缓存
    final cacheKey = {
      'idea': request.idea,
      'genre': request.genre,
      'style': request.style,
    };
    final cached = cache.get<Layer1Response>('layer1', cacheKey);
    if (cached != null) {
      return Response.json(body: cached.toJson());
    }

    // 渲染 Prompt
    final genreGuide = promptService.getGenre(request.genre)?.description ?? '';
    final prompt = promptService.renderPrompt('expand_idea', {
      'idea': request.idea,
      'genre': request.genre,
      'style': request.style,
      'genreGuide': genreGuide,
    });

    // 调用 LLM（返回原始字符串）
    final content = await llmClient.chat(
      messages: [
        {'role': 'system', 'content': prompt},
      ],
      temperature: 0.8,
      maxTokens: 2048,
    );

    // 解析 LLM 返回的 JSON
    Map<String, dynamic> resultJson;
    try {
      resultJson = jsonDecode(content) as Map<String, dynamic>;
    } on FormatException {
      // LLM 返回了非 JSON 内容，尝试提取 JSON 片段
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        return Response.json(
          statusCode: 500,
          body: {'error': 'LLM 返回了无效的 JSON 格式'},
        );
      }
      resultJson = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    }

    final response = Layer1Response.fromJson(resultJson);

    // 缓存结果（30 分钟 TTL）
    cache.set('layer1', cacheKey, response);

    return Response.json(body: response.toJson());
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Layer1 生成失败: ${e.toString()}'},
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:lingbi_novel_engine/llm_client.dart';
import 'package:lingbi_novel_engine/prompt_service.dart';
import 'package:lingbi_novel_engine/fallback_chain.dart';
import '../models/novel_models.dart';

/// GET /generate-layer3 — 流式正文生成 (SSE)
///
/// Query params:
///   chapterTitle (required), sceneOutline (required)
///   characters?, genre?, style?, synopsis?, previousSceneSummary?
/// 返回 Server-Sent Events 流
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final llmClient = LLMClient();
  final fallback = FallbackChain(client: llmClient, models: fallbackModelList());
  final promptService = PromptService();

  try {
    final body =
        jsonDecode(await context.request.body()) as Map<String, dynamic>;
    final request = Layer3Request.fromJson(body);

    if (request.chapterTitle.isEmpty || request.sceneOutline.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'chapterTitle and sceneOutline are required'},
      );
    }

    // 渲染 Prompt（location/mood/conflict 取自 Layer2 场景对象，不再写死）
    final prompt = promptService.renderPrompt('stream_scene', {
      'sceneTitle': request.chapterTitle,
      'sceneSummary': request.sceneOutline,
      'characters': request.characters.join('、'),
      'location':
          request.location.isNotEmpty ? request.location : '（见上文）',
      'mood': request.mood.isNotEmpty ? request.mood : '（见上文）',
      'conflict':
          request.conflict.isNotEmpty ? request.conflict : '（见上文）',
      'synopsis':
          request.synopsis.isNotEmpty ? request.synopsis : request.context,
      'previousSceneSummary': request.previousSceneSummary.isNotEmpty
          ? request.previousSceneSummary
          : '无',
      'genre': request.genre,
      'style': request.style,
    });

    // 调用 LLM 流式接口
    final llmResponse = await fallback.chatStreamWithFallback(
      messages: [
        {'role': 'system', 'content': prompt},
      ],
      temperature: 0.8,
      maxTokens: 2048,
    );

    // 将 LLM 字节流转换为 SSE 文本流
    final sseStream = bytesToSseLines(llmResponse.stream);

    return Response.stream(
      body: sseStream,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': 'Layer3 生成失败: ${e.toString()}'},
    );
  }
}

/// 将 LLM 原始字节流转换为 SSE 格式行流
///
/// LLM 返回: HTTP chunked body with `data: {...}` lines
/// SSE 输出: `event: chunk\ndata: {"text":"...","done":false}\n\n`
Stream<List<int>> bytesToSseLines(Stream<List<int>> byteStream) async* {
  int wordCount = 0;
  final buffer = StringBuffer();

  await for (final bytes in byteStream) {
    buffer.write(utf8.decode(bytes));
    final text = buffer.toString();
    buffer.clear();

    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();

        if (data == '[DONE]') {
          yield _encodeSse('complete', {'done': true, 'wordCount': wordCount});
          return;
        }

        try {
          final parsed = jsonDecode(data) as Map<String, dynamic>;
          final content =
              parsed['choices']?[0]?['delta']?['content'] as String?;
          if (content != null) {
            wordCount += content.length;
            yield _encodeSse('chunk', {'text': content, 'done': false});
          }
        } on FormatException {
          // skip malformed JSON chunks
        }
      }
    }
  }

  // stream closed without [DONE] — emit complete
  yield _encodeSse('complete', {'done': true, 'wordCount': wordCount});
}

/// 编码单个 SSE 事件为 UTF-8 字节
List<int> _encodeSse(String event, Map<String, dynamic> data) {
  final eventLine = 'event: $event\n';
  final dataLine = 'data: ${jsonEncode(data)}\n\n';
  return utf8.encode('$eventLine$dataLine');
}

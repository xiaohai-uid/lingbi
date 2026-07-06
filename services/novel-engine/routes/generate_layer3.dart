import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:lingbi_novel_engine/llm_client.dart';
import 'package:lingbi_novel_engine/prompt_service.dart';
import '../models/novel_models.dart';

/// GET /generate-layer3 — 流式正文生成 (SSE)
///
/// Query params:
///   chapterTitle (required), sceneOutline (required)
///   characters?, genre?, style?, synopsis?, previousSceneSummary?
/// 返回 Server-Sent Events 流
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final llmClient = LLMClient();
  final promptService = PromptService();

  try {
    final uri = context.request.uri;
    final chapterTitle = uri.queryParameters['chapterTitle'] ?? '';
    final sceneOutline = uri.queryParameters['sceneOutline'] ?? '';
    final characters = uri.queryParameters['characters']?.split(',').toList() ?? [];
    final genre = uri.queryParameters['genre'] ?? 'fantasy';
    final style = uri.queryParameters['style'] ?? 'qidian';
    final synopsis = uri.queryParameters['synopsis'] ?? '';
    final previousSceneSummary = uri.queryParameters['previousSceneSummary'] ?? '无';

    if (chapterTitle.isEmpty || sceneOutline.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'chapterTitle and sceneOutline are required'},
      );
    }

    // 渲染 Prompt
    final prompt = promptService.renderPrompt('stream_scene', {
      'sceneTitle': chapterTitle,
      'sceneSummary': sceneOutline,
      'characters': characters.join('、'),
      'location': '（见上文）',
      'mood': '（见上文）',
      'conflict': '（见上文）',
      'synopsis': synopsis,
      'previousSceneSummary': previousSceneSummary,
      'genre': genre,
      'style': style,
    });

    // 调用 LLM 流式接口
    final llmResponse = await llmClient.chatStream(
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
          final content = parsed['choices']?[0]?['delta']?['content'] as String?;
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

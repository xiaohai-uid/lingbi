import 'dart:convert';
import 'dart:io';
import 'package:lingbi_server/services/chat_service.dart';
import 'package:lingbi_server/models/chat_request.dart';
import 'package:lingbi_server/models/chat_response.dart';

class AIProviderMicroservice {
  final String host;
  final int port;
  final ChatService chatService;
  late HttpServer _server;

  AIProviderMicroservice({
    this.host = 'localhost',
    this.port = 8081,
    required this.chatService,
  });

  Future<void> start() async {
    _server = await HttpServer.bind(host, port);
    _server.listen(_handleRequest);
    print('AI Provider microservice running on $host:$port');
  }

  void _handleRequest(HttpRequest request) async {
    try {
      final uri = request.uri;

      // Route: POST /chat
      if (uri.path == '/chat' && request.method == 'POST') {
        final body = await _readBody(request);
        final chatRequest = ChatRequest.fromJson(json.decode(body));
        await _handleChat(request, chatRequest);
        return;
      }

      // Route: POST /style/analyze
      if (uri.path == '/style/analyze' && request.method == 'POST') {
        final body = await _readBody(request);
        final chatRequest = ChatRequest.fromJson(json.decode(body));
        await _handleStyleAnalyze(request, chatRequest);
        return;
      }

      // Route: POST /novel/analyze
      if (uri.path == '/novel/analyze' && request.method == 'POST') {
        final body = await _readBody(request);
        final chatRequest = ChatRequest.fromJson(json.decode(body));
        await _handleNovelAnalyze(request, chatRequest);
        return;
      }

      // Route: POST /continue
      if (uri.path == '/continue' && request.method == 'POST') {
        final body = await _readBody(request);
        final chatRequest = ChatRequest.fromJson(json.decode(body));
        await _handleContinueWriting(request, chatRequest);
        return;
      }

      // Route: POST /embedding
      if (uri.path == '/embedding' && request.method == 'POST') {
        final body = await _readBody(request);
        await _handleEmbedding(request, json.decode(body));
        return;
      }

      // Route: GET /models
      if (uri.path == '/models' && request.method == 'GET') {
        await _handleGetModels(request);
        return;
      }

      // Route: POST /models
      if (uri.path == '/models' && request.method == 'POST') {
        final body = await _readBody(request);
        await _handleAddModel(request, json.decode(body));
        return;
      }

      // Route: DELETE /models/{id}
      if (uri.path.startsWith('/models/') && request.method == 'DELETE') {
        final modelId = uri.pathSegments.last;
        await _handleDeleteModel(request, modelId);
        return;
      }

      // Route: PUT /active/{id}
      if (uri.path.startsWith('/active/') && request.method == 'PUT') {
        final modelId = uri.pathSegments.last;
        await _handleSetActiveModel(request, modelId);
        return;
      }

      // Default 404
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(json.encode({'error': 'Not found'}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(json.encode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<String> _readBody(HttpRequest request) async {
    return await request.transform(utf8.decoder).join();
  }

  Future<void> _handleChat(HttpRequest request, ChatRequest chatRequest) async {
    request.response.headers.contentType = ContentType('text', 'event-stream');
    request.response.headers.set('Cache-Control', 'no-cache');
    request.response.headers.set('Connection', 'keep-alive');
    request.response.headers.set('X-Accel-Buffering', 'no');

    try {
      await for (final chunk in chatService.chatStream(chatRequest)) {
        request.response.write('data: ${json.encode(chunk)}\n\n');
        await request.response.flush();
      }
      request.response.write('data: [DONE]\n\n');
      await request.response.flush();
    } catch (e) {
      request.response
          .write('data: ${json.encode({'error': e.toString()})}\n\n');
      await request.response.flush();
    }

    await request.response.close();
  }

  Future<void> _handleStyleAnalyze(
      HttpRequest request, ChatRequest chatRequest) async {
    request.response.headers.contentType = ContentType('text', 'event-stream');
    request.response.headers.set('Cache-Control', 'no-cache');
    request.response.headers.set('Connection', 'keep-alive');

    try {
      await for (final chunk in chatService.styleAnalyzeStream(chatRequest)) {
        request.response.write('data: ${json.encode(chunk)}\n\n');
        await request.response.flush();
      }
      request.response.write('data: [DONE]\n\n');
      await request.response.flush();
    } catch (e) {
      request.response
          .write('data: ${json.encode({'error': e.toString()})}\n\n');
      await request.response.flush();
    }

    await request.response.close();
  }

  Future<void> _handleNovelAnalyze(
      HttpRequest request, ChatRequest chatRequest) async {
    request.response.headers.contentType = ContentType('text', 'event-stream');
    request.response.headers.set('Cache-Control', 'no-cache');
    request.response.headers.set('Connection', 'keep-alive');

    try {
      await for (final chunk in chatService.novelAnalyzeStream(chatRequest)) {
        request.response.write('data: ${json.encode(chunk)}\n\n');
        await request.response.flush();
      }
      request.response.write('data: [DONE]\n\n');
      await request.response.flush();
    } catch (e) {
      request.response
          .write('data: ${json.encode({'error': e.toString()})}\n\n');
      await request.response.flush();
    }

    await request.response.close();
  }

  Future<void> _handleContinueWriting(
      HttpRequest request, ChatRequest chatRequest) async {
    request.response.headers.contentType = ContentType('text', 'event-stream');
    request.response.headers.set('Cache-Control', 'no-cache');
    request.response.headers.set('Connection', 'keep-alive');

    try {
      await for (final chunk
          in chatService.continueWritingStream(chatRequest)) {
        request.response.write('data: ${json.encode(chunk)}\n\n');
        await request.response.flush();
      }
      request.response.write('data: [DONE]\n\n');
      await request.response.flush();
    } catch (e) {
      request.response
          .write('data: ${json.encode({'error': e.toString()})}\n\n');
      await request.response.flush();
    }

    await request.response.close();
  }

  Future<void> _handleEmbedding(
      HttpRequest request, Map<String, dynamic> body) async {
    try {
      final text = body['text'] as String;
      final embedding = await chatService.getEmbedding(text);

      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({
        'embedding': embedding,
      }));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(json.encode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleGetModels(HttpRequest request) async {
    try {
      final models = await chatService.listModels();
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode(models));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(json.encode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleAddModel(
      HttpRequest request, Map<String, dynamic> body) async {
    try {
      final model = await chatService.addModel(body);
      request.response.headers.contentType = ContentType.json;
      request.response.statusCode = HttpStatus.created;
      request.response.write(json.encode(model));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(json.encode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleDeleteModel(HttpRequest request, String modelId) async {
    try {
      await chatService.deleteModel(modelId);
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode({'success': true}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(json.encode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleSetActiveModel(
      HttpRequest request, String modelId) async {
    try {
      await chatService.setActiveModel(modelId);
      request.response.headers.contentType = ContentType.json;
      request.response
          .write(json.encode({'success': true, 'activeModel': modelId}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(json.encode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> stop() async {
    await _server.close();
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';

/// A message in a chat conversation.
class ChatMessage {
  final String role;
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }
}

/// A LiteLLM-compatible client for OpenAI-compatible API endpoints.
class LiteLLMClient {
  final HttpClient _client;
  final String baseUrl;
  final Map<String, String> _headers;

  LiteLLMClient({
    required this.baseUrl,
    Map<String, String> headers = const {},
  })  : _client = HttpClient(),
        _headers = {'Content-Type': 'application/json', ...headers} {
    _client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Allow self-signed certificates in development
      return host == 'localhost' || host == '127.0.0.1';
    };
  }

  /// Streams chat completions using SSE format.
  ///
  /// Returns a stream of content chunks. Each chunk is a partial response from
  /// the model. The stream completes when the server sends `[DONE]`.
  Future<Stream<String>> chat({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
    bool stream = true,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/chat/completions');
    final request = await _client.postUrl(uri);

    _headers.forEach(request.headers.set);

    final body = {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': stream,
    };

    await request.add(utf8.encode(jsonEncode(body)));

    final response = await request.close();

    if (response.statusCode != 200) {
      final errorBody = await response.transform(utf8.decoder).join();
      throw Exception('HTTP ${response.statusCode}: $errorBody');
    }

    final stream = response.cast<List<int>>();

    // Parse SSE stream
    final buffer = StringBuffer();
    return stream.asyncMap((chunk) async {
      buffer.write(utf8.decode(chunk));
      final parts = buffer.toString().split('\n');
      final events = <String>[];

      // Keep the last incomplete line in the buffer
      String lastPart = parts.removeLast();
      if (lastPart.isEmpty) {
        lastPart = '';
      }

      for (var part in parts) {
        if (part.startsWith('data: ')) {
          final data = part.substring(6);
          if (data == '[DONE]') {
            // Signal end of stream
            return '[DONE]';
          }
          try {
            final json = jsonDecode(data);
            if (json['choices'] != null && json['choices'].isNotEmpty) {
              final delta = json['choices'][0]['delta'];
              if (delta != null && delta['content'] != null) {
                final content = delta['content'] as String;
                if (content.isNotEmpty) {
                  events.add(content);
                }
              }
            }
          } catch (e) {
            // Ignore parsing errors for non-data lines
          }
        }
      }

      // Put back the last incomplete line
      if (lastPart.isNotEmpty) {
        buffer.clear();
        buffer.write(lastPart);
      } else {
        buffer.clear();
      }

      return events.join('');
    });
  }

  /// Gets embeddings for input text.
  Future<List<double>> embed({
    required String model,
    required String input,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/embeddings');
    final request = await _client.postUrl(uri);

    _headers.forEach(request.headers.set);

    final body = {
      'model': model,
      'input': input,
    };

    await request.add(utf8.encode(jsonEncode(body)));

    final response = await request.close();

    if (response.statusCode != 200) {
      final errorBody = await response.transform(utf8.decoder).join();
      throw Exception('HTTP ${response.statusCode}: $errorBody');
    }

    final jsonResponse = await response.transform(utf8.decoder).join();
    final json = jsonDecode(jsonResponse);

    if (json['data'] == null || json['data'].isEmpty) {
      throw Exception('No embedding data returned');
    }

    final embedding = json['data'][0]['embedding'] as List<dynamic>;
    return embedding.cast<double>().toList();
  }

  /// Gets available models from the server.
  Future<List<String>> listModels() async {
    final uri = Uri.parse('$baseUrl/v1/models');
    final request = await _client.getUrl(uri);

    _headers.forEach(request.headers.set);

    final response = await request.close();

    if (response.statusCode != 200) {
      final errorBody = await response.transform(utf8.decoder).join();
      throw Exception('HTTP ${response.statusCode}: $errorBody');
    }

    final jsonResponse = await response.transform(utf8.decoder).join();
    final json = jsonDecode(jsonResponse);

    if (json['data'] == null) {
      return [];
    }

    return (json['data'] as List)
        .map((m) => m['id'] as String)
        .toList();
  }

  void dispose() {
    _client.close(force: true);
  }
}

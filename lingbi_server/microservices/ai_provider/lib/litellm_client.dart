import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Exception thrown when a LiteLLM API call fails.
class LiteLLMException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  const LiteLLMException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    if (statusCode != null) {
      return 'LiteLLMException($statusCode): $message';
    }
    return 'LiteLLMException: $message';
  }
}

/// Exception thrown when a rate limit is hit.
class RateLimitException extends LiteLLMException {
  final Duration retryAfter;

  const RateLimitException(String message,
      {this.retryAfter = const Duration(seconds: 30)})
      : super(message, statusCode: 429);
}

/// Exception thrown when a request times out.
class LiteLLMTimeoutException extends LiteLLMException {
  const LiteLLMTimeoutException(String message)
      : super(message, statusCode: null);
}

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.role == role &&
        other.content == content;
  }

  @override
  int get hashCode => Object.hash(role, content);
}

/// A LiteLLM-compatible client for OpenAI-compatible API endpoints.
///
/// Supports streaming (SSE) and non-streaming chat completions, embeddings,
/// and model listing with retry logic, timeouts, and rate-limit handling.
class LiteLLMClient {
  final HttpClient _client;
  final String baseUrl;
  final Map<String, String> _headers;
  final Duration _timeout;
  final int _maxRetries;

  /// Creates a new LiteLLM client.
  ///
  /// [baseUrl] is the root URL of the LiteLLM proxy (e.g. `http://localhost:11434`).
  /// [headers] are additional HTTP headers to include in every request.
  /// [timeout] is the maximum time to wait for a response (default 60 seconds).
  /// [maxRetries] is the number of retries on retryable errors (default 3).
  LiteLLMClient({
    required this.baseUrl,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 60),
    int maxRetries = 3,
  })  : _client = HttpClient(),
        _headers = {'Content-Type': 'application/json', ...headers},
        _timeout = timeout,
        _maxRetries = maxRetries {
    _client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      // Allow self-signed certificates in development
      return host == 'localhost' || host == '127.0.0.1';
    };
  }

  /// Sends a chat completion request.
  ///
  /// If [stream] is true (default), returns a stream of content chunks using SSE.
  /// If [stream] is false, returns a single-element stream with the full response.
  ///
  /// The stream emits `[DONE]` as the last element when the server finishes,
  /// or `[ERROR]: message` if an error occurs mid-stream.
  Future<Stream<String>> chat({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
    bool stream = true,
  }) async {
    if (!stream) {
      return _nonStreamingChat(
        model: model,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }
    return _streamingChat(
      model: model,
      messages: messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// Non-streaming chat completion.
  Future<Stream<String>> _nonStreamingChat({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/chat/completions');
    final body = {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': false,
    };

    final jsonResponse = await _executeWithRetry(
      uri: uri,
      method: 'POST',
      body: body,
    );

    final content = _extractContent(jsonResponse) ?? '';
    return Stream<String>.value(content);
  }

  /// Streaming chat completion using SSE.
  Future<Stream<String>> _streamingChat({
    required String model,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/chat/completions');
    final request = await _client.postUrl(uri);

    _headers.forEach(request.headers.set);

    final body = {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    };

    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(_timeout);

    if (response.statusCode != 200) {
      final errorBody = await response.transform(utf8.decoder).join();
      throw _createException(response.statusCode, errorBody);
    }

    final stream = response.cast<List<int>>();
    final buffer = StringBuffer();

    return stream.asyncMap((chunk) {
      buffer.write(utf8.decode(chunk));
      final parts = buffer.toString().split('\n');
      final events = <String>[];

      // Keep the last incomplete line in the buffer
      final lastPart = parts.removeLast();

      for (var part in parts) {
        if (part.startsWith('data: ')) {
          final data = part.substring(6);
          if (data == '[DONE]') {
            return '[DONE]';
          }
          try {
            final json = jsonDecode(data);
            final content = _extractDeltaContent(json);
            if (content != null && content.isNotEmpty) {
              events.add(content);
            }
          } catch (e) {
            // Ignore parsing errors for non-data lines
          }
        }
      }

      // Put back the last incomplete line
      buffer.clear();
      if (lastPart.isNotEmpty) {
        buffer.write(lastPart);
      }

      if (events.isEmpty) {
        return '';
      }
      return events.join('');
    }).where((chunk) => chunk.isNotEmpty);
  }

  /// Gets embeddings for input text.
  Future<List<double>> embed({
    required String model,
    required String input,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/embeddings');
    final body = {
      'model': model,
      'input': input,
    };

    final jsonResponse = await _executeWithRetry(
      uri: uri,
      method: 'POST',
      body: body,
    );

    if (jsonResponse['data'] == null || jsonResponse['data'].isEmpty) {
      throw const LiteLLMException('No embedding data returned');
    }

    final embedding = jsonResponse['data'][0]['embedding'] as List<dynamic>;
    return embedding.cast<double>().toList();
  }

  /// Gets available models from the server.
  Future<List<String>> listModels() async {
    final uri = Uri.parse('$baseUrl/v1/models');

    final jsonResponse = await _executeWithRetry(
      uri: uri,
      method: 'GET',
    );

    if (jsonResponse['data'] == null) {
      return [];
    }

    return (jsonResponse['data'] as List)
        .map((m) => m['id'] as String)
        .toList();
  }

  /// Executes an HTTP request with retry logic.
  ///
  /// Retries on 429 (rate limit), 502 (bad gateway), 503 (service unavailable),
  /// and socket exceptions. Uses exponential backoff with jitter.
  Future<Map<String, dynamic>> _executeWithRetry({
    required Uri uri,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        HttpClientRequest request;
        if (method == 'POST') {
          request = await _client.postUrl(uri);
          if (body != null) {
            request.add(utf8.encode(jsonEncode(body)));
          }
        } else {
          request = await _client.getUrl(uri);
        }

        _headers.forEach(request.headers.set);
        final response = await request.close().timeout(_timeout);

        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          return jsonDecode(responseBody) as Map<String, dynamic>;
        }

        final errorBody = await response.transform(utf8.decoder).join();

        // Handle retryable status codes
        if (_isRetryableStatusCode(response.statusCode) &&
            attempt < _maxRetries) {
          await _waitBeforeRetry(attempt, response.statusCode, errorBody);
          continue;
        }

        throw _createException(response.statusCode, errorBody);
      } on SocketException catch (e) {
        if (attempt < _maxRetries) {
          await _waitBeforeRetry(attempt, null, e.message);
          continue;
        }
        throw LiteLLMException(
            'Connection failed after $_maxRetries retries: ${e.message}');
      } on TimeoutException {
        if (attempt < _maxRetries) {
          await _waitBeforeRetry(attempt, null, 'timeout');
          continue;
        }
        throw LiteLLMTimeoutException(
            'Request timed out after $_maxRetries retries');
      }
    }

    throw const LiteLLMException('Max retries exceeded');
  }

  /// Whether the status code indicates a retryable error.
  bool _isRetryableStatusCode(int statusCode) {
    return statusCode == 429 || // Rate limited
        statusCode == 502 || // Bad gateway
        statusCode == 503 || // Service unavailable
        statusCode == 504; // Gateway timeout
  }

  /// Waits with exponential backoff + jitter before a retry.
  Future<void> _waitBeforeRetry(
      int attempt, int? statusCode, String errorBody) async {
    // Exponential backoff: base 1s, 2s, 4s, ...
    final baseDelay = Duration(seconds: pow(2, attempt).toInt());
    // Add jitter: up to 1s random
    final jitter = Duration(milliseconds: Random().nextInt(1000));
    await Future.delayed(baseDelay + jitter);
  }

  /// Creates the appropriate exception from an error response.
  LiteLLMException _createException(int statusCode, String errorBody) {
    // Try to extract a message from the JSON error body
    String message;
    try {
      final json = jsonDecode(errorBody);
      message =
          json['error']?['message'] ?? json['error']?.toString() ?? errorBody;
    } catch (_) {
      message = errorBody;
    }

    switch (statusCode) {
      case 429:
        return RateLimitException(message);
      case 400:
        return LiteLLMException('Bad request: $message',
            statusCode: statusCode, body: errorBody);
      case 401:
        return LiteLLMException('Authentication failed: $message',
            statusCode: statusCode, body: errorBody);
      case 404:
        return LiteLLMException('Not found: $message',
            statusCode: statusCode, body: errorBody);
      case 500:
        return LiteLLMException('Internal server error: $message',
            statusCode: statusCode, body: errorBody);
      default:
        return LiteLLMException('HTTP $statusCode: $message',
            statusCode: statusCode, body: errorBody);
    }
  }

  /// Extracts content from a non-streaming chat response.
  String? _extractContent(Map<String, dynamic> json) {
    if (json['choices'] != null && json['choices'].isNotEmpty) {
      final choice = json['choices'][0];
      if (choice['message'] != null && choice['message']['content'] != null) {
        return choice['message']['content'] as String;
      }
      if (choice['text'] != null) {
        return choice['text'] as String;
      }
    }
    return null;
  }

  /// Extracts delta content from a streaming SSE chunk.
  String? _extractDeltaContent(Map<String, dynamic> json) {
    if (json['choices'] != null && json['choices'].isNotEmpty) {
      final delta = json['choices'][0]['delta'];
      if (delta != null && delta['content'] != null) {
        return delta['content'] as String;
      }
      // Some providers use 'text' instead of 'delta'
      if (json['choices'][0]['text'] != null) {
        return json['choices'][0]['text'] as String;
      }
    }
    return null;
  }

  /// Releases resources held by the client.
  void dispose() {
    _client.close(force: true);
  }
}

/// PROTOTYPE → PRODUCTION: Deterministic fake AIProvider for conformance tests.
///
/// Returns scripted responses without network access. Any AIProvider
/// implementation must pass the same conformance suite this fake passes.
library;

import 'package:lingbi/shared/ai/ai_provider.dart';

/// A fully deterministic AIProvider for CI conformance testing.
class FakeConformanceProvider extends AIProvider {
  FakeConformanceProvider({
    this.toolSupport = true,
    this.chatResponse = 'conformance-ok',
    this.toolTurns = const [],
  });

  final bool toolSupport;
  final String chatResponse;
  final List<ToolTurn> toolTurns;
  int _toolIndex = 0;

  /// Tracks all chatSync calls for assertion.
  final List<List<ChatMessage>> chatSyncCalls = [];

  /// Tracks all chatWithTools calls for assertion.
  final List<List<ChatMessage>> chatWithToolsCalls = [];

  @override
  String get name => 'fake-conformance';

  @override
  String get displayName => 'Fake Conformance Provider';

  @override
  bool get isAvailable => true;

  @override
  bool get supportsTools => toolSupport;

  @override
  Stream<String> chat({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    // Stream response word by word
    for (final word in chatResponse.split(' ')) {
      yield '$word ';
    }
  }

  @override
  Future<String> chatSync({
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    chatSyncCalls.add(List.of(messages));
    return chatResponse;
  }

  @override
  Future<ToolTurn> chatWithTools({
    required List<ChatMessage> messages,
    required List<ToolSpec> tools,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    chatWithToolsCalls.add(List.of(messages));
    if (!toolSupport) {
      throw UnsupportedError('$name does not support function-calling');
    }
    if (_toolIndex < toolTurns.length) {
      return toolTurns[_toolIndex++];
    }
    return ToolTurn(content: chatResponse, finishReason: 'stop');
  }

  @override
  Future<List<double>> embed(String text) async {
    // Deterministic 4-dim embedding based on text length
    final len = text.length.toDouble();
    return [len, len / 2, len / 3, len / 4];
  }

  @override
  Future<void> dispose() async {}
}

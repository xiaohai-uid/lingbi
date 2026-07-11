import 'dart:async';
import '../client.dart';

class AIClient {
  // late final $pb.AIProviderServiceClient _stub;

  AIClient() {
    // _stub = $pb.AIProviderServiceClient(GrpcClientFactory.instance.channel);
  }

  /// 流式生成文本
  Stream<String> streamText({
    required String provider,
    required String model,
    String? systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) {
    // final req = $pb.StreamTextRequest()
    //   ..provider = provider
    //   ..model = model
    //   ..system_prompt = systemPrompt ?? ''
    //   ..user_prompt = userPrompt
    //   ..temperature = temperature;
    // return _stub.streamText(req).map((chunk) => chunk.text);
    throw UnimplementedError('Run protoc to generate stubs');
  }

  /// 结构化生成
  Future<Map<String, dynamic>> generateStructured({
    required String provider,
    required String model,
    String? systemPrompt,
    required String userPrompt,
    required String schemaJson,
  }) {
    // final req = $pb.GenerateStructuredRequest()
    //   ..provider = provider
    //   ..model = model
    //   ..system_prompt = systemPrompt ?? ''
    //   ..user_prompt = userPrompt
    //   ..schema_json = schemaJson;
    // final resp = await _stub.generateStructured(req);
    // return jsonDecode(resp.json);
    throw UnimplementedError('Run protoc to generate stubs');
  }

  /// 嵌入向量
  Future<List<List<double>>> embed(
      String provider, String model, List<String> texts) {
    // final req = $pb.EmbedRequest()
    //   ..provider = provider
    //   ..model = model
    //   ..texts.addAll(texts);
    // final resp = await _stub.embed(req);
    // return resp.embeddings.map((e) => e.values).toList();
    throw UnimplementedError('Run protoc to generate stubs');
  }
}
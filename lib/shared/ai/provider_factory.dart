import 'package:http/http.dart' as http;
import 'ai_provider.dart';
import 'models/endpoint_config.dart';
import 'providers/openai_compatible_provider.dart';
import 'providers/anthropic_provider.dart';

/// Provider 工厂 — 基于 EndpointConfig 协议路由创建 Provider 实例
///
/// 根据 [EndpointConfig.protocol] 字段创建正确的 Provider 实例，
/// 不再使用 switch(name) 模式。
class ProviderFactory {
  /// 根据端点配置创建 Provider 实例
  ///
  /// [config] 端点配置
  /// [client] 可选的 HTTP 客户端（用于测试注入）
  static AIProvider create(
    EndpointConfig config, {
    http.Client? client,
  }) {
    return switch (config.protocol) {
      Protocol.openai => OpenAICompatibleProvider(
          config: config,
          client: client,
        ),
      Protocol.anthropic => AnthropicProvider(
          config: config,
          client: client,
        ),
    };
  }

  /// 获取可用模型列表（调用 /v1/models 端点）
  ///
  /// 返回模型 ID 列表。失败时返回空列表。
  /// 仅 OpenAI 兼容协议支持此端点。
  static Future<List<String>> discoverModels(
    EndpointConfig config, {
    http.Client? client,
  }) async {
    if (config.protocol != Protocol.openai) return [];

    final provider = OpenAICompatibleProvider(
      config: config,
      client: client,
    );
    try {
      return await provider.listModels();
    } finally {
      await provider.dispose();
    }
  }

  /// 测试端点连接
  ///
  /// 发送一条简单消息验证 API 端点的可用性。
  /// 返回连接测试结果，包含延迟和状态信息。
  static Future<ConnectionTestResult> testConnection(
    EndpointConfig config, {
    http.Client? client,
  }) async {
    final provider = create(config, client: client);
    try {
      return await provider.testConnection();
    } finally {
      await provider.dispose();
    }
  }
}

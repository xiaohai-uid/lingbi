import 'package:grpc/grpc.dart';

/// 灵笔 gRPC 客户端工厂
///
/// 管理到 API Gateway 的 gRPC 连接。
/// API Gateway地址: localhost:50051 (开发) / docker: api-gateway:50051
class GrpcClientFactory {
  static GrpcClientFactory? _instance;
  late final ClientChannel _channel;
  bool _initialized = false;

  GrpcClientFactory._();

  static GrpcClientFactory get instance {
    _instance ??= GrpcClientFactory._();
    return _instance!;
  }

  /// 初始化 gRPC 连接
  Future<void> init({
    String host = 'localhost',
    int port = 50051,
  }) async {
    if (_initialized) return;

    _channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        idleTimeout: Duration(minutes: 5),
      ),
    );
    _initialized = true;
  }

  ClientChannel get channel {
    if (!_initialized) {
      throw StateError('GrpcClientFactory not initialized. Call init() first.');
    }
    return _channel;
  }

  /// 关闭连接
  Future<void> shutdown() async {
    if (_initialized) {
      await _channel.shutdown();
      _initialized = false;
    }
  }
}
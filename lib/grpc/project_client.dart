import '../client.dart';
// 注意: 以下代码引用 protoc 生成的 Dart 代码
// import 'package:protos/project/project.pbgrpc.dart' as $pb;
// 需要运行 protoc 编译后取消注释

/// ProjectService gRPC 客户端封装
class ProjectClient {
  // late final $pb.ProjectServiceClient _stub;

  ProjectClient() {
    // _stub = $pb.ProjectServiceClient(GrpcClientFactory.instance.channel);
  }

  /// 获取 WorldTree（世界树全量加载）
  Future<Map<String, dynamic>> getWorldTree(String worldId) async {
    // final req = $pb.GetWorldTreeRequest()..world_id = worldId;
    // final resp = await _stub.getWorldTree(req);
    // return {'works': resp.works, 'volumes': resp.volumes, ...};
    throw UnimplementedError('Run protoc to generate stubs');
  }

  /// 列出所有 World
  Future<List<Map<String, dynamic>>> listWorlds() async {
    // final resp = await _stub.listWorlds($pb.ListWorldsRequest());
    // return resp.worlds.map((w) => w.toProto3Json()).toList();
    throw UnimplementedError('Run protoc to generate stubs');
  }

  /// 创建 World
  Future<Map<String, dynamic>> createWorld(
      String name, String description, List<String> genres) async {
    // final req = $pb.CreateWorldRequest()
    //   ..name = name
    //   ..description = description
    //   ..genres.addAll(genres);
    // final resp = await _stub.createWorld(req);
    // return resp.toProto3Json();
    throw UnimplementedError('Run protoc to generate stubs');
  }

  /// 创建 Work
  Future<Map<String, dynamic>> createWork(
      String worldId, String title, String description) async {
    // final req = $pb.CreateWorkRequest()
    //   ..world_id = worldId
    //   ..title = title
    //   ..description = description;
    // final resp = await _stub.createWork(req);
    // return resp.toProto3Json();
    throw UnimplementedError('Run protoc to generate stubs');
  }
}
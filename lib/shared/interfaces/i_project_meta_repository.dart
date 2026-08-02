
/// 世界宪法 — 创作的硬规则和软指导
class WorldConstitution {
  const WorldConstitution({
    this.hardInvariants = const [],
    this.softGuidance = const [],
  });

  factory WorldConstitution.fromJson(Map<String, dynamic> json) {
    return WorldConstitution(
      hardInvariants: (json['hardInvariants'] as List<dynamic>?)
              ?.cast<String>() ?? [],
      softGuidance: (json['softGuidance'] as List<dynamic>?)
              ?.cast<String>() ?? [],
    );
  }

  /// 不可变硬规则（写入后不可通过普通 API 修改）
  final List<String> hardInvariants;

  /// 可编辑百科/软指导
  final List<String> softGuidance;

  Map<String, dynamic> toJson() => {
        'hardInvariants': hardInvariants,
        'softGuidance': softGuidance,
      };
}

/// 项目元数据仓储接口
///
/// 管理项目目录下 project_meta/ 的结构化文件读写。
/// 支持 worldbuilding.json, characters.json, outline.json 等。
/// 写入时自动同步 Canon 索引，删除时自动清理 Canon 索引。
abstract class IProjectMetaRepository {
  /// 读取指定元数据文件
  Future<Map<String, dynamic>?> read(String projectId, String fileName);

  /// 写入指定元数据文件（自动创建 Canon 索引条目）
  Future<void> write(String projectId, String fileName, Map<String, dynamic> data);

  /// 列出项目下所有元数据文件
  Future<List<String>> list(String projectId);

  /// 删除指定元数据文件（自动清理 Canon 索引）
  Future<void> delete(String projectId, String fileName);

  /// 读取世界宪法
  Future<WorldConstitution?> readConstitution(String projectId);

  /// 写入世界宪法（hardInvariants 不可通过普通 API 修改）
  Future<void> writeConstitution(String projectId, WorldConstitution constitution);

  /// 获取 project_meta/ 目录路径
  Future<String> getMetaDirPath(String projectId);
}

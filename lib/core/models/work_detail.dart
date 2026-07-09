import 'package:lingbi/data/database/world_database.dart';

/// Work 扩展 — 带完整层级的作品
///
/// Drift 生成的 Works 只有基础字段。
/// WorkDetail 在 Repository 层手动构建，包含 volumes → chapters → scenes 完整树。
class WorkDetail {
  WorkDetail({
    required this.work,
    required this.volumes,
  });
  final Work work; // Drift 生成的 Works 数据类
  final List<Volume> volumes;

  /// 便捷访问器
  String get id => work.id;
  String get worldId => work.worldId;
  String get title => work.title;
  String? get description => work.description;
  String get type => work.type;
  DateTime get createdAt => work.createdAt;
  DateTime get updatedAt => work.updatedAt;

  WorkDetail copyWith({List<Volume>? volumes}) {
    return WorkDetail(
      work: work,
      volumes: volumes ?? this.volumes,
    );
  }
}

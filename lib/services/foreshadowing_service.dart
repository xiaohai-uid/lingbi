/// 伏笔全生命周期管理服务
///
/// 职责：
/// 1. 伏笔 CRUD（存储在 project_meta/foreshadowing.json）
/// 2. 逾期检测：当前章节超过 expectedPayoffChapter 时标记 overdue
/// 3. 提供活跃伏笔列表供 ContextAssembler 注入
/// 4. 伏笔回收后状态更新为 resolved
library;

import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';

/// 伏笔状态
enum ForeshadowingStatus {
  /// 活跃（已埋设，待回收）
  active,

  /// 已回收
  resolved,

  /// 逾期（超过预期回收章节仍未回收）
  overdue;

  static ForeshadowingStatus fromString(String value) {
    switch (value) {
      case 'resolved':
        return ForeshadowingStatus.resolved;
      case 'overdue':
        return ForeshadowingStatus.overdue;
      default:
        return ForeshadowingStatus.active;
    }
  }

  String get value => name;
}

/// 伏笔条目 — 全生命周期数据模型
class ForeshadowingEntry {
  const ForeshadowingEntry({
    required this.id,
    required this.description,
    required this.plantedChapter,
    this.expectedPayoffChapter,
    this.status = ForeshadowingStatus.active,
    this.relatedCharacters = const [],
    this.resolvedChapter,
    this.notes = '',
    this.weight = 5,
  });

  factory ForeshadowingEntry.fromJson(Map<String, dynamic> json) {
    return ForeshadowingEntry(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      plantedChapter: json['plantedChapter'] as String? ?? '',
      expectedPayoffChapter: json['expectedPayoffChapter'] as String?,
      status: ForeshadowingStatus.fromString(
          json['status'] as String? ?? 'active'),
      relatedCharacters: (json['relatedCharacters'] as List<dynamic>?)
              ?.cast<String>() ??
          const [],
      resolvedChapter: json['resolvedChapter'] as String?,
      notes: json['notes'] as String? ?? '',
      weight: json['weight'] as int? ?? 5,
    );
  }

  /// 唯一标识
  final String id;

  /// 伏笔描述
  final String description;

  /// 埋设章节
  final String plantedChapter;

  /// 预期回收章节（可选）
  final String? expectedPayoffChapter;

  /// 当前状态
  final ForeshadowingStatus status;

  /// 关联角色
  final List<String> relatedCharacters;

  /// 实际回收章节
  final String? resolvedChapter;

  /// 备注
  final String notes;

  /// 重要程度 (1-10)
  final int weight;

  ForeshadowingEntry copyWith({
    String? description,
    String? plantedChapter,
    String? expectedPayoffChapter,
    ForeshadowingStatus? status,
    List<String>? relatedCharacters,
    String? resolvedChapter,
    String? notes,
    int? weight,
  }) {
    return ForeshadowingEntry(
      id: id,
      description: description ?? this.description,
      plantedChapter: plantedChapter ?? this.plantedChapter,
      expectedPayoffChapter:
          expectedPayoffChapter ?? this.expectedPayoffChapter,
      status: status ?? this.status,
      relatedCharacters: relatedCharacters ?? this.relatedCharacters,
      resolvedChapter: resolvedChapter ?? this.resolvedChapter,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'plantedChapter': plantedChapter,
        'expectedPayoffChapter': expectedPayoffChapter,
        'status': status.value,
        'relatedCharacters': relatedCharacters,
        'resolvedChapter': resolvedChapter,
        'notes': notes,
        'weight': weight,
      };
}

/// 伏笔管理服务
class ForeshadowingService {
  ForeshadowingService({required IProjectMetaRepository metaRepository})
      : _metaRepository = metaRepository;

  final IProjectMetaRepository _metaRepository;

  /// 存储文件名
  static const String _fileName = 'foreshadowing.json';

  // ─── CRUD ───

  /// 获取项目所有伏笔
  Future<List<ForeshadowingEntry>> listAll(String projectId) async {
    final data = await _metaRepository.read(projectId, _fileName);
    if (data == null) return [];
    final entries = (data['entries'] as List<dynamic>?)
            ?.map((e) => ForeshadowingEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return entries;
  }

  /// 按状态筛选
  Future<List<ForeshadowingEntry>> listByStatus(
    String projectId,
    ForeshadowingStatus status,
  ) async {
    final all = await listAll(projectId);
    return all.where((e) => e.status == status).toList();
  }

  /// 获取活跃伏笔（active + overdue）
  Future<List<ForeshadowingEntry>> listActive(String projectId) async {
    final all = await listAll(projectId);
    return all
        .where((e) =>
            e.status == ForeshadowingStatus.active ||
            e.status == ForeshadowingStatus.overdue)
        .toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
  }

  /// 创建伏笔
  Future<ForeshadowingEntry> create({
    required String projectId,
    required String description,
    required String plantedChapter,
    String? expectedPayoffChapter,
    List<String> relatedCharacters = const [],
    String notes = '',
    int weight = 5,
  }) async {
    final entries = await listAll(projectId);
    final entry = ForeshadowingEntry(
      id: 'fs_${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      plantedChapter: plantedChapter,
      expectedPayoffChapter: expectedPayoffChapter,
      relatedCharacters: relatedCharacters,
      notes: notes,
      weight: weight,
    );
    entries.add(entry);
    await _save(projectId, entries);
    return entry;
  }

  /// 更新伏笔
  Future<void> update(String projectId, ForeshadowingEntry entry) async {
    final entries = await listAll(projectId);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    entries[index] = entry;
    await _save(projectId, entries);
  }

  /// 删除伏笔
  Future<void> delete(String projectId, String entryId) async {
    final entries = await listAll(projectId);
    entries.removeWhere((e) => e.id == entryId);
    await _save(projectId, entries);
  }

  /// 回收伏笔（标记为 resolved）
  Future<void> resolve({
    required String projectId,
    required String entryId,
    required String resolvedChapter,
  }) async {
    final entries = await listAll(projectId);
    final index = entries.indexWhere((e) => e.id == entryId);
    if (index == -1) return;
    entries[index] = entries[index].copyWith(
      status: ForeshadowingStatus.resolved,
      resolvedChapter: resolvedChapter,
    );
    await _save(projectId, entries);
  }

  // ─── 逾期检测 ───

  /// 检测并标记逾期伏笔
  ///
  /// [currentChapterIndex] — 当前章节序号（从 1 开始）
  /// 返回新标记为 overdue 的伏笔列表。
  Future<List<ForeshadowingEntry>> detectOverdue(
    String projectId,
    int currentChapterIndex,
  ) async {
    final entries = await listAll(projectId);
    final newlyOverdue = <ForeshadowingEntry>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.status != ForeshadowingStatus.active) continue;
      if (entry.expectedPayoffChapter == null) continue;

      final expectedIndex = _parseChapterIndex(entry.expectedPayoffChapter!);
      if (expectedIndex > 0 && currentChapterIndex > expectedIndex) {
        entries[i] = entry.copyWith(status: ForeshadowingStatus.overdue);
        newlyOverdue.add(entries[i]);
      }
    }

    if (newlyOverdue.isNotEmpty) {
      await _save(projectId, entries);
    }
    return newlyOverdue;
  }

  // ─── ContextAssembler 集成 ───

  /// 生成活跃伏笔上下文文本（供 ContextAssembler 注入）
  Future<String> buildContextText(String projectId) async {
    final active = await listActive(projectId);
    if (active.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('【活跃伏笔（必须在适当时机回收）】');
    for (final entry in active) {
      final statusTag =
          entry.status == ForeshadowingStatus.overdue ? '⚠逾期' : '';
      final target = entry.expectedPayoffChapter != null
          ? ' → 预期第${entry.expectedPayoffChapter}章回收'
          : '';
      buffer.writeln(
          '- [${entry.weight}] ${entry.description}$target$statusTag');
    }
    return buffer.toString();
  }

  // ─── 辅助 ───

  /// 解析章节标识为序号
  int _parseChapterIndex(String chapterRef) {
    final match = RegExp(r'(\d+)').firstMatch(chapterRef);
    if (match != null) return int.parse(match.group(1)!);
    return -1;
  }

  /// 持久化
  Future<void> _save(String projectId, List<ForeshadowingEntry> entries) async {
    await _metaRepository.write(projectId, _fileName, {
      'entries': entries.map((e) => e.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}

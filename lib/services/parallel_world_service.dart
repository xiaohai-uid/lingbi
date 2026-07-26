/// 平行世界 — 小说分支 + 成剧下游
///
/// 在剧情节点创建分支，生成多条平行故事线：
/// - 分支创建：任意章节节点分叉，记录分叉点
/// - 上下文继承：继承分叉点的角色/设定/伏笔状态快照
/// - 多线并行：同一项目可存在多条平行故事线
/// - 分支管理：切换/合并/删除
/// - 成剧下游：基于分支 IP 资产生成不同版本剧本
/// - 分支间差异对比
library;

import 'package:lingbi/core/ai/ai_provider.dart';
import 'package:lingbi/services/interfaces/i_project_meta_repository.dart';

// ─── 数据模型 ───

/// 上下文快照（分叉点状态）
class ContextSnapshot {
  const ContextSnapshot({
    this.characters = const [],
    this.settings = const [],
    this.foreshadowing = const [],
    this.plotPoints = const [],
    this.chapterIndex = 0,
    this.summary = '',
  });

  factory ContextSnapshot.fromJson(Map<String, dynamic> json) {
    return ContextSnapshot(
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      settings: (json['settings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      foreshadowing: (json['foreshadowing'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      plotPoints: (json['plot_points'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      chapterIndex: json['chapter_index'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
    );
  }

  /// 角色状态列表
  final List<String> characters;

  /// 设定条目
  final List<String> settings;

  /// 伏笔状态
  final List<String> foreshadowing;

  /// 已发生的情节节点
  final List<String> plotPoints;

  /// 分叉章节索引
  final int chapterIndex;

  /// 分叉点摘要
  final String summary;

  Map<String, dynamic> toJson() => {
        'characters': characters,
        'settings': settings,
        'foreshadowing': foreshadowing,
        'plot_points': plotPoints,
        'chapter_index': chapterIndex,
        'summary': summary,
      };
}

/// 故事分支
class StoryBranch {
  const StoryBranch({
    required this.id,
    required this.name,
    required this.forkPoint,
    this.parentBranchId = '',
    this.snapshot = const ContextSnapshot(),
    this.chapters = const [],
    this.createdAt = '',
    this.status = BranchStatus.active,
    this.tags = const [],
  });

  factory StoryBranch.fromJson(Map<String, dynamic> json) {
    return StoryBranch(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      forkPoint: json['fork_point'] as String? ?? '',
      parentBranchId: json['parent_branch_id'] as String? ?? '',
      snapshot: json['snapshot'] != null
          ? ContextSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>)
          : const ContextSnapshot(),
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['created_at'] as String? ?? '',
      status: BranchStatus.fromString(json['status'] as String? ?? 'active'),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  final String id;
  final String name;

  /// 分叉点标识（章节ID/位置描述）
  final String forkPoint;

  /// 父分支 ID（主线为空）
  final String parentBranchId;

  /// 分叉时的上下文快照
  final ContextSnapshot snapshot;

  /// 该分支的章节内容列表
  final List<String> chapters;

  final String createdAt;
  final BranchStatus status;
  final List<String> tags;

  bool get isMainLine => parentBranchId.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fork_point': forkPoint,
        'parent_branch_id': parentBranchId,
        'snapshot': snapshot.toJson(),
        'chapters': chapters,
        'created_at': createdAt,
        'status': status.name,
        'tags': tags,
      };

  StoryBranch copyWith({
    String? name,
    List<String>? chapters,
    BranchStatus? status,
    List<String>? tags,
  }) {
    return StoryBranch(
      id: id,
      name: name ?? this.name,
      forkPoint: forkPoint,
      parentBranchId: parentBranchId,
      snapshot: snapshot,
      chapters: chapters ?? this.chapters,
      createdAt: createdAt,
      status: status ?? this.status,
      tags: tags ?? this.tags,
    );
  }
}

/// 分支状态
enum BranchStatus {
  active,
  archived,
  merged;

  String get label => switch (this) {
        BranchStatus.active => '进行中',
        BranchStatus.archived => '已归档',
        BranchStatus.merged => '已合并',
      };

  static BranchStatus fromString(String s) {
    return BranchStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => BranchStatus.active,
    );
  }
}

/// 分支差异条目
class BranchDiffEntry {
  const BranchDiffEntry({
    required this.chapterIndex,
    required this.type,
    this.contentA = '',
    this.contentB = '',
  });

  final int chapterIndex;
  final DiffType type;
  final String contentA;
  final String contentB;
}

/// 差异类型
enum DiffType {
  added,
  removed,
  modified,
  identical;

  String get label => switch (this) {
        DiffType.added => '新增',
        DiffType.removed => '删除',
        DiffType.modified => '修改',
        DiffType.identical => '相同',
      };
}

/// 分支树节点
class BranchTreeNode {
  const BranchTreeNode({
    required this.branch,
    this.children = const [],
  });

  final StoryBranch branch;
  final List<BranchTreeNode> children;

  int get depth => children.isEmpty ? 0 : 1 + children.map((c) => c.depth).reduce((a, b) => a > b ? a : b);
}

// ─── 服务 ───

/// 平行世界服务
class ParallelWorldService {
  ParallelWorldService({
    required IProjectMetaRepository metaRepository,
    required AIProvider aiProvider,
  })  : _metaRepository = metaRepository,
        _aiProvider = aiProvider;

  final IProjectMetaRepository _metaRepository;
  final AIProvider _aiProvider;

  static const _storageKey = 'parallel_worlds';
  static int _idCounter = 0;

  // ─── 1. 分支 CRUD ───

  /// 获取项目所有分支
  Future<List<StoryBranch>> listBranches(String projectId) async {
    final data = await _metaRepository.read(projectId, _storageKey);
    if (data == null) return [];
    final list = (data['branches'] as List<dynamic>?) ?? [];
    return list
        .map((e) => StoryBranch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 创建分支（在指定分叉点）
  Future<StoryBranch> createBranch({
    required String projectId,
    required String name,
    required String forkPoint,
    String parentBranchId = '',
    ContextSnapshot snapshot = const ContextSnapshot(),
  }) async {
    final branches = await listBranches(projectId);

    final branch = StoryBranch(
      id: 'branch_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}',
      name: name,
      forkPoint: forkPoint,
      parentBranchId: parentBranchId,
      snapshot: snapshot,
      createdAt: DateTime.now().toIso8601String(),
    );

    branches.add(branch);
    await _save(projectId, branches);
    return branch;
  }

  /// 获取单个分支
  Future<StoryBranch?> getBranch(String projectId, String branchId) async {
    final branches = await listBranches(projectId);
    return branches.where((b) => b.id == branchId).firstOrNull;
  }

  /// 向分支添加章节
  Future<StoryBranch?> addChapter(
    String projectId,
    String branchId,
    String chapterContent,
  ) async {
    final branches = await listBranches(projectId);
    final idx = branches.indexWhere((b) => b.id == branchId);
    if (idx == -1) return null;

    final updated = branches[idx].copyWith(
      chapters: [...branches[idx].chapters, chapterContent],
    );
    branches[idx] = updated;
    await _save(projectId, branches);
    return updated;
  }

  /// 删除分支
  Future<bool> deleteBranch(String projectId, String branchId) async {
    final branches = await listBranches(projectId);
    final before = branches.length;
    branches.removeWhere((b) => b.id == branchId);
    // 同时删除以此分支为父的子分支
    branches.removeWhere((b) => b.parentBranchId == branchId);
    await _save(projectId, branches);
    return branches.length < before;
  }

  /// 归档分支
  Future<StoryBranch?> archiveBranch(
      String projectId, String branchId) async {
    return _updateStatus(projectId, branchId, BranchStatus.archived);
  }

  /// 标记合并
  Future<StoryBranch?> markMerged(
      String projectId, String branchId) async {
    return _updateStatus(projectId, branchId, BranchStatus.merged);
  }

  // ─── 2. 分支树 ───

  /// 构建分支树结构
  Future<List<BranchTreeNode>> buildTree(String projectId) async {
    final branches = await listBranches(projectId);
    return _buildTreeNodes(branches, '');
  }

  List<BranchTreeNode> _buildTreeNodes(
      List<StoryBranch> all, String parentId) {
    final children = all.where((b) => b.parentBranchId == parentId).toList();
    return children.map((b) {
      return BranchTreeNode(
        branch: b,
        children: _buildTreeNodes(all, b.id),
      );
    }).toList();
  }

  // ─── 3. 差异对比 ───

  /// 对比两个分支的章节差异
  Future<List<BranchDiffEntry>> diffBranches(
    String projectId,
    String branchIdA,
    String branchIdB,
  ) async {
    final branchA = await getBranch(projectId, branchIdA);
    final branchB = await getBranch(projectId, branchIdB);
    if (branchA == null || branchB == null) return [];

    final diffs = <BranchDiffEntry>[];
    final maxLen =
        branchA.chapters.length > branchB.chapters.length
            ? branchA.chapters.length
            : branchB.chapters.length;

    for (var i = 0; i < maxLen; i++) {
      final hasA = i < branchA.chapters.length;
      final hasB = i < branchB.chapters.length;

      if (hasA && !hasB) {
        diffs.add(BranchDiffEntry(
          chapterIndex: i,
          type: DiffType.removed,
          contentA: branchA.chapters[i],
        ));
      } else if (!hasA && hasB) {
        diffs.add(BranchDiffEntry(
          chapterIndex: i,
          type: DiffType.added,
          contentB: branchB.chapters[i],
        ));
      } else if (hasA && hasB) {
        final same = branchA.chapters[i] == branchB.chapters[i];
        diffs.add(BranchDiffEntry(
          chapterIndex: i,
          type: same ? DiffType.identical : DiffType.modified,
          contentA: branchA.chapters[i],
          contentB: branchB.chapters[i],
        ));
      }
    }

    return diffs;
  }

  // ─── 4. 成剧下游 ───

  /// 基于分支 IP 资产生成成剧提示词
  Future<String> buildDramaPrompt(
    String projectId,
    String branchId, {
    String styleHint = '国漫',
  }) async {
    final branch = await getBranch(projectId, branchId);
    if (branch == null) return '';

    final sb = StringBuffer();
    sb.writeln('【平行世界分支】${branch.name}');
    sb.writeln('分叉点: ${branch.forkPoint}');
    sb.writeln('风格: $styleHint');

    // 注入快照上下文
    final snap = branch.snapshot;
    if (snap.characters.isNotEmpty) {
      sb.writeln('\n【角色】');
      for (final c in snap.characters) {
        sb.writeln('- $c');
      }
    }
    if (snap.settings.isNotEmpty) {
      sb.writeln('\n【设定】');
      for (final s in snap.settings) {
        sb.writeln('- $s');
      }
    }
    if (snap.foreshadowing.isNotEmpty) {
      sb.writeln('\n【伏笔】');
      for (final f in snap.foreshadowing) {
        sb.writeln('- $f');
      }
    }

    // 注入章节内容
    if (branch.chapters.isNotEmpty) {
      sb.writeln('\n【章节内容】');
      for (var i = 0; i < branch.chapters.length; i++) {
        sb.writeln('第${i + 1}章: ${branch.chapters[i]}');
      }
    }

    return sb.toString();
  }

  /// 基于分支生成成剧方案（调用 AI）
  Future<String> generateDramaVersion(
    String projectId,
    String branchId, {
    String styleHint = '国漫',
  }) async {
    final prompt = await buildDramaPrompt(projectId, branchId,
        styleHint: styleHint);
    if (prompt.isEmpty) return '';

    try {
      return await _aiProvider.chatSync(
        messages: [
          const ChatMessage(
            role: 'system',
            content: '你是影视改编策划。基于提供的小说分支内容，生成该版本的成剧方案'
                '（含角色卡、分镜概要、场景列表）。',
          ),
          ChatMessage(role: 'user', content: prompt),
        ],
      );
    } catch (_) {
      return '';
    }
  }

  // ─── 辅助 ───

  Future<StoryBranch?> _updateStatus(
    String projectId,
    String branchId,
    BranchStatus status,
  ) async {
    final branches = await listBranches(projectId);
    final idx = branches.indexWhere((b) => b.id == branchId);
    if (idx == -1) return null;

    final updated = branches[idx].copyWith(status: status);
    branches[idx] = updated;
    await _save(projectId, branches);
    return updated;
  }

  Future<void> _save(String projectId, List<StoryBranch> branches) async {
    final data = {'branches': branches.map((b) => b.toJson()).toList()};
    await _metaRepository.write(projectId, _storageKey, data);
  }
}

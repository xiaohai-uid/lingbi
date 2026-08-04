import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/shared/errors/app_error.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';
import 'package:path/path.dart' as p;

import 'atomic_file_store.dart';
import 'mutation/file_canonical_store.dart';
import 'mutation/local_mutation_journal.dart';
import 'mutation/project_mutation_journal_factory.dart';
import '../../domain/mutation/canonical_revision.dart';
import '../../shared/interfaces/project_root_resolver.dart';

enum RecoveryItemType { candidate, version, snapshot, trash }

/// 一个待用户决定的恢复事故（MP-09）：崩溃/外部编辑后目标字节不确定，
/// 已被冻结；当前字节作为恢复候选保留，必须显式批准或放弃。
final class RecoveryIncident {
  const RecoveryIncident({
    required this.id,
    required this.projectId,
    required this.rootPath,
    required this.targetPath,
    required this.expectedHash,
    this.currentHash,
    this.currentContent,
    required this.createdAt,
  });

  /// intent id（journal 中持久化的 commit_intent）。
  final String id;

  /// 项目稳定标识（生产为 uuid，不一定是目录路径）。
  final String projectId;

  /// 解析后的项目根目录（经 rootResolver；无 resolver 时回退 projectId）。
  final String rootPath;

  /// 项目相对路径。
  final String targetPath;

  /// intent 期望落盘的字节 hash。
  final String expectedHash;

  /// 当前磁盘字节（恢复候选）。
  final String? currentHash;
  final String? currentContent;
  final DateTime createdAt;
}

class RecoveryItem {
  const RecoveryItem({
    required this.id,
    required this.type,
    required this.path,
    required this.title,
    required this.updatedAt,
    this.originalPath,
  });

  final String id;
  final RecoveryItemType type;
  final String path;
  final String title;
  final DateTime updatedAt;
  final String? originalPath;
}

class RecoveryCenterService {
  RecoveryCenterService({
    AtomicFileStore? atomicStore,
    required this.mutationProtocol,
    this.journal,
    this.canonicalStore,
    this.rootResolver,
    this.journalFactory,
    this.storeForRoot,
    this.projectIdProvider,
  }) : _atomicStore = atomicStore ?? AtomicFileStore();

  final AtomicFileStore _atomicStore;

  /// 变更协议：restore 经由此接口创建三记录不变量（origin: restore）。
  /// 必需注入；缺失时 fail-closed（拒绝恢复写入）。
  final MutationProtocol mutationProtocol;

  /// 恢复事故扫描所需的 journal 与 canonical store（MP-09）。
  /// 未注入时 scanIncidents 返回 NOT_CONFIGURED。
  final LocalMutationJournal? journal;
  final FileCanonicalStore? canonicalStore;

  /// 把项目稳定 id 解析为真实项目根（生产为 uuid → 目录）。
  /// 未注入时把 projectId 视为目录路径（测试/直连场景）。
  final ProjectRootResolver? rootResolver;

  /// 生产扫描：遍历已注册项目，为每个项目创建 project-owned journal/store。
  final ProjectMutationJournalFactory? journalFactory;
  final FileCanonicalStore Function(ResolvedProjectRoot)? storeForRoot;
  final Future<List<String>> Function()? projectIdProvider;

  /// 扫描未决 commit intent 中目标字节不确定（frozen）的恢复事故。
  /// 每个事故携带当前字节作为恢复候选。
  ///
  /// 同时覆盖已显式 targetFrozen 的 intent（reconciler/重试路径已写
  /// outcome 的冻结事故），保证冻结字节始终可见、可恢复。
  Future<Result<List<RecoveryIncident>>> scanIncidents() async {
    final singleJournal = journal;
    final singleStore = canonicalStore;
    if (singleJournal != null && singleStore != null) {
      return Result.success(await _scanProject(singleJournal, singleStore));
    }

    final factory = journalFactory;
    final storeBuilder = storeForRoot;
    final provider = projectIdProvider;
    final resolver = rootResolver;
    if (factory != null &&
        storeBuilder != null &&
        provider != null &&
        resolver != null) {
      final incidents = <RecoveryIncident>[];
      for (final projectId in await provider()) {
        final rootResult = await resolver.resolve(projectId);
        final root = rootResult.getOrNull();
        if (root == null) continue;
        final journalResult = await factory.forProject(projectId);
        final projectJournal = journalResult.getOrNull();
        if (projectJournal == null) continue;
        incidents.addAll(
          await _scanProject(projectJournal, storeBuilder(root)),
        );
      }
      return Result.success(incidents);
    }

    return Result.failure(FileError(
      'Recovery incidents require a journal and canonical store',
      code: 'NOT_CONFIGURED',
    ));
  }

  Future<List<RecoveryIncident>> _scanProject(
    LocalMutationJournal journal,
    FileCanonicalStore store,
  ) async {
    final incidents = <RecoveryIncident>[];
    final seen = <String>{};

    Future<void> consider(CommitIntent intent) async {
      final snapshot = await store.read(intent.targetPath);
      final currentHash = snapshot.getOrNull()?.hash;
      final currentMissing = snapshot.errorOrNull() != null;

      if (currentHash != null && currentHash == intent.expectedContentHash) {
        // apply 已落盘；不是事故。
        return;
      }
      final atBase = currentMissing
          ? intent.baseContentHash.isEmpty
          : currentHash == intent.baseContentHash &&
              intent.baseContentHash.isNotEmpty;
      if (atBase) {
        // 目标未被触碰；intent 从未 apply，不是事故。
        return;
      }
      if (seen.contains(intent.id)) return;
      seen.add(intent.id);
      incidents.add(RecoveryIncident(
        id: intent.id,
        projectId: intent.projectId,
        rootPath: await _resolveRoot(intent.projectId),
        targetPath: intent.targetPath,
        expectedHash: intent.expectedContentHash,
        currentHash: currentHash,
        currentContent: currentMissing ? null : snapshot.getOrNull()?.content,
        createdAt: DateTime.now().toUtc(),
      ));
    }

    for (final intent in await journal.readUnresolvedIntents()) {
      await consider(intent);
    }
    // targetFrozen outcomes：intent 已 resolve（不再 unresolved），但用户
    // 尚未决定；从 outcome 反查 intent 继续呈现事故。
    final frozenIntentIds = await _frozenIntentIds(journal);
    for (final intentId in frozenIntentIds) {
      final events = await journal.readByAggregate(intentId);
      for (final event in events) {
        if (event.eventType == LocalMutationJournal.commitIntentEventType) {
          await consider(CommitIntent.fromJson(event.payload));
          break;
        }
      }
    }
    return incidents;
  }

  Future<String> _resolveRoot(String projectId) async {
    final resolver = rootResolver;
    if (resolver == null) return projectId;
    final result = await resolver.resolve(projectId);
    return result.getOrNull()?.rootPath ?? projectId;
  }

  Future<List<String>> _frozenIntentIds(LocalMutationJournal journal) async {
    final events = await journal.readAll();
    final frozen = <String>[];
    for (final event in events) {
      if (event.eventType == LocalMutationJournal.recoveryOutcomeEventType) {
        final outcome = RecoveryOutcome.fromJson(event.payload);
        if (outcome.outcome == RecoveryOutcomeType.targetFrozen) {
          frozen.add(outcome.intentId);
        }
      }
    }
    return frozen.toSet().toList();
  }

  /// 用户对冻结事故的显式决定（MP-09）：
  /// - approveCurrentBytes=true：以当前字节为最终正文，补全 receipt。
  /// - approveCurrentBytes=false：把当前字节存入 trash 作为恢复候选
  ///   （可经 restore 重新批准），并显式放弃 intent。
  Future<Result<RecoveryOutcome>> decideIncident({
    required RecoveryIncident incident,
    required bool approveCurrentBytes,
  }) async {
    final journal = this.journal;
    final store = canonicalStore;
    if (journal == null || store == null) {
      return Result.failure(FileError(
        'Recovery incidents require a journal and canonical store',
        code: 'NOT_CONFIGURED',
      ));
    }

    if (approveCurrentBytes) {
      await journal.append(JournalEvent(
        eventId: 'evt-commit-recovered-${incident.id}',
        eventType: LocalMutationJournal.receiptEventType,
        aggregateId: incident.id,
        payload: CommitReceipt(
          id: 'rcpt-recovered-${incident.id}',
          candidateId: incident.id,
          approvalId: 'user-approved-frozen',
          idempotencyKey: 'recovered-${incident.id}',
          beforeRevision: 0,
          afterRevision: 1,
          affectedPaths: [incident.targetPath],
          committedAt: DateTime.now().toUtc(),
          receiptHash: canonicalTextHash(
            'recovered:${incident.id}:${incident.currentHash ?? ''}',
          ),
        ).toJson(),
      ));
      // 显式记录 intent 已解决（按 intentId），使后续扫描不再视为事故。
      await journal.appendRecoveryOutcome(RecoveryOutcome(
        id: 'outcome-${incident.id}-approved',
        intentId: incident.id,
        projectId: incident.projectId,
        targetPath: incident.targetPath,
        outcome: RecoveryOutcomeType.receiptCompleted,
        resolvedAt: DateTime.now().toUtc(),
        reason: 'user approved frozen current bytes as final content',
      ));
      return Result.success(RecoveryOutcome(
        id: 'outcome-${incident.id}-approved',
        intentId: incident.id,
        projectId: incident.projectId,
        targetPath: incident.targetPath,
        outcome: RecoveryOutcomeType.receiptCompleted,
        resolvedAt: DateTime.now().toUtc(),
        reason: 'user approved frozen current bytes as final content',
      ));
    }

    // Abandon: preserve current bytes as a trash recovery candidate.
    final currentContent = incident.currentContent;
    // 项目根 = 解析后的 rootPath（生产 projectId 为 uuid，不是目录）。
    final projectDir = incident.rootPath;
    final targetAbsolute = p.join(incident.rootPath, incident.targetPath);
    if (currentContent != null) {
      final trashDir = Directory(p.join(projectDir, '.lingbi', 'trash'));
      await trashDir.create(recursive: true);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final candidateFile = File(
        p.join(trashDir.path, '${stamp}_frozen_${p.basename(targetAbsolute)}'),
      );
      await _atomicStore.writeString(candidateFile.path, currentContent);
      final meta = File('${candidateFile.path}.meta.json');
      await _atomicStore.writeString(
        meta.path,
        jsonEncode({
          'originalPath': p.absolute(targetAbsolute),
          'sha256': incident.currentHash ?? '',
          'deletedAt': DateTime.now().toUtc().toIso8601String(),
          'recoveryFrom': 'frozen-${incident.id}',
        }),
      );
    }
    final outcome = RecoveryOutcome(
      id: 'outcome-${incident.id}-abandoned',
      intentId: incident.id,
      projectId: incident.projectId,
      targetPath: incident.targetPath,
      outcome: RecoveryOutcomeType.intentAbandoned,
      resolvedAt: DateTime.now().toUtc(),
      reason:
          'user abandoned frozen intent; current bytes preserved as recovery candidate',
    );
    await journal.appendRecoveryOutcome(outcome);
    return Result.success(outcome);
  }

  /// T04: Result 化——不抛异常，返回 Result<File>。
  Future<Result<File>> softDelete(String projectDir, String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      return Result.failure(
          FileError('File does not exist: $sourcePath', code: 'NOT_FOUND'));
    }
    final trashDir = Directory(p.join(projectDir, '.lingbi', 'trash'));
    await trashDir.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final target =
        File(p.join(trashDir.path, '${stamp}_${p.basename(sourcePath)}'));
    final bytes = await source.readAsBytes();
    await source.rename(target.path);
    await _atomicStore.writeString(
      '${target.path}.meta.json',
      jsonEncode({
        'originalPath': p.absolute(sourcePath),
        'sha256': sha256.convert(bytes).toString(),
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return Result.success(target);
  }

  Future<List<RecoveryItem>> scan(String projectDir) async {
    final roots = <RecoveryItemType, String>{
      RecoveryItemType.candidate: p.join(projectDir, '.lingbi', 'candidates'),
      RecoveryItemType.version: p.join(projectDir, '.lingbi', 'versions'),
      RecoveryItemType.snapshot: p.join(projectDir, '.lingbi', 'snapshots'),
      RecoveryItemType.trash: p.join(projectDir, '.lingbi', 'trash'),
    };
    final items = <RecoveryItem>[];
    for (final entry in roots.entries) {
      final dir = Directory(entry.value);
      if (!await dir.exists()) continue;
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File ||
            entity.path.endsWith('.meta.json') ||
            entity.path.endsWith('.bak') ||
            entity.path.endsWith('.tmp') ||
            p.basename(entity.path) == 'metadata.json') {
          continue;
        }
        final stat = await entity.stat();
        String? originalPath;
        if (entry.key == RecoveryItemType.trash) {
          final meta = File('${entity.path}.meta.json');
          if (await meta.exists()) {
            try {
              final map =
                  jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
              originalPath = map['originalPath'] as String?;
            } catch (_) {}
          }
        }
        items.add(RecoveryItem(
          id: sha256.convert(utf8.encode(entity.path)).toString(),
          type: entry.key,
          path: entity.path,
          title: p.basename(entity.path),
          updatedAt: stat.modified,
          originalPath: originalPath,
        ));
      }
    }
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  /// T04: Result 化——不抛异常，返回 Result<File>。
  Future<Result<File>> restore(RecoveryItem item, {String? targetPath}) async {
    final source = File(item.path);
    if (!await source.exists()) {
      return Result.failure(FileError(
          'Recovery item does not exist: ${item.path}',
          code: 'NOT_FOUND'));
    }
    final destinationPath = targetPath ?? item.originalPath;
    if (destinationPath == null) {
      return Result.failure(FileError(
          'A target path is required for this recovery item',
          code: 'NO_TARGET'));
    }
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    if (await destination.exists()) {
      return Result.failure(FileError(
          'Restore target already exists: ${destination.path}',
          code: 'CONFLICT'));
    }

    // T01: fail-closed — restore REQUIRE MutationProtocol
    final protocol = mutationProtocol;
    final content = await source.readAsString();
    // Derive project dir from item.path: <projectDir>/.lingbi/<type>/<file>
    final projectDir = p.dirname(p.dirname(p.dirname(item.path)));
    final relativePath = p.relative(destinationPath, from: projectDir);
    final editResult = await protocol.applyUserEdit(ChangeRequest(
      projectId: projectDir,
      origin: ChangeOrigin.restore,
      action: ChangeAction.restoreSnapshot,
      target: ChangeTarget(
        projectRelativePath: relativePath,
        kind: 'restore',
      ),
      baseRevision: 0,
      payload: content,
    ));
    if (editResult.errorOrNull() != null) {
      return Result.failure(editResult.errorOrNull()!);
    }

    await source.rename(destination.path);
    final meta = File('${item.path}.meta.json');
    if (await meta.exists()) await meta.delete();
    final metaBackup = File('${item.path}.meta.json.bak');
    if (await metaBackup.exists()) await metaBackup.delete();
    return Result.success(destination);
  }
}

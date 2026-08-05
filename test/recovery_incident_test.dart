import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/mutation/file_canonical_store.dart';
import 'package:lingbi/services/mutation/local_mutation_journal.dart';
import 'package:lingbi/services/mutation/local_mutation_protocol.dart';
import 'package:lingbi/services/recovery_center_service.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/project_root_resolver.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';

/// MP-09: recovery incident freeze and current-bytes-as-recovery-candidate.
///
/// Covers: indeterminate intent freeze, current bytes as recovery candidate,
/// explicit user decision (approve current bytes / abandon with candidate),
/// re-approval via the trash-backed recovery candidate, and uuid projectId
/// root resolution.
void main() {
  late Directory tempDir;
  late String projectRoot;
  late LocalMutationJournal journal;
  late FileCanonicalStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_incident_');
    projectRoot = '${tempDir.path}/project';
    _testRootPath = projectRoot;
    Directory(projectRoot).createSync(recursive: true);
    journal = LocalMutationJournal(
      basePath: '${tempDir.path}/journal',
    );
    store = FileCanonicalStore(
      projectRoot: projectRoot,
      atomicStore: AtomicFileStore(),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  RecoveryCenterService _service() => RecoveryCenterService(
        mutationProtocol: LocalMutationProtocol(
          journal: journal,
          store: store,
        ),
        journal: journal,
        canonicalStore: store,
        rootResolver: _ResolveToRoot(),
      );

  /// 构造一个"写入中途崩溃"的意图：intent 已持久化，但目标字节与
  /// base 和 expected 都不匹配（外部编辑或半截写入）。
  Future<void> _seedIndeterminateIntent() async {
    final intent = CommitIntent(
      id: 'intent-frozen-1',
      projectId: projectRoot,
      candidateId: 'cand-1',
      targetPath: 'chapters/ch01.md',
      baseRevision: 0,
      expectedRevision: 1,
      expectedContentHash: 'expected-hash-not-on-disk',
      idempotencyKey: 'idem-frozen',
      baseContentHash: 'base-hash',
    );
    await journal.appendCommitIntent(intent);
    // 当前字节与 base/expected 都不一致（半截写入/外部编辑）。
    File('$projectRoot/chapters/ch01.md')
      ..createSync(recursive: true)
      ..writeAsStringSync('半截或不一致的字节', flush: true);
  }

  group('recovery incident freeze', () {
    test(
        'indeterminate intent surfaces as a frozen incident with current bytes',
        () async {
      await _seedIndeterminateIntent();

      final incidents = await _service().scanIncidents();
      expect(incidents.errorOrNull(), isNull);
      expect(incidents.getOrNull()!.length, 1);

      final incident = incidents.getOrNull()!.single;
      expect(incident.id, 'intent-frozen-1');
      expect(incident.targetPath, 'chapters/ch01.md');
      expect(incident.currentContent, '半截或不一致的字节', reason: '当前字节必须作为恢复候选保留');
      expect(incident.currentHash, isNotNull);
    });

    test('matching target bytes do not surface as an incident', () async {
      // Apply 已成功落盘（字节 == expected）。
      final intent = CommitIntent(
        id: 'intent-ok-1',
        projectId: projectRoot,
        candidateId: 'cand-2',
        targetPath: 'chapters/ch02.md',
        baseRevision: 0,
        expectedRevision: 1,
        expectedContentHash: _textHash('完整内容'),
        idempotencyKey: 'idem-ok',
        baseContentHash: '',
      );
      await journal.appendCommitIntent(intent);
      File('$projectRoot/chapters/ch02.md')
        ..createSync(recursive: true)
        ..writeAsStringSync('完整内容', flush: true);

      final incidents = await _service().scanIncidents();
      expect(incidents.errorOrNull(), isNull);
      expect(incidents.getOrNull()!, isEmpty);
    });

    test('approving without current bytes fails closed instead of empty hash',
        () async {
      final intent = CommitIntent(
        id: 'intent-missing-current-1',
        projectId: projectRoot,
        candidateId: 'cand-missing-current',
        targetPath: 'chapters/missing-current.md',
        baseRevision: 0,
        expectedRevision: 1,
        expectedContentHash: 'expected-hash-missing-current',
        idempotencyKey: 'idem-missing-current',
        baseContentHash: 'base-hash',
      );
      await journal.appendCommitIntent(intent);

      final incident = (await _service().scanIncidents()).getOrNull()!.single;
      expect(incident.currentContent, isNull);
      expect(incident.currentHash, isNull);

      final decision = await _service().decideIncident(
        incident: incident,
        approveCurrentBytes: true,
      );
      expect(decision.errorOrNull(), isNotNull);
    });

    test('approve keeps current bytes and records the decision', () async {
      await _seedIndeterminateIntent();
      final incident = (await _service().scanIncidents()).getOrNull()!.single;

      final outcome = await _service().decideIncident(
        incident: incident,
        approveCurrentBytes: true,
      );
      expect(outcome.errorOrNull(), isNull);
      expect(
          outcome.getOrNull()!.outcome, RecoveryOutcomeType.receiptCompleted);

      // 当前字节被保留为最终正文。
      expect(
        File('$projectRoot/chapters/ch01.md').readAsStringSync(),
        '半截或不一致的字节',
      );
      // 该 intent 已解决，不再作为 incident。
      final again = await _service().scanIncidents();
      expect(again.getOrNull()!, isEmpty);
    });

    test('abandon preserves current bytes as a trash recovery candidate',
        () async {
      await _seedIndeterminateIntent();
      final incident = (await _service().scanIncidents()).getOrNull()!.single;

      final outcome = await _service().decideIncident(
        incident: incident,
        approveCurrentBytes: false,
      );
      expect(outcome.errorOrNull(), isNull);
      expect(outcome.getOrNull()!.outcome, RecoveryOutcomeType.intentAbandoned);

      // 当前字节已存入 .lingbi/trash 作为恢复候选，可被 recovery center 扫描。
      final items = await _service().scan(projectRoot);
      final trashCandidates =
          items.where((i) => i.type == RecoveryItemType.trash).toList();
      expect(trashCandidates, hasLength(1));
      expect(File(trashCandidates.single.path).readAsStringSync(), '半截或不一致的字节');
    });

    test('uuid projectId resolves to its root before writing trash', () async {
      // 生产语义：projectId 是 uuid，不是目录；trash 必须落在解析后的根。
      final intent = CommitIntent(
        id: 'intent-uuid-1',
        projectId: 'proj-uuid-1',
        candidateId: 'cand-uuid',
        targetPath: 'chapters/ch03.md',
        baseRevision: 0,
        expectedRevision: 1,
        expectedContentHash: 'expected-hash-uuid',
        idempotencyKey: 'idem-uuid',
        baseContentHash: 'base-hash',
      );
      await journal.appendCommitIntent(intent);
      File('$projectRoot/chapters/ch03.md')
        ..createSync(recursive: true)
        ..writeAsStringSync('uuid 场景的半截字节', flush: true);

      final incidents = await _service().scanIncidents();
      final incident = incidents.getOrNull()!.single;
      expect(incident.rootPath, projectRoot,
          reason: 'uuid 经 resolver 解析为真实项目根');

      final outcome = await _service().decideIncident(
        incident: incident,
        approveCurrentBytes: false,
      );
      expect(outcome.errorOrNull(), isNull);

      // trash 落在真实根目录内（不是 <cwd>/<uuid> 幻影目录）。
      final items = await _service().scan(projectRoot);
      final trashCandidates =
          items.where((i) => i.type == RecoveryItemType.trash).toList();
      expect(trashCandidates, hasLength(1));
      expect(
        trashCandidates.single.path,
        startsWith('$projectRoot${Platform.pathSeparator}.lingbi'),
      );
      expect(
          File(trashCandidates.single.path).readAsStringSync(), 'uuid 场景的半截字节');
    });

    test('re-approval restores the trash recovery candidate to a target',
        () async {
      await _seedIndeterminateIntent();
      final incident = (await _service().scanIncidents()).getOrNull()!.single;
      await _service().decideIncident(
        incident: incident,
        approveCurrentBytes: false,
      );

      // 用户重新批准：把 trash 恢复候选恢复到新目标（原目标仍存在，
      // restore 不覆盖已有文件——CONFLICT 语义保证不丢数据）。
      final items = await _service().scan(projectRoot);
      final candidate =
          items.where((i) => i.type == RecoveryItemType.trash).single;
      final recoveryTarget = '$projectRoot/chapters/ch01.recovered.md';
      final restored = await _service().restore(
        candidate,
        targetPath: recoveryTarget,
      );
      expect(restored.errorOrNull(), isNull,
          reason: '${restored.errorOrNull()}');
      expect(File(recoveryTarget).readAsStringSync(), '半截或不一致的字节');
    });
  });
}

String _textHash(String content) {
  final normalized = content.replaceAll('\r\n', '\n');
  return sha256.convert(utf8.encode(normalized)).toString();
}

/// 把任意 projectId 解析为测试项目根（生产 = uuid → 目录）。
class _ResolveToRoot implements ProjectRootResolver {
  @override
  Future<Result<ResolvedProjectRoot>> resolve(String projectId) async {
    final path = projectId == 'proj-uuid-1' ? _testRootPath : projectId;
    return Result.success(
      ResolvedProjectRoot(projectId: projectId, rootPath: path),
    );
  }
}

/// 测试项目根（setUp 时赋值，供 uuid → 目录解析）。
String _testRootPath = '';

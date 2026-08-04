import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/models/canon_entry.dart';
import 'package:lingbi/features/skill/data/skill/skill_audit_log.dart';
import 'package:lingbi/features/skill/data/skill/skill_executor.dart';
import 'package:lingbi/features/skill/data/skill/skill_manifest_verifier.dart';
import 'package:lingbi/features/skill/data/skill/skill_permission.dart';
import 'package:lingbi/features/skill/data/skill_marketplace.dart';
import 'package:lingbi/domain/mutation/mutation_models.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/interfaces/mutation_protocol.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_skill_security_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('signed manifest verification', () {
    test('rejects a declared file that escapes the package root', () {
      final manifest = _signedManifest(
        files: {'../secrets.txt': _digest('stolen')},
      );

      final result = _testVerifier().verify(
        manifest: manifest,
        packageFiles: {'../secrets.txt': utf8.encode('stolen')},
      );

      expect(result.isValid, isFalse);
      expect(result.failures, contains(SkillVerificationFailure.pathEscape));
    });

    test('rejects a package after signed content is tampered with', () {
      final manifest = _signedManifest(
        files: {'SKILL.md': _digest('approved')},
      );

      final result = _testVerifier().verify(
        manifest: manifest,
        packageFiles: {'SKILL.md': utf8.encode('tampered')},
      );

      expect(result.isValid, isFalse);
      expect(result.failures, contains(SkillVerificationFailure.hashMismatch));
    });

    test('rejects an older signed version than the installed version', () {
      final manifest = _signedManifest(
        version: '1.4.0',
        files: {'SKILL.md': _digest('approved')},
      );

      final result = _testVerifier().verify(
        manifest: manifest,
        packageFiles: {'SKILL.md': utf8.encode('approved')},
        installedVersion: '2.0.0',
      );

      expect(result.isValid, isFalse);
      expect(result.failures, contains(SkillVerificationFailure.versionRollback));
    });

    test('production rejects signed-looking packages when no trust root exists', () {
      final manifest = _signedManifest(
        files: {'SKILL.md': _digest('approved')},
      );
      const verifier = SkillManifestVerifier.production();

      final result = verifier.verify(
        manifest: manifest,
        packageFiles: {'SKILL.md': utf8.encode('approved')},
      );

      expect(result.isValid, isFalse);
      expect(result.failures, contains(SkillVerificationFailure.noTrustedRoot));
    });

    test('unsigned packages require an explicit development manifest and mode', () {
      final manifest = SkillPackageManifest(
        skillId: 'dev-skill',
        version: '0.1.0-dev',
        files: {'SKILL.md': _digest('local')},
        capabilities: const {'project.read'},
        signerId: null,
        signature: null,
        state: SkillPackageState.development,
      );
      const verifier = SkillManifestVerifier.development();

      final result = verifier.verify(
        manifest: manifest,
        packageFiles: {'SKILL.md': utf8.encode('local')},
      );

      expect(result.isValid, isTrue);
      expect(result.signatureStatus, SkillSignatureStatus.unsignedDevelopment);
    });
  });

  group('project-scoped runtime capabilities', () {
    test('blocks undeclared network access and records the attempt', () async {
      final external = _FakeExternalAccess();
      final audit = SkillAuditLog(
        filePath: '${tempDir.path}/audit.jsonl',
        clock: () => DateTime.utc(2026, 7, 28),
      );
      final api = SandboxedSkillApi(
        permissions: PermissionSet.fromStrings(const []),
        delegate: _FakeSkillApi(),
        projectId: 'project-a',
        skillId: 'malicious-skill',
        externalAccess: external,
        mutationProtocol: _NoopProtocol(),
        auditLog: audit,
      );

      await expectLater(
        api.networkGet(Uri.parse('https://example.com/private')),
        throwsA(isA<PermissionViolation>()),
      );
      expect(external.networkCalls, isEmpty);
      final records = await audit.readVerified();
      expect(records.single.operation, 'network.get');
      expect(records.single.outcome, SkillAuditOutcome.denied);
    });

    test('blocks undeclared secret access before reaching secure storage', () async {
      final external = _FakeExternalAccess();
      final api = SandboxedSkillApi(
        permissions: PermissionSet.fromStrings(const []),
        delegate: _FakeSkillApi(),
        projectId: 'project-a',
        skillId: 'malicious-skill',
        externalAccess: external,
        mutationProtocol: _NoopProtocol(),
      );

      await expectLater(
        api.readSecret('project-a', 'provider-token'),
        throwsA(isA<PermissionViolation>()),
      );
      expect(external.secretCalls, isEmpty);
    });

    test('a granted capability cannot be reused for another project', () async {
      final external = _FakeExternalAccess();
      final api = SandboxedSkillApi(
        permissions: PermissionSet.fromStrings(const []),
        delegate: _FakeSkillApi(),
        projectId: 'project-a',
        skillId: 'scoped-skill',
        capabilities: const {'secret.read:provider-token'},
        externalAccess: external,
        mutationProtocol: _NoopProtocol(),
      );

      await expectLater(
        api.readSecret('project-b', 'provider-token'),
        throwsA(isA<PermissionViolation>()),
      );
      expect(external.secretCalls, isEmpty);
    });

    test('project file access rejects traversal before reading the filesystem', () async {
      File('${tempDir.path}/project.txt').writeAsStringSync('safe');
      final api = SandboxedSkillApi(
        permissions: PermissionSet.fromStrings(const []),
        delegate: _FakeSkillApi(),
        projectId: 'project-a',
        skillId: 'path-skill',
        projectRoot: tempDir.path,
        capabilities: const {'project.file.read'},
        mutationProtocol: _NoopProtocol(),
      );

      await expectLater(
        api.readProjectFile('project-a', '../outside.txt'),
        throwsA(isA<PermissionViolation>()),
      );
    });
  });

  group('append-only skill audit log', () {
    test('exposes immutable records and detects on-disk edits', () async {
      final auditFile = File('${tempDir.path}/audit.jsonl');
      final audit = SkillAuditLog(
        filePath: auditFile.path,
        clock: () => DateTime.utc(2026, 7, 28, 1, 2, 3),
      );
      await audit.append(
        skillId: 'safe-skill',
        projectId: 'project-a',
        operation: 'document.read',
        outcome: SkillAuditOutcome.allowed,
        details: const {'documentId': 'chapter-1'},
      );

      final records = await audit.readVerified();
      expect(() => records.add(records.single), throwsUnsupportedError);
      expect(
        () => records.single.details['documentId'] = 'chapter-2',
        throwsUnsupportedError,
      );

      final tampered = auditFile.readAsStringSync().replaceFirst(
            'chapter-1',
            'chapter-X',
          );
      auditFile.writeAsStringSync(tampered);
      await expectLater(audit.readVerified(), throwsA(isA<AuditIntegrityException>()));
    });
  });

  group('marketplace provenance and rollback metadata', () {
    test('offline updates show permission diff and can restore the prior version', () async {
      final marketplace = SkillMarketplace(
        installDir: tempDir.path,
        manifestVerifier: _testVerifier(),
      );
      addTearDown(marketplace.dispose);

      final v1 = _offlinePackage(
        version: '1.0.0',
        content: 'version one',
        capabilities: const {'project.file.read'},
        packagePath: 'D:/packages/writer.skillpkg',
      );
      final v2 = _offlinePackage(
        version: '2.0.0',
        content: 'version two',
        capabilities: const {'project.file.read', 'network:example.com'},
        packagePath: 'D:/packages/writer-v2.skillpkg',
      );

      expect(await marketplace.installOfflinePackage(v1), isTrue);
      expect(await marketplace.installOfflinePackage(v2), isTrue);

      final metadata = await marketplace.readInstallMetadata('writer-skill');
      expect(metadata, isNotNull);
      expect(metadata!.source, SkillInstallSource.offlinePackage);
      expect(metadata.version, '2.0.0');
      expect(metadata.signerId, 'test-root');
      expect(metadata.signatureStatus, SkillSignatureStatus.verified);
      expect(metadata.sourceUri, 'D:/packages/writer-v2.skillpkg');
      expect(metadata.permissionDiff.added, {'network:example.com'});
      expect(metadata.permissionDiff.removed, isEmpty);

      expect(await marketplace.rollback('writer-skill'), isTrue);
      expect(
        File('${tempDir.path}/writer-skill/SKILL.md').readAsStringSync(),
        'version one',
      );
      final rolledBack = await marketplace.readInstallMetadata('writer-skill');
      expect(rolledBack!.version, '1.0.0');
    });
  });
}

String _digest(String value) => sha256.convert(utf8.encode(value)).toString();

SkillManifestVerifier _testVerifier() => const SkillManifestVerifier(
      trustedSigners: {
        'test-root': SkillTrustedSigner.testOnly(
          id: 'test-root',
          key: 'lingbi-test-signing-key-not-for-production',
        ),
      },
      allowTestSigners: true,
    );

SkillPackageManifest _signedManifest({
  String version = '1.0.0',
  required Map<String, String> files,
  Set<String> capabilities = const {'project.file.read'},
}) {
  final unsigned = SkillPackageManifest(
    skillId: 'writer-skill',
    version: version,
    files: files,
    capabilities: capabilities,
    signerId: 'test-root',
    signature: null,
    state: SkillPackageState.test,
  );
  return unsigned.copyWith(
    signature: SkillManifestVerifier.createTestSignature(
      unsigned,
      key: 'lingbi-test-signing-key-not-for-production',
    ),
  );
}

OfflineSkillPackage _offlinePackage({
  required String version,
  required String content,
  required Set<String> capabilities,
  required String packagePath,
}) {
  return OfflineSkillPackage(
    manifest: _signedManifest(
      version: version,
      files: {'SKILL.md': _digest(content)},
      capabilities: capabilities,
    ),
    files: {'SKILL.md': utf8.encode(content)},
    packagePath: packagePath,
  );
}

class _FakeExternalAccess implements SkillExternalAccess {
  final List<Uri> networkCalls = [];
  final List<String> secretCalls = [];

  @override
  Future<String> networkGet(Uri uri) async {
    networkCalls.add(uri);
    return 'ok';
  }

  @override
  Future<String?> readSecret(String projectId, String key) async {
    secretCalls.add('$projectId:$key');
    return 'secret';
  }
}

class _FakeSkillApi implements SkillApi {
  @override
  Future<List<CanonEntry>> canonRead(String projectId) async => const [];

  @override
  Future<void> canonWrite(String projectId, CanonEntry entry) async {}

  @override
  Future<String> documentRead(String projectId, String documentId) async => '';

  @override
  Future<void> documentWrite(
    String projectId,
    String documentId,
    String content,
  ) async {}
}

class _NoopProtocol implements MutationProtocol {
  @override
  Future<Result<CandidateChange>> propose(ChangeRequest request) async =>
      Result.success(CandidateChange(
        id: 'noop-cand',
        projectId: request.projectId,
        origin: request.origin,
        action: request.action,
        target: request.target,
        baseRevision: request.baseRevision,
        payloadHash: 'noop',
        actionHash: 'noop',
        createdAt: DateTime.now().toUtc(),
        state: CandidateState.proposed,
      ));

  @override
  Future<Result<ApprovalDecision>> decide(ApprovalCommand command) async =>
      Result.success(ApprovalDecision(
        id: 'noop-appr',
        candidateId: command.candidateId,
        candidateHash: 'noop',
        actionHash: 'noop',
        baseRevision: 0,
        actorId: command.actorId,
        approved: command.approved,
        decidedAt: DateTime.now().toUtc(),
        policy: command.policy,
      ));

  @override
  Future<Result<CommitReceipt>> commit(CommitCommand command) async =>
      Result.success(CommitReceipt(
        id: 'noop-rcpt',
        candidateId: command.candidateId,
        approvalId: command.approvalId,
        idempotencyKey: command.idempotencyKey,
        beforeRevision: 0,
        afterRevision: 1,
        affectedPaths: const [],
        committedAt: DateTime.now().toUtc(),
        receiptHash: 'noop',
      ));

  @override
  Future<Result<CommitReceipt>> applyUserEdit(ChangeRequest request) async =>
      commit(CommitCommand(
        candidateId: 'noop-cand',
        approvalId: 'noop-appr',
        idempotencyKey: request.idempotencyKey ?? 'noop-idem',
      ));

  @override
  Future<Result<void>> reject(RejectCommand command) async =>
      Result.success(null);

  @override
  Future<Result<List<RecoveryOutcome>>> reconcilePending(
          String projectId) async =>
      Result.success(const []);
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/domain/collaboration/role.dart';
import 'package:lingbi/services/collaboration_service.dart';

void main() {
  late Directory tempDir;
  late CollaborationService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_collab_');
    service = CollaborationService(storageDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('role permissions', () {
    test('owner has full permissions', () {
      final role = CollaborationRole.owner;
      expect(role.canEdit, isTrue);
      expect(role.canReview, isTrue);
      expect(role.canApprove, isTrue);
      expect(role.canManageRoles, isTrue);
      expect(role.canDelete, isTrue);
    });

    test('editor can edit but not manage roles or delete', () {
      final role = CollaborationRole.editor;
      expect(role.canEdit, isTrue);
      expect(role.canReview, isTrue);
      expect(role.canApprove, isFalse);
      expect(role.canManageRoles, isFalse);
      expect(role.canDelete, isFalse);
    });

    test('reviewer can review and comment but not edit', () {
      final role = CollaborationRole.reviewer;
      expect(role.canEdit, isFalse);
      expect(role.canReview, isTrue);
      expect(role.canApprove, isTrue);
      expect(role.canManageRoles, isFalse);
      expect(role.canDelete, isFalse);
    });

    test('viewer has read-only access', () {
      final role = CollaborationRole.viewer;
      expect(role.canEdit, isFalse);
      expect(role.canReview, isFalse);
      expect(role.canApprove, isFalse);
      expect(role.canManageRoles, isFalse);
      expect(role.canDelete, isFalse);
    });
  });

  group('collaboration operations', () {
    test('assigns roles and persists them', () async {
      await service.assignRole(
        projectId: 'proj-1',
        userId: 'user-a',
        role: CollaborationRole.editor,
      );

      final members = await service.getMembers('proj-1');
      expect(members, hasLength(1));
      expect(members.first.userId, 'user-a');
      expect(members.first.role, CollaborationRole.editor);
    });

    test('denies edit permission for viewer', () async {
      await service.assignRole(
        projectId: 'proj-1',
        userId: 'user-b',
        role: CollaborationRole.viewer,
      );

      final allowed = await service.checkPermission(
        projectId: 'proj-1',
        userId: 'user-b',
        action: CollaborationAction.edit,
      );

      expect(allowed, isFalse);
    });

    test('records audit log for role changes', () async {
      await service.assignRole(
        projectId: 'proj-1',
        userId: 'user-a',
        role: CollaborationRole.owner,
      );
      await service.assignRole(
        projectId: 'proj-1',
        userId: 'user-a',
        role: CollaborationRole.editor,
      );

      final audit = await service.getAuditLog('proj-1');
      expect(audit, hasLength(2));
      expect(audit.first.action, 'role_assigned');
      expect(audit.last.details['new_role'], 'editor');
    });

    test('single-user mode keeps confirmation lightweight', () async {
      // No members assigned = single-user mode
      final allowed = await service.checkPermission(
        projectId: 'proj-1',
        userId: 'solo-user',
        action: CollaborationAction.edit,
      );

      // Single-user mode grants all permissions
      expect(allowed, isTrue);
    });
  });
}

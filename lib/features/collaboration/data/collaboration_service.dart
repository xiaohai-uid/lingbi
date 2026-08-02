/// Collaboration service for studio roles, comments, approvals, and audit.
///
/// Single-user mode keeps confirmation lightweight (all permissions granted).
/// When members are configured, role-based access control is enforced.
library;

import 'dart:convert';
import 'dart:io';

import 'package:lingbi/domain/collaboration/role.dart';

export 'package:lingbi/domain/collaboration/role.dart';

/// A project member with a role.
class ProjectMember {
  const ProjectMember({
    required this.userId,
    required this.role,
    required this.assignedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) => ProjectMember(
        userId: json['user_id'] as String,
        role: CollaborationRole.values.byName(json['role'] as String),
        assignedAt: DateTime.parse(json['assigned_at'] as String),
      );

  final String userId;
  final CollaborationRole role;
  final DateTime assignedAt;

  Map<String, Object?> toJson() => {
        'user_id': userId,
        'role': role.name,
        'assigned_at': assignedAt.toUtc().toIso8601String(),
      };
}

/// An audit log entry.
class AuditEntry {
  const AuditEntry({
    required this.timestamp,
    required this.userId,
    required this.action,
    required this.details,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        userId: json['user_id'] as String,
        action: json['action'] as String,
        details: (json['details'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString())),
      );

  final DateTime timestamp;
  final String userId;
  final String action;
  final Map<String, String> details;

  Map<String, Object?> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'user_id': userId,
        'action': action,
        'details': details,
      };
}

class CollaborationService {
  CollaborationService({required this.storageDir});

  final String storageDir;

  String _membersFile(String projectId) =>
      '$storageDir/$projectId/collaboration/members.json';
  String _auditFile(String projectId) =>
      '$storageDir/$projectId/collaboration/audit.jsonl';

  Future<List<ProjectMember>> getMembers(String projectId) async {
    final file = File(_membersFile(projectId));
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ProjectMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> assignRole({
    required String projectId,
    required String userId,
    required CollaborationRole role,
  }) async {
    final members = await getMembers(projectId);
    members.removeWhere((m) => m.userId == userId);
    members.add(ProjectMember(
      userId: userId,
      role: role,
      assignedAt: DateTime.now().toUtc(),
    ));

    final dir = Directory('$storageDir/$projectId/collaboration');
    await dir.create(recursive: true);
    await File(_membersFile(projectId)).writeAsString(
      jsonEncode(members.map((m) => m.toJson()).toList()),
      flush: true,
    );

    // Audit
    await _appendAudit(projectId, AuditEntry(
      timestamp: DateTime.now().toUtc(),
      userId: userId,
      action: 'role_assigned',
      details: {'new_role': role.name},
    ));
  }

  Future<bool> checkPermission({
    required String projectId,
    required String userId,
    required CollaborationAction action,
  }) async {
    final members = await getMembers(projectId);

    // Single-user mode: no members configured, grant all
    if (members.isEmpty) return true;

    final member = members.where((m) => m.userId == userId).firstOrNull;
    if (member == null) return false;

    return action.isAllowedBy(member.role);
  }

  Future<List<AuditEntry>> getAuditLog(String projectId) async {
    final file = File(_auditFile(projectId));
    if (!await file.exists()) return [];
    final lines = await file.readAsLines();
    return lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) => AuditEntry.fromJson(jsonDecode(l) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _appendAudit(String projectId, AuditEntry entry) async {
    final dir = Directory('$storageDir/$projectId/collaboration');
    await dir.create(recursive: true);
    final file = File(_auditFile(projectId));
    await file.writeAsString(
      '${jsonEncode(entry.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }
}

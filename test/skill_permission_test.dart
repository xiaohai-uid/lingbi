import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/skill/skill_permission.dart';

void main() {
  group('SkillPermission', () {
    test('fromString 解析 canon.read', () {
      expect(SkillPermission.fromString('canon.read'), SkillPermission.canonRead);
    });

    test('fromString 解析 canon.write', () {
      expect(SkillPermission.fromString('canon.write'), SkillPermission.canonWrite);
    });

    test('fromString 解析 document.read', () {
      expect(SkillPermission.fromString('document.read'), SkillPermission.documentRead);
    });

    test('fromString 解析 document.write', () {
      expect(SkillPermission.fromString('document.write'), SkillPermission.documentWrite);
    });

    test('fromString 解析 storybeat.read', () {
      expect(SkillPermission.fromString('storybeat.read'), SkillPermission.storybeatRead);
    });

    test('fromString 解析 storybeat.write', () {
      expect(SkillPermission.fromString('storybeat.write'), SkillPermission.storybeatWrite);
    });

    test('fromString 无效权限字符串抛出 FormatException', () {
      expect(() => SkillPermission.fromString('canon.delete'), throwsFormatException);
      expect(() => SkillPermission.fromString('invalid'), throwsFormatException);
    });
  });

  group('PermissionSet', () {
    test('defaultLightweight 包含所有 read 权限', () {
      final perms = PermissionSet.defaultLightweight();
      expect(perms.can(SkillPermission.canonRead), true);
      expect(perms.can(SkillPermission.documentRead), true);
      expect(perms.can(SkillPermission.storybeatRead), true);
    });

    test('defaultLightweight 不包含任何 write 权限', () {
      final perms = PermissionSet.defaultLightweight();
      expect(perms.can(SkillPermission.canonWrite), false);
      expect(perms.can(SkillPermission.documentWrite), false);
      expect(perms.can(SkillPermission.storybeatWrite), false);
    });

    test('fromStrings 解析权限列表', () {
      final perms = PermissionSet.fromStrings(['canon.read', 'canon.write']);
      expect(perms.can(SkillPermission.canonRead), true);
      expect(perms.can(SkillPermission.canonWrite), true);
      expect(perms.can(SkillPermission.documentRead), false);
    });

    test('fromStrings 无效权限抛出 FormatException', () {
      expect(() => PermissionSet.fromStrings(['canon.delete']), throwsFormatException);
    });

    test('空权限集', () {
      final perms = PermissionSet.fromStrings([]);
      expect(perms.can(SkillPermission.canonRead), false);
    });

    test('containsAll 检查多个权限', () {
      final perms = PermissionSet.fromStrings(['canon.read', 'document.read', 'canon.write']);
      expect(perms.containsAll([SkillPermission.canonRead, SkillPermission.documentRead]), true);
      expect(perms.containsAll([SkillPermission.canonRead, SkillPermission.storybeatWrite]), false);
    });
  });
}

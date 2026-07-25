/// Skill 权限枚举
enum SkillPermission {
  canonRead,
  canonWrite,
  documentRead,
  documentWrite,
  storybeatRead,
  storybeatWrite;

  /// 从字符串解析权限（如 'canon.read' → canonRead）
  static SkillPermission fromString(String value) {
    switch (value) {
      case 'canon.read':
        return SkillPermission.canonRead;
      case 'canon.write':
        return SkillPermission.canonWrite;
      case 'document.read':
        return SkillPermission.documentRead;
      case 'document.write':
        return SkillPermission.documentWrite;
      case 'storybeat.read':
        return SkillPermission.storybeatRead;
      case 'storybeat.write':
        return SkillPermission.storybeatWrite;
      default:
        throw FormatException('无效的权限声明: $value');
    }
  }

  /// 转为字符串表示
  String get value {
    switch (this) {
      case SkillPermission.canonRead:
        return 'canon.read';
      case SkillPermission.canonWrite:
        return 'canon.write';
      case SkillPermission.documentRead:
        return 'document.read';
      case SkillPermission.documentWrite:
        return 'document.write';
      case SkillPermission.storybeatRead:
        return 'storybeat.read';
      case SkillPermission.storybeatWrite:
        return 'storybeat.write';
    }
  }
}

/// 权限集合
class PermissionSet {
  final Set<SkillPermission> _permissions;

  PermissionSet._(this._permissions);

  /// 轻量 Skill 默认权限：所有 read 权限
  factory PermissionSet.defaultLightweight() {
    return PermissionSet._({
      SkillPermission.canonRead,
      SkillPermission.documentRead,
      SkillPermission.storybeatRead,
    });
  }

  /// 从字符串列表构建权限集
  factory PermissionSet.fromStrings(List<String> values) {
    return PermissionSet._(
      values.map(SkillPermission.fromString).toSet(),
    );
  }

  /// 检查是否拥有指定权限
  bool can(SkillPermission permission) => _permissions.contains(permission);

  /// 检查是否拥有所有指定权限
  bool containsAll(List<SkillPermission> permissions) {
    return permissions.every(_permissions.contains);
  }

  /// 获取所有权限
  Set<SkillPermission> get all => Set.unmodifiable(_permissions);
}

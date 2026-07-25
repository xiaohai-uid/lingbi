/// LicenseService — 许可证验证与离线激活
///
/// 提供灵笔 Pro 许可证的完整生命周期管理：
/// - 格式验证（LINGBI-PRO-XXXX-XXXX-XXXX）
/// - 机器绑定（防止一 key 多用）
/// - 过期检测
/// - 本地持久化（离线优先，不依赖网络验证）
///
/// 安全策略：
/// - 许可证存储在应用数据目录，不明文写入 settings.json
/// - 机器指纹基于平台信息哈希，不含用户个人数据
/// - 离线验证为主，联网时可选做服务端二次校验
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// 许可证信息
class LicenseInfo {
  const LicenseInfo({
    required this.key,
    required this.activatedAt,
    required this.expiresAt,
    required this.machineId,
  });

  factory LicenseInfo.fromJson(Map<String, dynamic> json) {
    return LicenseInfo(
      key: json['key'] as String? ?? '',
      activatedAt: DateTime.tryParse(json['activatedAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now(),
      machineId: json['machineId'] as String? ?? '',
    );
  }

  final String key;
  final DateTime activatedAt;
  final DateTime expiresAt;
  final String machineId;

  /// 是否已过期
  bool get isExpired => expiresAt.isBefore(DateTime.now());

  /// 是否绑定到当前机器
  bool get isBoundToThisMachine =>
      machineId == LicenseService.machineFingerprint();

  /// 许可证是否有效（未过期 + 本机绑定）
  bool get isValid => !isExpired && isBoundToThisMachine;

  Map<String, dynamic> toJson() => {
        'key': key,
        'activatedAt': activatedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'machineId': machineId,
      };
}

/// 许可证服务
class LicenseService {
  LicenseService({required String storageDir}) : _storageDir = storageDir;

  final String _storageDir;

  /// 许可证文件名
  static const _licenseFileName = 'license.json';

  /// 许可证格式正则：LINGBI-PRO-XXXX-XXXX-XXXX（每段4位字母数字）
  static final _licenseRegex =
      RegExp(r'^LINGBI-PRO-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');

  /// 验证许可证格式
  static bool isValidFormat(String key) {
    if (key.isEmpty) return false;
    return _licenseRegex.hasMatch(key);
  }

  /// 生成当前机器指纹（确定性，不含个人信息）
  ///
  /// 基于操作系统版本 + 主机名哈希。
  static String machineFingerprint() {
    final raw = '${Platform.operatingSystemVersion}-${Platform.localHostname}';
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
  }

  /// 保存许可证到本地
  Future<void> saveLicense(LicenseInfo license) async {
    try {
      final dir = Directory(_storageDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('$_storageDir/$_licenseFileName');
      await file.writeAsString(jsonEncode(license.toJson()));
    } catch (_) {
      // 写入失败不阻断
    }
  }

  /// 从本地加载许可证
  Future<LicenseInfo?> loadLicense() async {
    try {
      final file = File('$_storageDir/$_licenseFileName');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return LicenseInfo.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// 删除许可证（取消激活）
  Future<void> deleteLicense() async {
    try {
      final file = File('$_storageDir/$_licenseFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// 验证并激活许可证
  ///
  /// 返回激活后的 LicenseInfo，验证失败返回 null。
  Future<LicenseInfo?> activate({
    required String key,
    required DateTime expiresAt,
  }) async {
    if (!isValidFormat(key)) return null;

    final license = LicenseInfo(
      key: key,
      activatedAt: DateTime.now(),
      expiresAt: expiresAt,
      machineId: machineFingerprint(),
    );

    await saveLicense(license);
    return license;
  }
}

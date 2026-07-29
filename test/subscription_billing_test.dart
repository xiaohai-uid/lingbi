/// 批次5 测试 — 收费系统
///
/// 验证：
/// 1. SubscriptionTier 分层模型（Free/Pro）
/// 2. SubscriptionService 功能门禁（FeatureGate）
/// 3. LicenseService 许可证验证（格式/过期/机器绑定/离线）
/// 4. QuotaService 与 Pro 集成（Pro 无限制）
/// 5. 模型套餐数据模型
@Timeout(Duration(seconds: 30))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/settings/data/subscription_service.dart';
import 'package:lingbi/services/license_service.dart';

void main() {
  // ═══════════════════════════════════════════════════════
  // 1. 订阅层模型
  // ═══════════════════════════════════════════════════════
  group('SubscriptionTier 分层', () {
    test('Free 层默认值', () {
      const sub = SubscriptionState();
      expect(sub.tier, SubscriptionTier.free);
      expect(sub.isPro, false);
      expect(sub.isActive, true); // Free 永远活跃
    });

    test('Pro 层含过期时间', () {
      final sub = SubscriptionState(
        tier: SubscriptionTier.pro,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        licenseKey: 'LINGBI-PRO-XXXX-YYYY-ZZZZ',
      );
      expect(sub.isPro, true);
      expect(sub.isActive, true);
      expect(sub.expiresAt, isNotNull);
    });

    test('Pro 过期后 isActive 为 false', () {
      final sub = SubscriptionState(
        tier: SubscriptionTier.pro,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(sub.isPro, true);
      expect(sub.isActive, false);
    });

    test('JSON 序列化往返', () {
      final sub = SubscriptionState(
        tier: SubscriptionTier.pro,
        expiresAt: DateTime(2027),
        licenseKey: 'LINGBI-PRO-1234-5678-9ABC',
      );
      final json = sub.toJson();
      expect(json['tier'], 'pro');
      expect(json['licenseKey'], 'LINGBI-PRO-1234-5678-9ABC');

      final restored = SubscriptionState.fromJson(json);
      expect(restored.tier, SubscriptionTier.pro);
      expect(restored.licenseKey, 'LINGBI-PRO-1234-5678-9ABC');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 2. 功能门禁
  // ═══════════════════════════════════════════════════════
  group('FeatureGate 功能门禁', () {
    test('Free 层可用功能', () {
      const sub = SubscriptionState();
      expect(sub.canAccess(ProFeature.localEditing), true);
      expect(sub.canAccess(ProFeature.basicSkills), true);
      expect(sub.canAccess(ProFeature.basicExport), true);
      expect(sub.canAccess(ProFeature.byoApiKey), true);
    });

    test('Free 层不可用功能', () {
      const sub = SubscriptionState();
      expect(sub.canAccess(ProFeature.cloudSync), false);
      expect(sub.canAccess(ProFeature.advancedExport), false);
      expect(sub.canAccess(ProFeature.batchOperations), false);
      expect(sub.canAccess(ProFeature.officialModelPlan), false);
    });

    test('Pro 层全部功能可用', () {
      final sub = SubscriptionState(
        tier: SubscriptionTier.pro,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      for (final feature in ProFeature.values) {
        expect(sub.canAccess(feature), true, reason: '$feature should be accessible');
      }
    });

    test('Pro 过期后高级功能不可用', () {
      final sub = SubscriptionState(
        tier: SubscriptionTier.pro,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(sub.canAccess(ProFeature.cloudSync), false);
      expect(sub.canAccess(ProFeature.localEditing), true); // 基础功能仍可用
    });

    test('SubscriptionService 门禁检查', () {
      final service = SubscriptionService();
      // 默认 Free
      expect(service.canAccess(ProFeature.localEditing), true);
      expect(service.canAccess(ProFeature.cloudSync), false);
    });

    test('SubscriptionService 激活 Pro', () {
      final service = SubscriptionService();
      service.activatePro(
        licenseKey: 'LINGBI-PRO-TEST-KEY-001',
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
      expect(service.isPro, true);
      expect(service.canAccess(ProFeature.cloudSync), true);
      expect(service.canAccess(ProFeature.advancedExport), true);
    });

    test('SubscriptionService 降级回 Free', () {
      final service = SubscriptionService();
      service.activatePro(
        licenseKey: 'KEY',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(service.isPro, true);

      service.deactivate();
      expect(service.isPro, false);
      expect(service.canAccess(ProFeature.cloudSync), false);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 3. 许可证验证
  // ═══════════════════════════════════════════════════════
  group('LicenseService 许可证', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('license_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('许可证格式验证 — 有效', () {
      expect(
        LicenseService.isValidFormat('LINGBI-PRO-ABCD-EF12-3456'),
        true,
      );
    });

    test('许可证格式验证 — 无效（前缀错误）', () {
      expect(
        LicenseService.isValidFormat('INVALID-PRO-ABCD-EF12-3456'),
        false,
      );
    });

    test('许可证格式验证 — 无效（段数不对）', () {
      expect(LicenseService.isValidFormat('LINGBI-PRO-ABCD'), false);
    });

    test('许可证格式验证 — 空字符串', () {
      expect(LicenseService.isValidFormat(''), false);
    });

    test('生成机器指纹（确定性）', () {
      final fp1 = LicenseService.machineFingerprint();
      final fp2 = LicenseService.machineFingerprint();
      expect(fp1, isNotEmpty);
      expect(fp1, fp2); // 同一机器相同
    });

    test('许可证激活与持久化', () async {
      final service = LicenseService(storageDir: tempDir.path);

      final license = LicenseInfo(
        key: 'LINGBI-PRO-TEST-1234-5678',
        activatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 365)),
        machineId: LicenseService.machineFingerprint(),
      );

      await service.saveLicense(license);
      final loaded = await service.loadLicense();

      expect(loaded, isNotNull);
      expect(loaded!.key, 'LINGBI-PRO-TEST-1234-5678');
      expect(loaded.isExpired, false);
      expect(loaded.isBoundToThisMachine, true);
    });

    test('过期许可证检测', () {
      final license = LicenseInfo(
        key: 'LINGBI-PRO-EXPIRED-KEY-001',
        activatedAt: DateTime.now().subtract(const Duration(days: 400)),
        expiresAt: DateTime.now().subtract(const Duration(days: 35)),
        machineId: LicenseService.machineFingerprint(),
      );
      expect(license.isExpired, true);
      expect(license.isValid, false);
    });

    test('机器绑定验证', () {
      final license = LicenseInfo(
        key: 'LINGBI-PRO-OTHER-MACHINE-01',
        activatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        machineId: 'different-machine-id',
      );
      expect(license.isBoundToThisMachine, false);
      expect(license.isValid, false); // 非本机 → 无效
    });

    test('无许可证文件时返回 null', () async {
      final service = LicenseService(storageDir: tempDir.path);
      final loaded = await service.loadLicense();
      expect(loaded, isNull);
    });

    test('LicenseInfo JSON 序列化', () {
      final license = LicenseInfo(
        key: 'LINGBI-PRO-JSON-TEST-001',
        activatedAt: DateTime(2026, 7),
        expiresAt: DateTime(2027, 7),
        machineId: 'test-machine',
      );
      final json = license.toJson();
      expect(json['key'], 'LINGBI-PRO-JSON-TEST-001');
      expect(json['machineId'], 'test-machine');

      final restored = LicenseInfo.fromJson(json);
      expect(restored.key, license.key);
      expect(restored.expiresAt, license.expiresAt);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 4. QuotaService 与 Pro 集成
  // ═══════════════════════════════════════════════════════
  group('Quota Pro 集成', () {
    test('SubscriptionService 提供每日限额', () {
      final service = SubscriptionService();
      expect(service.dailyLimit, SubscriptionService.freeDailyLimit);
    });

    test('Pro 用户每日限额为无限制', () {
      final service = SubscriptionService();
      service.activatePro(
        licenseKey: 'KEY',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(service.dailyLimit, -1); // -1 表示无限制
    });
  });

  // ═══════════════════════════════════════════════════════
  // 5. 模型套餐
  // ═══════════════════════════════════════════════════════
  group('模型套餐', () {
    test('ModelPlan 数据模型', () {
      const plan = ModelPlan(
        id: 'lingbi-standard',
        name: '灵笔标准套餐',
        provider: 'lingbi',
        pricePerMonth: 29.9,
        includedTokens: 500000,
        models: ['deepseek-chat', 'gpt-4o-mini'],
      );
      expect(plan.id, 'lingbi-standard');
      expect(plan.pricePerMonth, 29.9);
      expect(plan.includedTokens, 500000);
      expect(plan.models.length, 2);
    });

    test('ModelPlan JSON 序列化', () {
      const plan = ModelPlan(
        id: 'lingbi-pro',
        name: '灵笔专业套餐',
        provider: 'lingbi',
        pricePerMonth: 99,
        includedTokens: 2000000,
        models: ['deepseek-chat', 'gpt-4o', 'claude-sonnet'],
      );
      final json = plan.toJson();
      expect(json['id'], 'lingbi-pro');
      expect(json['includedTokens'], 2000000);

      final restored = ModelPlan.fromJson(json);
      expect(restored.name, '灵笔专业套餐');
      expect(restored.models.length, 3);
    });

    test('UsageRecord 用量记录', () {
      final record = UsageRecord(
        planId: 'lingbi-standard',
        usedTokens: 125000,
        periodStart: DateTime(2026, 7),
        periodEnd: DateTime(2026, 8),
      );
      expect(record.usedTokens, 125000);
      expect(record.periodStart.month, 7);
    });

    test('UsageRecord 剩余额度计算', () {
      const plan = ModelPlan(
        id: 'test',
        name: '测试',
        provider: 'lingbi',
        pricePerMonth: 0,
        includedTokens: 500000,
        models: [],
      );
      final record = UsageRecord(
        planId: 'test',
        usedTokens: 200000,
        periodStart: DateTime.now(),
        periodEnd: DateTime.now().add(const Duration(days: 30)),
      );
      expect(record.remainingTokens(plan), 300000);
    });
  });
}

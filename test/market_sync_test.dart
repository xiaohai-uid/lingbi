/// 批次4 测试 — 市场情报 + 云同步
///
/// 验证：
/// 1. Project 模型新增 targetPlatform/genre/audience 字段（向后兼容）
/// 2. MarketIntelService 数据模型 + 本地缓存 + 拉取逻辑
/// 3. SettingsService 匿名数据贡献开关
/// 4. WebDAV 同步服务（配置模型 + 同步状态机）
/// 5. GenerationContext 市场上下文注入
@Timeout(Duration(seconds: 30))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/project.dart';
import 'package:lingbi/services/market_intel_service.dart';
import 'package:lingbi/services/sync/webdav_service.dart';
import 'package:lingbi/services/sync/sync_manager.dart';

void main() {
  // ═══════════════════════════════════════════════════════
  // 1. Project 模型 — 市场情报字段
  // ═══════════════════════════════════════════════════════
  group('Project 模型市场字段', () {
    test('默认值为空（向后兼容）', () {
      final project = Project(
        name: '测试小说',
        directoryPath: '/tmp/novel',
      );
      expect(project.targetPlatform, '');
      expect(project.genre, '');
      expect(project.audience, '');
    });

    test('可设置目标平台/题材/读者画像', () {
      final project = Project(
        name: '玄幻大作',
        directoryPath: '/tmp/novel',
        targetPlatform: '起点中文网',
        genre: '玄幻',
        audience: '18-25岁男性',
      );
      expect(project.targetPlatform, '起点中文网');
      expect(project.genre, '玄幻');
      expect(project.audience, '18-25岁男性');
    });

    test('toJson/fromJson 序列化往返', () {
      final project = Project(
        name: '都市言情',
        directoryPath: '/tmp/romance',
        targetPlatform: '番茄小说',
        genre: '都市',
        audience: '20-35岁女性',
      );
      final json = project.toJson();
      expect(json['targetPlatform'], '番茄小说');
      expect(json['genre'], '都市');
      expect(json['audience'], '20-35岁女性');

      final restored = Project.fromJson(json);
      expect(restored.targetPlatform, '番茄小说');
      expect(restored.genre, '都市');
      expect(restored.audience, '20-35岁女性');
    });

    test('旧版 JSON（无新字段）反序列化不报错', () {
      final oldJson = {
        'id': 'proj-001',
        'name': '旧项目',
        'description': '',
        'directoryPath': '/tmp/old',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final project = Project.fromJson(oldJson);
      expect(project.name, '旧项目');
      expect(project.targetPlatform, '');
      expect(project.genre, '');
      expect(project.audience, '');
    });

    test('字段可修改（mutable）', () {
      final project = Project(
        name: '测试',
        directoryPath: '/tmp',
      );
      project.targetPlatform = '七猫';
      project.genre = '悬疑';
      project.audience = '全年龄';
      expect(project.targetPlatform, '七猫');
      expect(project.genre, '悬疑');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 2. MarketIntelService — 市场情报
  // ═══════════════════════════════════════════════════════
  group('MarketIntelService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('market_intel_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('MarketTrendEntry 数据模型', () {
      const entry = MarketTrendEntry(
        title: '斗破苍穹',
        platform: '起点中文网',
        genre: '玄幻',
        rank: 1,
        heatScore: 98500,
        tags: ['热血', '升级', '废柴逆袭'],
      );
      expect(entry.title, '斗破苍穹');
      expect(entry.platform, '起点中文网');
      expect(entry.genre, '玄幻');
      expect(entry.rank, 1);
      expect(entry.heatScore, 98500);
      expect(entry.tags.length, 3);
    });

    test('MarketTrendEntry JSON 序列化', () {
      const entry = MarketTrendEntry(
        title: '测试作品',
        platform: '番茄',
        genre: '都市',
        rank: 5,
        heatScore: 12000,
        tags: ['甜宠'],
      );
      final json = entry.toJson();
      expect(json['title'], '测试作品');
      expect(json['heat_score'], 12000);

      final restored = MarketTrendEntry.fromJson(json);
      expect(restored.title, '测试作品');
      expect(restored.rank, 5);
    });

    test('MarketIntelSnapshot 快照模型', () {
      final snapshot = MarketIntelSnapshot(
        platform: '起点中文网',
        genre: '玄幻',
        fetchedAt: DateTime.now(),
        trends: const [
          MarketTrendEntry(
            title: '作品A',
            platform: '起点',
            genre: '玄幻',
            rank: 1,
            heatScore: 99000,
          ),
        ],
        avgChapterWords: 3200,
        hotTags: const ['系统', '重生', '无敌'],
      );
      expect(snapshot.trends.length, 1);
      expect(snapshot.avgChapterWords, 3200);
      expect(snapshot.hotTags.length, 3);
    });

    test('本地缓存写入和读取', () async {
      final service = MarketIntelService(cacheDir: tempDir.path);

      final snapshot = MarketIntelSnapshot(
        platform: '起点',
        genre: '玄幻',
        fetchedAt: DateTime.now(),
        trends: const [
          MarketTrendEntry(
            title: '缓存测试',
            platform: '起点',
            genre: '玄幻',
            rank: 1,
            heatScore: 5000,
          ),
        ],
        avgChapterWords: 2800,
        hotTags: const ['测试'],
      );

      await service.saveCache(snapshot);
      final loaded = await service.loadCache('起点', '玄幻');

      expect(loaded, isNotNull);
      expect(loaded!.trends.first.title, '缓存测试');
      expect(loaded.avgChapterWords, 2800);
    });

    test('缓存不存在时返回 null', () async {
      final service = MarketIntelService(cacheDir: tempDir.path);
      final result = await service.loadCache('不存在', '不存在');
      expect(result, isNull);
    });

    test('生成市场上下文摘要（注入 AI）', () {
      final snapshot = MarketIntelSnapshot(
        platform: '起点',
        genre: '玄幻',
        fetchedAt: DateTime.now(),
        trends: const [
          MarketTrendEntry(
            title: '热门A',
            platform: '起点',
            genre: '玄幻',
            rank: 1,
            heatScore: 99000,
            tags: ['系统', '无敌'],
          ),
          MarketTrendEntry(
            title: '热门B',
            platform: '起点',
            genre: '玄幻',
            rank: 2,
            heatScore: 88000,
            tags: ['重生'],
          ),
        ],
        avgChapterWords: 3100,
        hotTags: const ['系统', '重生', '无敌', '升级'],
      );

      final context = MarketIntelService.buildContextSummary(snapshot);
      expect(context, contains('起点'));
      expect(context, contains('玄幻'));
      expect(context, contains('3100'));
      expect(context, contains('系统'));
      expect(context, contains('热门A'));
    });

    test('空快照生成空上下文', () {
      final context = MarketIntelService.buildContextSummary(null);
      expect(context, '');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 3. WebDAV 同步
  // ═══════════════════════════════════════════════════════
  group('WebDAV 同步', () {
    test('WebDavConfig 数据模型', () {
      const config = WebDavConfig(
        serverUrl: 'https://dav.example.com/lingbi',
        username: 'user@test.com',
        password: 'secret',
      );
      expect(config.serverUrl, 'https://dav.example.com/lingbi');
      expect(config.username, 'user@test.com');
      expect(config.isEnabled, true);
    });

    test('WebDavConfig 禁用状态', () {
      const config = WebDavConfig(
        serverUrl: '',
        username: '',
        password: '',
        enabled: false,
      );
      expect(config.isEnabled, false);
    });

    test('WebDavConfig JSON 序列化（不暴露密码）', () {
      const config = WebDavConfig(
        serverUrl: 'https://dav.jianguoyun.com/dav',
        username: 'myuser',
        password: 'mypassword',
      );
      final json = config.toJson();
      expect(json['serverUrl'], 'https://dav.jianguoyun.com/dav');
      expect(json['username'], 'myuser');
      // 密码不在普通 JSON 中暴露
      expect(json.containsKey('password'), false);
    });

    test('WebDavConfig fromJson 完整恢复', () {
      final json = {
        'serverUrl': 'https://dav.example.com',
        'username': 'test',
        'enabled': true,
      };
      final config = WebDavConfig.fromJson(json);
      expect(config.serverUrl, 'https://dav.example.com');
      expect(config.username, 'test');
      expect(config.isEnabled, true);
      expect(config.password, ''); // 密码需从安全存储恢复
    });

    test('SyncStatus 状态模型', () {
      const status = SyncStatus(
        state: SyncState.idle,
      );
      expect(status.state, SyncState.idle);
      expect(status.isIdle, true);
      expect(status.isSyncing, false);
    });

    test('SyncStatus 同步中状态', () {
      final status = SyncStatus(
        state: SyncState.syncing,
        lastSyncAt: DateTime.now(),
        progress: '正在上传 3/10 个文件...',
      );
      expect(status.isSyncing, true);
      expect(status.progress, isNotEmpty);
    });

    test('SyncManager 初始状态为 idle', () {
      final manager = SyncManager(
        config: const WebDavConfig(
          serverUrl: '',
          username: '',
          password: '',
          enabled: false,
        ),
      );
      expect(manager.status.state, SyncState.idle);
      expect(manager.isConfigured, false);
    });

    test('SyncManager 配置检查', () {
      final manager = SyncManager(
        config: const WebDavConfig(
          serverUrl: 'https://dav.example.com',
          username: 'user',
          password: 'pass',
        ),
      );
      expect(manager.isConfigured, true);
    });

    test('SyncConflict 冲突模型', () {
      final conflict = SyncConflict(
        filePath: '/projects/novel/ch1.md',
        localModified: DateTime.now(),
        remoteModified: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(conflict.filePath, contains('ch1.md'));
      expect(conflict.localModified.isAfter(conflict.remoteModified), true);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 4. 匿名数据贡献开关
  // ═══════════════════════════════════════════════════════
  group('匿名数据贡献', () {
    test('AnalyticsConsent 默认开启', () {
      final consent = AnalyticsConsent();
      expect(consent.enabled, true);
      expect(consent.anonymousId, isNotEmpty);
    });

    test('AnalyticsConsent 可关闭', () {
      final consent = AnalyticsConsent(enabled: false);
      expect(consent.enabled, false);
    });

    test('AnalyticsConsent JSON 序列化', () {
      final consent = AnalyticsConsent();
      final json = consent.toJson();
      expect(json['enabled'], true);
      expect(json['anonymousId'], isNotEmpty);

      final restored = AnalyticsConsent.fromJson(json);
      expect(restored.enabled, true);
      expect(restored.anonymousId, consent.anonymousId);
    });

    test('AnalyticsPayload 只含匿名统计', () {
      const payload = AnalyticsPayload(
        anonymousId: 'anon-123',
        genre: '玄幻',
        platform: '起点',
        totalWords: 150000,
        chapterCount: 50,
        skillUsageCount: {'smart-continuation': 30, 'dialogue-polish': 15},
      );
      final json = payload.toJson();
      // 不包含任何可识别信息
      expect(json.containsKey('username'), false);
      expect(json.containsKey('email'), false);
      expect(json.containsKey('projectName'), false);
      expect(json['genre'], '玄幻');
      expect(json['totalWords'], 150000);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 5. 市场上下文注入 GenerationContext
  // ═══════════════════════════════════════════════════════
  group('市场上下文注入', () {
    test('Project 市场字段生成上下文片段', () {
      final project = Project(
        name: '我的小说',
        directoryPath: '/tmp',
        targetPlatform: '起点中文网',
        genre: '玄幻',
        audience: '18-25岁男性读者',
      );

      final fragment = buildMarketContextFragment(project);
      expect(fragment, contains('起点中文网'));
      expect(fragment, contains('玄幻'));
      expect(fragment, contains('18-25岁男性读者'));
    });

    test('无市场字段时返回空字符串', () {
      final project = Project(
        name: '空白项目',
        directoryPath: '/tmp',
      );
      final fragment = buildMarketContextFragment(project);
      expect(fragment, '');
    });

    test('部分字段有值时只包含有值部分', () {
      final project = Project(
        name: '半配置',
        directoryPath: '/tmp',
        genre: '悬疑',
      );
      final fragment = buildMarketContextFragment(project);
      expect(fragment, contains('悬疑'));
      expect(fragment, isNot(contains('目标平台')));
    });
  });
}

/// 从 Project 市场字段构建上下文片段（与 ProjectDataSource 中逻辑一致）
String buildMarketContextFragment(Project project) {
  final parts = <String>[];
  if (project.targetPlatform.isNotEmpty) {
    parts.add('目标平台: ${project.targetPlatform}');
  }
  if (project.genre.isNotEmpty) {
    parts.add('题材: ${project.genre}');
  }
  if (project.audience.isNotEmpty) {
    parts.add('目标读者: ${project.audience}');
  }
  if (parts.isEmpty) return '';
  return '【市场定位】\n${parts.join('\n')}';
}

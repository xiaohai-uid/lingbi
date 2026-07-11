// 灵笔 v4.0 — 全栈集成测试
// 运行: flutter test test/integration_test/
// 前提: docker compose up -d 已运行
// TDD 红: 首次运行预期失败（服务未部署）
// TDD 绿: 部署后全部通过

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  final baseUrl = 'http://localhost:8080';
  
  group('Phase 1: 健康检查', () {
    test('API Gateway 健康检查', () async {
      final resp = await http.get(Uri.parse('$baseUrl/health'));
      expect(resp.statusCode, 200);
      final body = jsonDecode(resp.body);
      expect(body['status'], 'ok');
    });

    test('Project Service 健康检查', () async {
      final resp = await http.get(Uri.parse('http://localhost:8082/health'));
      expect(resp.statusCode, 200);
    });

    test('Settings Service 健康检查', () async {
      final resp = await http.get(Uri.parse('http://localhost:8087/health'));
      expect(resp.statusCode, 200);
    });

    test('Quota Service 健康检查', () async {
      final resp = await http.get(Uri.parse('http://localhost:8088/health'));
      expect(resp.statusCode, 200);
    });
  });

  group('Phase 2: 核心 API', () {
    late String worldId;

    test('Create World', () async {
      final resp = await http.post(
        Uri.parse('http://localhost:8082/api/v1/worlds'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': '测试世界',
          'description': '集成测试用',
          'genres': ['玄幻']
        }),
      );
      expect(resp.statusCode, 201);
      final body = jsonDecode(resp.body);
      expect(body['name'], '测试世界');
      worldId = body['id'];
    });

    test('List Worlds', () async {
      final resp = await http.get(
        Uri.parse('http://localhost:8082/api/v1/worlds'),
      );
      expect(resp.statusCode, 200);
      final worlds = jsonDecode(resp.body) as List;
      expect(worlds.isNotEmpty, true);
    });

    test('Create Work', () async {
      final resp = await http.post(
        Uri.parse('http://localhost:8082/api/v1/works'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'world_id': worldId,
          'title': '测试作品',
          'description': '集成测试作品'
        }),
      );
      expect(resp.statusCode, 201);
      final body = jsonDecode(resp.body);
      expect(body['title'], '测试作品');
    });
  });

  group('Phase 3: 配额与设置', () {
    test('Set Setting', () async {
      final resp = await http.put(
        Uri.parse('http://localhost:8087/api/v1/settings/theme'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'value': 'dark'}),
      );
      expect(resp.statusCode, 200);
    });

    test('Get Setting', () async {
      final resp = await http.get(
        Uri.parse('http://localhost:8087/api/v1/settings/theme'),
      );
      expect(resp.statusCode, 200);
      final body = jsonDecode(resp.body);
      expect(body['value'], 'dark');
    });

    test('Quota Check', () async {
      final resp = await http.post(
        Uri.parse('http://localhost:8088/api/v1/quota/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'test-user',
          'model': 'gpt-4o'
        }),
      );
      expect(resp.statusCode, 200);
      final body = jsonDecode(resp.body);
      expect(body.containsKey('remaining'), true);
      expect(body['remaining'], greaterThan(0));
    });

    test('Quota Consume', () async {
      final resp = await http.post(
        Uri.parse('http://localhost:8088/api/v1/quota/consume'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'test-user',
          'model': 'gpt-4o',
          'tokens': 100
        }),
      );
      expect(resp.statusCode, 200);
      final body = jsonDecode(resp.body);
      expect(body['tokens_used'], 100);
    });
  });

  group('Phase 4: 画布与时间线', () {
    test('Timeline Create Event', () async {
      final resp = await http.post(
        Uri.parse('http://localhost:8094/api/v1/timeline'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'world_id': 'test-world',
          'title': '关键事件',
          'description': '故事转折点',
          'story_time': 1000,
          'involved_character_ids': ['char-1']
        }),
      );
      expect(resp.statusCode, 201);
    });

    test('Faction Create', () async {
      final resp = await http.post(
        Uri.parse('http://localhost:8095/api/v1/factions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'world_id': 'test-world',
          'name': '青云门',
          'description': '修仙门派'
        }),
      );
      expect(resp.statusCode, 201);
    });

    test('Canvas Create Node', () async {
      final resp = await http.post(
        Uri.parse('http://localhost:8091/api/v1/canvas/nodes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chapter_id': 'ch-1',
          'title': '开场',
          'summary': '故事开始',
          'characters': ['张三'],
          'location': '青云山',
          'mood': '平静'
        }),
      );
      expect(resp.statusCode, 201);
    });
  });

  group('Phase 5: 认证流程', () {
    test('Auth Login', () async {
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'test',
          'password': 'test'
        }),
      );
      expect(resp.statusCode, 200);
      final body = jsonDecode(resp.body);
      expect(body.containsKey('token'), true);
    });
  });
}
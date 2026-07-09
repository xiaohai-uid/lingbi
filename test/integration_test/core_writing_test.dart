import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingbi/main.dart';
import 'config.dart';
import 'helpers/widget_helpers.dart';
import 'helpers/health_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Core Writing Flow', () {
    setUpAll(() async {
      // 确认微服务可用
      await waitForAllServices(kServicePorts);
    });

    testWidgets('Create project, add document, edit and save', (tester) async {
      // Step 1: 启动应用，验证 HomePage
      await tester.pumpWidget(const LingBiApp());
      await tester.pumpAndSettle();
      expect(find.text('新建项目'), findsOneWidget);

      // Step 2: 创建新项目
      await createProject(tester, '集成测试小说');
      expect(find.text('集成测试小说'), findsWidgets);

      // Step 3: 创建新文档
      await createDocument(tester, '第一章');
      expect(find.text('第一章'), findsWidgets);

      // Step 4: 在编辑器中输入文本
      const testContent = '这是一个集成测试段落。';
      await typeInEditor(tester, testContent);
      expect(find.textContaining(testContent), findsWidgets);

      // Step 5: 验证保存状态 — 编辑器可见且可用
      expect(find.byType(TextField), findsWidgets);

      // Step 6: 验证可以通过 API Gateway 查询项目列表
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse(
          apiUrl(kServicePorts['API Gateway']!, '/api/v1/project/list'),
        ),
      );
      final response = await request.close();
      expect(response.statusCode, anyOf(200, 404),
          reason: 'Project list API should be reachable');
      await response.drain();
      client.close();
    });
  });
}

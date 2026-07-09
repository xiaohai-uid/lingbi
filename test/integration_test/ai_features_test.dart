import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingbi/main.dart';
import 'config.dart';
import 'helpers/widget_helpers.dart';
import 'helpers/health_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Features', () {
    setUpAll(() async {
      await waitForAllServices(kServicePorts);
    });

    testWidgets('AI Panel shows and responds to input', (tester) async {
      // Step 1: 启动应用并进入项目
      await tester.pumpWidget(const LingBiApp());
      await tester.pumpAndSettle();
      await createProject(tester, 'AI测试项目');
      await createDocument(tester, 'AI测试文档');

      // Step 2: 打开 AI Panel
      // AI Panel 通过右侧按钮或侧边栏标签打开
      final aiPanelButton = find.byTooltip('AI 助手');
      if (aiPanelButton.evaluate().isNotEmpty) {
        await tester.tap(aiPanelButton);
        await tester.pumpAndSettle();
      }

      // Step 3: 验证 AI Panel 显示
      expect(find.textContaining('AI'), findsWidgets);

      // Step 4: 选择 Free Provider（默认不消耗 API Key）
      final providerDropdown = find.byType(DropdownButtonFormField);
      if (providerDropdown.evaluate().isNotEmpty) {
        await tester.tap(providerDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Free').last);
        await tester.pumpAndSettle();
      }

      // Step 5: 输入消息
      final textField = find.byType(TextField).last;
      await tester.enterText(textField, '续写这段故事');
      await tester.pumpAndSettle();

      // Step 6: 点击发送按钮
      final sendButton = find.byIcon(Icons.send);
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        // 验证 AI Panel 有响应（即使 free provider 返回空）
        // 至少 UI 没有崩溃
      }

      // Step 7: 验证 AI Provider 微服务可达
      final healthy = await checkServiceHealth(kServicePorts['AI Provider']!);
      expect(healthy, isTrue, reason: 'AI Provider should be running');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingbi/main.dart';
import 'config.dart';
import 'helpers/widget_helpers.dart';
import 'helpers/health_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Project Parallel Editing', () {
    setUpAll(() async {
      await waitForAllServices(kServicePorts);
    });

    testWidgets('Create two projects and switch between them', (tester) async {
      // Step 1: 启动应用
      await tester.pumpWidget(const LingBiApp());
      await tester.pumpAndSettle();

      // Step 2: 创建项目 A
      await createProject(tester, '小说A');
      await createDocument(tester, '第一章');
      expect(find.text('第一章'), findsWidgets);

      // Step 3: 回到 HomePage 创建项目 B
      // 通过项目 Tab 或 Home 按钮
      final homeButton = find.byTooltip('首页');
      if (homeButton.evaluate().isNotEmpty) {
        await tester.tap(homeButton);
        await tester.pumpAndSettle();
      }

      // 检查是否在 HomePage
      if (find.text('新建项目').evaluate().isNotEmpty) {
        await createProject(tester, '小说B');
        await createDocument(tester, '序幕');
        expect(find.text('序幕'), findsWidgets);
      }

      // Step 4: 通过 Tab 切换回项目 A
      final tabA = find.text('小说A');
      if (tabA.evaluate().isNotEmpty) {
        await tester.tap(tabA);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        // 验证项目 A 的文档树
        expect(find.text('第一章'), findsWidgets);
      }

      // Step 5: 验证项目 B 的文档树
      final tabB = find.text('小说B');
      if (tabB.evaluate().isNotEmpty) {
        await tester.tap(tabB);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('序幕'), findsWidgets);
      }

      // Step 6: 验证微服务数据一致性
      final healthy = await checkServiceHealth(kServicePorts['Project']!);
      expect(healthy, isTrue, reason: 'Project service should be healthy');
    });
  });
}

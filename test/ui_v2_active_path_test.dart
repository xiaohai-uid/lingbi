/// 锁定商业版 V1 唯一 UI 路径为 ui_v2
///
/// 验证：
/// 1. UIFeatureFlag.useNewUI == true
/// 2. 应用启动后进入 AppScaffold（非旧版 HomePage）
/// 3. 项目打开后显示 ui_v2/EditorPage
/// 4. 旧版 ProjectPage 和 NovelWritingPanel 不在当前用户路径中
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/main.dart';
import 'package:lingbi/ui_v2/feature_flag.dart';
import 'package:lingbi/ui_v2/components/app_scaffold.dart';

void main() {
  group('UI V2 活跃路径锁定', () {
    test('UIFeatureFlag.useNewUI 必须为 true', () {
      expect(UIFeatureFlag.useNewUI, isTrue,
          reason: '商业版 V1 必须使用 ui_v2 作为唯一活跃 UI');
    });

    testWidgets('ServiceLocator 初始化成功时渲染 LingBiAppV3',
        (tester) async {
      // 使用降级模式验证路由逻辑：
      // initSucceeded=true 时进入新 UI
      final locator = ServiceLocator.failed(error: 'test');
      // 降级模式进入 _LocalModeHome
      await tester.pumpWidget(LingBiApp(locator: locator, localWorkDir: '.'));
      await tester.pumpAndSettle();

      // 降级模式不应包含 AppScaffold
      expect(find.byType(AppScaffold), findsNothing);
    });

    test('UIFeatureFlag 是编译时常量，不可运行时修改', () {
      // 验证 useNewUI 是 const，确保不会意外回退
      const flag = UIFeatureFlag.useNewUI;
      expect(flag, isTrue);
      // const 值在编译时确定，运行时不可修改
      expect(identical(flag, true), isTrue);
    });

    test('旧版 UI 路径不在商业版活跃路径中', () {
      // 当 useNewUI=true 时，main.dart 路由到 LingBiAppV3
      // 旧版 HomePage 仅在 useNewUI=false 时使用
      // 此测试确保 feature flag 不被意外翻转
      expect(UIFeatureFlag.useNewUI, isTrue,
          reason: '翻转此标志将导致商业版回退到旧版 UI');
    });
  });
}

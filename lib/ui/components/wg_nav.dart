import 'package:flutter/material.dart';

import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/ui/components/wg_sidebar.dart';
import 'package:lingbi/ui/pages/wg_dashboard_page.dart';
import 'package:lingbi/ui/pages/wg_workspace_page.dart';
import 'package:lingbi/ui/pages/wg_editor_page.dart';
import 'package:lingbi/ui/pages/canon_page.dart';
import 'package:lingbi/ui/pages/story_canvas_page.dart';
import 'package:lingbi/ui/pages/settings_page.dart';

/// 灵笔统一导航：6 个核心页面。
/// 所有页面的侧边栏共用，消除重复的导航代码。
List<WgNavItem> wgNavItems(BuildContext context, String active) => [
  WgNavItem(
    icon: Icons.dashboard_outlined,
    label: '仪表盘',
    active: active == 'dashboard',
    onTap: active == 'dashboard'
        ? null
        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WgDashboardPage())),
  ),
  WgNavItem(
    icon: Icons.folder_copy_outlined,
    label: '工作区',
    active: active == 'workspace',
    onTap: active == 'workspace' ? null : () => openFirstWorkspace(context),
  ),
  WgNavItem(
    icon: Icons.edit_note_outlined,
    label: '编辑器',
    active: active == 'editor',
    onTap: active == 'editor'
        ? null
        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WgEditorPage())),
  ),
  WgNavItem(
    icon: Icons.auto_stories_outlined,
    label: '知识库',
    active: active == 'canon',
    onTap: active == 'canon'
        ? null
        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanonPage())),
  ),
  WgNavItem(
    icon: Icons.hub_outlined,
    label: '故事画布',
    active: active == 'story_canvas',
    onTap: active == 'story_canvas'
        ? null
        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryCanvasPage())),
  ),
  WgNavItem(
    icon: Icons.settings_outlined,
    label: '设置',
    active: active == 'settings',
    onTap: active == 'settings'
        ? null
        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
  ),
];

/// 打开工作区：进入第一个世界；无世界时回仪表盘。
Future<void> openFirstWorkspace(BuildContext context) async {
  try {
    final worlds = await ServiceLocator.instance.worldService.listWorlds();
    if (!context.mounted) return;
    if (worlds.isEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WgDashboardPage()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WgWorkspacePage(world: worlds.first)));
    }
  } catch (_) {
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WgDashboardPage()));
    }
  }
}
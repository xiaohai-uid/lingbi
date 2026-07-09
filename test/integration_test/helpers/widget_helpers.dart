import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

/// 在 HomePage 创建新项目
Future<void> createProject(WidgetTester tester, String name) async {
  // 点击"新建项目"按钮
  await tester.tap(find.text('新建项目'));
  await tester.pumpAndSettle();

  // 输入项目名称（对话框中的 TextField）
  await tester.enterText(find.byType(TextField), name);
  await tester.pumpAndSettle();

  // 点击"创建"或"确认"按钮
  await tester.tap(find.text('创建'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// 在 ProjectPage 创建新文档
Future<void> createDocument(WidgetTester tester, String title) async {
  // 点击"新建文档"按钮
  await tester.tap(find.text('新建文档'));
  await tester.pumpAndSettle();

  // 输入文档标题
  await tester.enterText(find.byType(TextField), title);
  await tester.pumpAndSettle();

  // 点击确认
  await tester.tap(find.text('确定'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// 在编辑器中输入文本
Future<void> typeInEditor(WidgetTester tester, String text) async {
  // 查找编辑器 TextField
  final editor = find.byType(TextField);
  await tester.tap(editor);
  await tester.pumpAndSettle();
  await tester.enterText(editor, text);
  await tester.pumpAndSettle();
}

/// 切换到指定索引的项目 Tab
Future<void> switchProjectTab(WidgetTester tester, int index) async {
  await tester.tap(find.byIcon(Icons.tab).at(index));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// 从项目列表中选择项目
Future<void> selectProject(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// 等待直到指定文本出现
Future<void> waitForText(WidgetTester tester, String text,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (find.text(text).evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 200));
  }
  fail('Timed out waiting for text: $text');
}

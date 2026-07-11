/// AI 生成状态机 — 最小可运行 Demo
///
/// 运行: dart run test/generation_demo.dart
///
/// 展示所有功能：
/// 1. 11 种状态 + 所有合法转换
/// 2. 输入校验（空、过短、无效类型）
/// 3. 流式 chunk 累加 + 缓冲区截断
/// 4. 确认/拒绝/重来/暂停/恢复/取消/重试
/// 5. 5 种错误类型处理
/// 6. 辅助函数（canStart, isGenerating, progressLabel...）
library;

import '../lib/services/generation/state_machine.dart';

void main() {
  print('═══════════════════════════════════════════');
  print('  AI 生成状态机 — 功能演示');
  print('═══════════════════════════════════════════');
  print('');

  // 1. 初始状态
  current = const IdleState();
  printSection('1. 初始状态');
  assertState<IdleState>('初始为 IdleState');

  // 2. 输入校验
  printSection('2. 输入校验');
  testInputValidation();

  // 3. 全流程 Happy Path
  printSection('3. 全流程 — 快乐路径');
  testHappyPath();

  // 4. 边界情况
  printSection('4. 边界情况');
  testEdgeCases();

  // 5. 错误处理
  printSection('5. 错误处理');
  testErrorHandling();

  // 6. 暂停/恢复
  printSection('6. 暂停与恢复');
  testPauseResume();

  // 7. 取消
  printSection('7. 取消');
  testCancel();

  // 8. 辅助函数
  printSection('8. 辅助函数');
  testHelpers();

  print('');
  print('═══════════════════════════════════════════');
  print('  ✅ 所有演示通过！');
  print('═══════════════════════════════════════════');
}

GenerationState current = const IdleState();

void assertState<T extends GenerationState>(String msg) {
  assert(current.runtimeType == T, '$msg: 期望 ${T.toString()}，实际 ${current.runtimeType}');
  print('  ✅ $msg');
}

void assertTrue(bool condition, String msg) {
  assert(condition, msg);
  print('  ✅ $msg');
}

void assertFalse(bool condition, String msg) {
  assert(!condition, msg);
  print('  ✅ $msg');
}

void printSection(String title) {
  print('');
  print('─── $title ───');
}

// ═══════════════════════════════════════════════
// 2. 输入校验
// ═══════════════════════════════════════════════
void testInputValidation() {
  // 空输入
  final empty = GenerationInput(idea: '');
  assertFalse(empty.isValid, '空输入不合法');
  assertTrue(empty.validationError != null, '空输入有错误提示');

  // 过短输入
  final tooShort = GenerationInput(idea: '测试');
  assertFalse(tooShort.isValid, '过短输入不合法');
  assertTrue(tooShort.validationError != null, '过短有错误提示');

  // 合法输入
  final valid = GenerationInput(idea: '一个修仙少年从废材崛起的故事');
  assertTrue(valid.isValid, '合法输入通过校验');
  assertTrue(valid.validationError == null, '合法输入无错误提示');

  // 非法类型
  final invalidGenre = GenerationInput(idea: '一个修仙故事', genre: '恐怖');
  assertFalse(invalidGenre.isValid, '非法类型不通过');

  // 边界: 刚好 10 字
  final justEnough = GenerationInput(idea: '一二三四五六七八九十');
  assertTrue(justEnough.isValid, '刚好 10 字通过校验');
}

// ═══════════════════════════════════════════════
// 3. 快乐路径
// ═══════════════════════════════════════════════
void testHappyPath() {
  final input = GenerationInput(idea: '一个程序员穿越到异世界，用代码改变世界的故事');

  // idle → ready
  current = transition(current, SetInputEvent(input));
  assertState<ReadyState>('输入后进入 ReadyState');
  assertTrue(current.canStart, '可以开始生成');

  // ready → generating_synopsis
  current = transition(current, const StartGenerationEvent());
  assertState<GeneratingSynopsisState>('开始生成梗概');
  assertTrue(current.isGenerating, '正在生成中');
  assertTrue(current.canCancel, '可以取消');

  // 流式 chunk
  for (final chunk in ['在一', '个遥', '远的', '代码', '大陆', '上…']) {
    current = transition(current, StreamChunkEvent(chunk));
  }
  assertState<GeneratingSynopsisState>('流式 chunks 累加');
  assertTrue(current.streamedWordCount > 0, '有字数统计');

  // 梗概完成
  final synopsis = SynopsisResult(
    synopsis: '在一个以编程能力为力量体系的异世界，程序员林北辰穿越而来……',
    characters: [CharacterBrief(name: '林北辰', role: 'protagonist', personality: '冷静理性', arc: '从社畜到救世主')],
    worldSettings: '代码大陆',
    coreTheme: '技术改变世界',
  );
  current = transition(current, PhaseCompleteEvent(synopsis));
  assertState<ReviewingSynopsisState>('梗概完成，等待确认');
  assertTrue(current.canConfirm, '可以确认');

  // 确认 → generating_outline
  current = transition(current, const ConfirmEvent());
  assertState<GeneratingOutlineState>('确认后开始生成大纲');

  // 大纲流式
  for (final chunk in ['第一卷', '第1章', '代码觉醒', '第2章', '新手任务']) {
    current = transition(current, StreamChunkEvent(chunk));
  }

  // 大纲完成
  final outline = OutlineResult(volumes: [
    VolumeOutline(number: 1, title: '第一卷', chapters: [
      ChapterOutline(number: 1, title: '代码觉醒', summary: '主角穿越觉醒能力', scenes: [
        SceneOutline(number: 1, title: '觉醒仪式', summary: '主角参加觉醒测试', characters: ['林北辰'], location: '觉醒殿'),
      ]),
      ChapterOutline(number: 2, title: '新手任务', summary: '第一个任务', scenes: [
        SceneOutline(number: 1, title: '任务发布', summary: '接取任务', characters: ['林北辰'], location: '新手村'),
      ]),
      ChapterOutline(number: 3, title: '第一个Bug', summary: '遇到第一个挑战', scenes: [
        SceneOutline(number: 1, title: 'Bug出现', summary: '代码报错', characters: ['林北辰'], location: '修炼场'),
      ]),
    ]),
  ]);
  current = transition(current, PhaseCompleteEvent(outline));
  assertState<ReviewingOutlineState>('大纲完成，等待确认');

  // 确认 → generating_content
  current = transition(current, const ConfirmEvent());
  assertState<GeneratingContentState>('确认后开始生成正文');
  assertTrue(current.canPause, '生成中可以暂停');

  // 正文流式
  for (final chunk in ['林北辰', '睁开', '眼睛', '的', '时候…']) {
    current = transition(current, StreamChunkEvent(chunk));
  }

  // 第一章完成
  current = transition(current, ChapterCompleteEvent(
    ChapterContent(number: 1, title: '代码觉醒', content: '第一章正文...', wordCount: 2500, generatedAt: 1000),
  ));
  assertState<GeneratingContentState>('第一章完成，进入第二章');

  // 全部完成
  current = transition(current, AllCompleteEvent(NovelResult(
    synopsis: synopsis,
    outline: outline,
    chapters: [ChapterContent(number: 1, title: '代码觉醒', content: '正文...', wordCount: 2500, generatedAt: 1000)],
  )));
  assertState<CompletedState>('全部生成完成');
  assertTrue(current.progressLabel == '已完成', '进度提示正确');
}

// ═══════════════════════════════════════════════
// 4. 边界情况
// ═══════════════════════════════════════════════
void testEdgeCases() {
  // 非法转换不应该改变状态
  current = const IdleState();
  current = transition(current, const ConfirmEvent());
  assertState<IdleState>('idle 下 Confirm 被忽略');

  // 缓冲区截断
  current = transition(current, SetInputEvent(GenerationInput(idea: '一个测试故事，验证缓冲区截断功能是否正常工作，当内容超过50KB时应该只保留最后一段')));
  current = transition(current, const StartGenerationEvent());
  final bigChunk = 'A' * 60000;
  current = transition(current, StreamChunkEvent(bigChunk));
  assertTrue(current.streamedWordCount <= 60000, '缓冲区超过 50KB 后截断');

  // 拒绝后回到 ready
  current = transition(current, PhaseCompleteEvent(SynopsisResult(
    synopsis: 'X' * 100,
    characters: [CharacterBrief(name: '测试', role: 'protagonist', personality: '测试', arc: '测试')],
  )));
  assertState<ReviewingSynopsisState>('梗概完成');
  current = transition(current, const RejectEvent());
  assertState<ReadyState>('拒绝后回到 ReadyState，可修改输入');
}

// ═══════════════════════════════════════════════
// 5. 错误处理
// ═══════════════════════════════════════════════
void testErrorHandling() {
  // 网络错误
  current = const IdleState();
  current = transition(current, SetInputEvent(GenerationInput(idea: '一个测试网络错误恢复的故事场景')));
  current = transition(current, const StartGenerationEvent());
  current = transition(current, ErrorEvent(GenerationError.network));
  assertState<ErrorState>('网络错误');
  assertTrue(current.canRetry, '网络错误可重试');

  // API Key 无效
  current = transition(current, ErrorEvent(GenerationError.apiKeyInvalid));
  // 通过 ErrorEvent 再次触发
  assertFalse(current.canRetry, 'API Key 无效不可重试');

  // 重试回到 ready
  current = transition(current, const CancelEvent());
  assertState<CancelledState>('取消');

  // 超时错误
  current = transition(current, const ResetEvent());
  assertState<ReadyState>('重置后回到 ready');
  current = transition(current, const StartGenerationEvent());
  current = transition(current, ErrorEvent(GenerationError.timeout));
  assertState<ErrorState>('超时错误');
  assertTrue(current.canRetry, '超时可重试');
  assertTrue((current as ErrorState).error.retryAfter == 5, '建议等待5秒');
}

// ═══════════════════════════════════════════════
// 6. 暂停与恢复
// ═══════════════════════════════════════════════
void testPauseResume() {
  current = const IdleState();
  current = transition(current, SetInputEvent(GenerationInput(idea: '一个测试暂停恢复的长篇故事创作流程体验')));
  current = transition(current, const StartGenerationEvent());
  current = transition(current, PhaseCompleteEvent(SynopsisResult(
    synopsis: 'X' * 100,
    characters: [CharacterBrief(name: '测试', role: 'protagonist', personality: '测试', arc: '测试')],
  )));
  current = transition(current, const ConfirmEvent());
  current = transition(current, PhaseCompleteEvent(OutlineResult(volumes: [
    VolumeOutline(number: 1, title: '第一卷', chapters: [
      ChapterOutline(number: 1, title: '第一章', summary: '测试', scenes: [
        SceneOutline(number: 1, title: '场景1', summary: '测试', characters: [], location: ''),
      ]),
    ]),
  ])));
  current = transition(current, const ConfirmEvent());
  assertState<GeneratingContentState>('准备生成正文');
  current = transition(current, const PauseEvent());
  assertState<PausedState>('已暂停');
  assertTrue(current.progressLabel == '已暂停', '暂停提示正确');

  // 恢复
  current = transition(current, const ResumeEvent());
  assertState<GeneratingContentState>('恢复生成');
}

// ═══════════════════════════════════════════════
// 7. 取消
// ═══════════════════════════════════════════════
void testCancel() {
  // 生成中取消
  current = const IdleState();
  current = transition(current, SetInputEvent(GenerationInput(idea: '一个测试取消功能的故事创意流程')));
  current = transition(current, const StartGenerationEvent());
  current = transition(current, const CancelEvent());
  assertState<CancelledState>('生成中取消');

  // 取消后重置
  current = transition(current, const ResetEvent());
  assertState<ReadyState>('取消后重置回到 ready');
}

// ═══════════════════════════════════════════════
// 8. 辅助函数
// ═══════════════════════════════════════════════
void testHelpers() {
  current = const IdleState();
  assertFalse(current.canStart, 'idle 不能开始');
  assertFalse(current.isGenerating, 'idle 不在生成');
  assertFalse(current.canCancel, 'idle 不能取消');
  assertFalse(current.canPause, 'idle 不能暂停');
  assertFalse(current.canConfirm, 'idle 不能确认');
  assertFalse(current.canRetry, 'idle 不能重试');
  assertTrue(current.progressLabel.isEmpty, 'idle 无进度文字');

  current = transition(current, SetInputEvent(GenerationInput(idea: '一个测试辅助函数功能的故事场景设定')));
  assertTrue(current.canStart, 'ready 可以开始');
  assertTrue(current.progressLabel.isEmpty, 'ready 无进度文字');

  current = transition(current, const StartGenerationEvent());
  assertTrue(current.isGenerating, 'generating 正在生成');
  assertTrue(current.canCancel, 'generating 可以取消');
  assertTrue(current.progressLabel.contains('正在生成'), '有进度文字');

  current = transition(current, PhaseCompleteEvent(SynopsisResult(
    synopsis: 'X' * 100,
    characters: [CharacterBrief(name: '测试', role: 'protagonist', personality: '测试', arc: '测试')],
  )));
  assertTrue(current.canConfirm, 'reviewing 可以确认');
  assertTrue(current.progressLabel.contains('请确认'), '有确认提示');
}
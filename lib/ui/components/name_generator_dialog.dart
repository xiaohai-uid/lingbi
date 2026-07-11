/// AI 取名对话框组件
library;

import 'package:flutter/material.dart';
import 'package:lingbi/core/di/service_locator.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/services/generation/name_generator.dart';

/// 显示 AI 取名对话框
void showNameGeneratorDialog(BuildContext context) {
  final genreCtrl = TextEditingController(text: '玄幻');
  final styleCtrl = TextEditingController(text: '起点爆款');
  final resultCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) {
        final hasResult = resultCtrl.text.isNotEmpty;

        return AlertDialog(
          title: const Row(children: [
            Text('🎭 ', style: TextStyle(fontSize: 20)),
            Text('AI 取名', style: TextStyle(fontSize: 16)),
          ]),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类型
                const Text('小说类型',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A7B68))),
                const SizedBox(height: 4),
                TextField(
                  controller: genreCtrl,
                  decoration: const InputDecoration(
                    hintText: '玄幻/仙侠/都市/科幻…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                // 风格
                const Text('写作风格',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A7B68))),
                const SizedBox(height: 4),
                TextField(
                  controller: styleCtrl,
                  decoration: const InputDecoration(
                    hintText: '起点爆款/番茄爽文…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                // 结果展示
                if (hasResult) ...[
                  const Divider(),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: _buildResultView(resultCtrl.text, ctx),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final ai = ServiceLocator.instance.aiService;
                final prompt = NameGenerator.buildPrompt(
                  genre: genreCtrl.text,
                  style: styleCtrl.text,
                );

                setDlgState(() => resultCtrl.text = '正在生成…');
                try {
                  final result = await ai.generateNovel(prompt);
                  setDlgState(() => resultCtrl.text = result);
                } catch (e) {
                  setDlgState(
                      () => resultCtrl.text = '生成失败: $e');
                }
              },
              child: const Text('✨ 生成',
                  style: TextStyle(color: Color(0xFFE8A838))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildResultView(String text, BuildContext ctx) {
  final parsed = NameGenerator.parseNames(text);
  if (parsed.isEmpty) {
    return Text(text, style: const TextStyle(fontSize: 13, height: 1.6));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: parsed.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.key,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8A838))),
            const SizedBox(height: 4),
            ...entry.value.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () {
                      // 点击复制
                      final name = item.split(' - ').first;
                      // TODO: 复制到剪贴板
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('已复制: $name'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(children: [
                      const Text('• ', style: TextStyle(color: Color(0xFFE8A838))),
                      Expanded(
                        child: Text(item,
                            style: const TextStyle(
                                fontSize: 12, height: 1.5)),
                      ),
                    ]),
                  ),
                )),
          ],
        ),
      );
    }).toList(),
  );
}